import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pipes/domain/models/app_settings.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class MusicTrack {
  const MusicTrack({
    required this.id,
    required this.title,
    required this.author,
    required this.path,
  });

  final String id;
  final String title;
  final String author;
  final String path;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'author': author,
        'path': path,
      };

  factory MusicTrack.fromMap(Map<dynamic, dynamic> m) => MusicTrack(
        id: (m['id'] ?? '') as String,
        title: (m['title'] ?? 'Unknown') as String,
        author: (m['author'] ?? '') as String,
        path: (m['path'] ?? '') as String,
      );
}

/// Playlist + player + YouTube downloader (audio only, saved on the device).
class MusicController extends ChangeNotifier {
  MusicController();

  static const String _boxName = 'pipes_settings';
  static const String _playlistKey = 'playlist';

  final AudioPlayer _player = AudioPlayer();
  final List<MusicTrack> _tracks = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String? _status;
  bool _initialized = false;
  bool _disposed = false;
  bool _shuffle = false;
  bool _repeatOne = false;
  final List<String> _log = [];
  final Stopwatch _logClock = Stopwatch();
  String? _pendingLabel;
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  double _speedBps = 0;

  /// Parallel connections / chunk size used for fast downloads.
  static const int _workers = 6;
  static const int _chunkSize = 512 * 1024;

  List<String> get log => List.unmodifiable(_log);
  String? get pendingLabel => _pendingLabel;

  void _addLog(String m) {
    final t = _logClock.elapsed.inSeconds.toString().padLeft(3);
    _log.add('[${t}s] $m');
    if (_log.length > 60) _log.removeAt(0);
    _notify();
  }

  int get downloadedBytes => _downloadedBytes;
  int get totalBytes => _totalBytes;
  double get speedBytesPerSecond => _speedBps;
  int? get etaSeconds {
    if (_speedBps < 1 || _totalBytes <= 0) return null;
    return ((_totalBytes - _downloadedBytes) / _speedBps).ceil();
  }

  List<MusicTrack> get tracks => List.unmodifiable(_tracks);
  int get currentIndex => _currentIndex;
  MusicTrack? get current =>
      (_currentIndex >= 0 && _currentIndex < _tracks.length)
          ? _tracks[_currentIndex]
          : null;
  bool get isPlaying => _isPlaying;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String? get status => _status;
  bool get shuffle => _shuffle;
  bool get repeatOne => _repeatOne;
  Stream<Duration> get positionStream => _player.positionStream;
  Duration? get duration => _player.duration;
  Stream<Duration?> get durationStream => _player.durationStream;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final box = Hive.box(_boxName);
      final raw = box.get(_playlistKey, defaultValue: const []) as List;
      for (final item in raw) {
        if (item is Map) {
          final t = MusicTrack.fromMap(item);
          // Skip tracks whose file was deleted from the phone.
          if (t.path.isNotEmpty && File(t.path).existsSync()) {
            _tracks.add(t);
          }
        }
      }
    } catch (_) {}

    _player.playerStateStream.listen((s) {
      final playing = s.playing && s.processingState != ProcessingState.completed;
      if (playing != _isPlaying) {
        _isPlaying = playing;
        _notify();
      }
      if (s.processingState == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });

    _player.playbackEventStream.listen((_) {}, onError: (Object e, StackTrace st) {
      _status = 'Playback error: $e';
      _isPlaying = false;
      _notify();
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _savePlaylist() async {
    try {
      await Hive.box(_boxName)
          .put(_playlistKey, _tracks.map((t) => t.toMap()).toList());
    } catch (_) {}
  }

  void _onTrackCompleted() {
    if (_tracks.isEmpty) return;
    if (_repeatOne) {
      playIndex(_currentIndex);
    } else {
      next();
    }
  }

  Future<void> playIndex(int index) async {
    if (index < 0 || index >= _tracks.length) return;
    final track = _tracks[index];
    try {
      _currentIndex = index;
      _status = null;
      _notify();
      await _player.setFilePath(track.path);
      await _player.play();
    } catch (e) {
      _status = 'Cannot play "${track.title}": $e';
      _isPlaying = false;
      _notify();
    }
  }

  Future<void> togglePlayPause() async {
    if (_tracks.isEmpty) return;
    if (current == null) {
      await playIndex(0);
      return;
    }
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  Future<void> next() async {
    if (_tracks.isEmpty) return;
    int nextIndex;
    if (_shuffle && _tracks.length > 1) {
      nextIndex = (DateTime.now().millisecondsSinceEpoch % _tracks.length);
      if (nextIndex == _currentIndex) {
        nextIndex = (nextIndex + 1) % _tracks.length;
      }
    } else {
      nextIndex = (_currentIndex + 1) % _tracks.length;
    }
    await playIndex(nextIndex);
  }

  Future<void> previous() async {
    if (_tracks.isEmpty) return;
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    final prev = (_currentIndex - 1) < 0 ? _tracks.length - 1 : _currentIndex - 1;
    await playIndex(prev);
  }

  Future<void> seek(Duration position) => _player.seek(position);

  void toggleShuffle() {
    _shuffle = !_shuffle;
    _notify();
  }

  void toggleRepeatOne() {
    _repeatOne = !_repeatOne;
    _notify();
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _tracks.length) return;
    final removed = _tracks[index];
    final wasCurrent = index == _currentIndex;

    _tracks.removeAt(index);
    if (wasCurrent) {
      await _player.stop();
      _currentIndex = -1;
    } else if (index < _currentIndex) {
      _currentIndex -= 1;
    }
    try {
      final f = File(removed.path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    await _savePlaylist();
    _notify();
  }

  /// Starts the playlist if nothing is playing yet.
  Future<void> startIfIdle() async {
    if (_tracks.isEmpty || _isPlaying) return;
    await playIndex(_currentIndex >= 0 ? _currentIndex : 0);
  }

  Future<void> pause() async {
    if (_player.playing) await _player.pause();
  }

  /// Picks the audio stream that matches the chosen [quality].
  /// Smaller streams = much faster download.
  AudioStreamInfo _pickStream(
    Iterable<AudioStreamInfo> streams,
    AudioQuality quality,
  ) {
    final all = streams.toList();
    final mp4 = all.where((s) => s.container.name.toLowerCase() == 'mp4').toList();
    final pool = mp4.isNotEmpty ? mp4 : all;
    pool.sort((a, b) => a.bitrate.bitsPerSecond.compareTo(b.bitrate.bitsPerSecond));
    switch (quality) {
      case AudioQuality.fast:
        return pool.first;
      case AudioQuality.high:
        return pool.last;
      case AudioQuality.normal:
        return pool.firstWhere(
          (s) => s.bitrate.bitsPerSecond >= 100000,
          orElse: () => pool.last,
        );
    }
  }

  /// Downloads [url] with several parallel ranged requests (this is what
  /// makes it fast: YouTube throttles a single connection).
  Future<void> _downloadParallel(
    Uri url,
    int total,
    File file,
    Stopwatch watch,
  ) async {
    final raf = await file.open(mode: FileMode.write);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..maxConnectionsPerHost = _workers + 2;
    try {
      final chunkCount = (total / _chunkSize).ceil();
      var nextChunk = 0;
      var writeQueue = Future<void>.value();
      var lastNotifyMs = 0;
      var cancelled = false;

      Future<void> fetchChunk(int index) async {
        final start = index * _chunkSize;
        final end = (start + _chunkSize - 1) < total ? start + _chunkSize - 1 : total - 1;
        final expected = end - start + 1;
        Object? lastError;
        for (var attempt = 0; attempt < 2; attempt++) {
          if (cancelled) return;
          var got = 0;
          try {
            final req = await client.getUrl(Uri.parse('$url&range=$start-$end'));
            final res = await req.close().timeout(const Duration(seconds: 10));
            if (res.statusCode != 200 && res.statusCode != 206) {
              throw HttpException('HTTP ${res.statusCode}');
            }
            final bb = BytesBuilder(copy: false);
            await for (final c in res.timeout(const Duration(seconds: 10))) {
              if (cancelled) throw const HttpException('cancelled');
              bb.add(c);
              got += c.length;
              _downloadedBytes += c.length;
            }
            final bytes = bb.takeBytes();
            if (bytes.length != expected) {
              throw HttpException('Bad chunk size ${bytes.length} != $expected');
            }
            writeQueue = writeQueue.then((_) async {
              await raf.setPosition(start);
              await raf.writeFrom(bytes);
            });
            await writeQueue;

            final ms = watch.elapsedMilliseconds;
            if (ms - lastNotifyMs > 350) {
              lastNotifyMs = ms;
              _speedBps = ms > 0 ? _downloadedBytes * 1000 / ms : 0;
              _downloadProgress = (_downloadedBytes / total).clamp(0.0, 1.0);
              _notify();
            }
            return;
          } catch (e) {
            if (cancelled) return;
            lastError = e;
            _downloadedBytes -= got; // this chunk will be re-downloaded
          }
        }
        throw lastError ?? Exception('chunk failed');
      }

      Future<void> worker() async {
        while (!cancelled) {
          final i = nextChunk++;
          if (i >= chunkCount) return;
          await fetchChunk(i);
        }
      }

      try {
        await Future.wait(
          List.generate(_workers, (_) => worker()),
          eagerError: true,
        );
      } catch (_) {
        cancelled = true;
        rethrow;
      }
      await writeQueue;
      await raf.flush();
    } finally {
      client.close(force: true);
      await raf.close();
    }
  }

  /// Fallback: the normal single-connection download of the library.
  Future<void> _downloadSequential(
    YoutubeExplode yt,
    AudioStreamInfo streamInfo,
    File file,
    Stopwatch watch,
  ) async {
    final sink = file.openWrite();
    try {
      final total = streamInfo.size.totalBytes;
      var lastNotifyMs = 0;
      await for (final chunk in yt.videos.streams
          .get(streamInfo)
          .timeout(const Duration(seconds: 12))) {
        _downloadedBytes += chunk.length;
        sink.add(chunk);
        final ms = watch.elapsedMilliseconds;
        if (ms - lastNotifyMs > 350 && total > 0) {
          lastNotifyMs = ms;
          _speedBps = ms > 0 ? _downloadedBytes * 1000 / ms : 0;
          _downloadProgress = (_downloadedBytes / total).clamp(0.0, 1.0);
          _notify();
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  /// Adds audio files from the phone (picked with the file picker).
  /// Each file is copied into the app folder so it keeps working later.
  /// Returns null when OK, otherwise an error message.
  Future<String?> addLocalFiles(
    List<({String path, String name})> files, {
    bool playAfter = true,
  }) async {
    if (files.isEmpty) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${dir.path}/music');
      if (!await musicDir.exists()) await musicDir.create(recursive: true);

      final firstNew = _tracks.length;
      var added = 0;
      for (final f in files) {
        final src = File(f.path);
        if (!await src.exists()) continue;
        final dot = f.name.lastIndexOf('.');
        final ext = dot > 0 ? f.name.substring(dot) : '.mp3';
        final title = dot > 0 ? f.name.substring(0, dot) : f.name;
        final id = 'local_${DateTime.now().microsecondsSinceEpoch}_$added';
        final dest = File('${musicDir.path}/$id$ext');
        await src.copy(dest.path);
        _tracks.add(
          MusicTrack(id: id, title: title, author: 'My phone', path: dest.path),
        );
        added++;
      }
      if (added == 0) return 'File එක කියවන්න බැරි උනා.';
      await _savePlaylist();
      _status = 'සිංදු $added ක් add උනා ✓';
      _notify();
      if (playAfter) await playIndex(firstNew);
      return null;
    } catch (e) {
      return 'සිංදු add කරන්න බැරි උනා.\n($e)';
    }
  }

  /// Downloads the audio of a YouTube link and adds it to the playlist.
  /// Tries several YouTube "clients" one after another, because YouTube
  /// blocks some of them from time to time.
  /// Returns null when OK, otherwise an error message.
  Future<String?> addFromYoutube(
    String link, {
    bool playAfter = true,
    AudioQuality quality = AudioQuality.normal,
  }) async {
    final url = link.trim();
    if (url.isEmpty) return 'Link එකක් paste කරන්න.';
    if (_isDownloading) return 'දැනටමත් download වෙමින් පවතී…';

    final yt = YoutubeExplode();
    File? file;
    try {
      _isDownloading = true;
      _downloadProgress = 0;
      _downloadedBytes = 0;
      _totalBytes = 0;
      _speedBps = 0;
      _log.clear();
      _logClock
        ..reset()
        ..start();
      _pendingLabel = url;
      _status = 'Video info ගන්නවා…';
      _notify();
      _addLog('Start: $url');

      final videoId = VideoId(url);
      _addLog('Video id: ${videoId.value}');
      final existing = _tracks.indexWhere((t) => t.id == videoId.value);
      if (existing != -1) {
        _status = 'මේ සිංදුව කලින්ම playlist එකේ තියෙනවා.';
        _pendingLabel = null;
        _isDownloading = false;
        _notify();
        if (playAfter) await playIndex(existing);
        return null;
      }

      // Title is only for display, so a failure here must not stop the download.
      final Future<Video?> infoFuture = () async {
        try {
          return await yt.videos.get(videoId).timeout(const Duration(seconds: 15));
        } catch (_) {
          return null;
        }
      }();

      final dir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${dir.path}/music');
      if (!await musicDir.exists()) await musicDir.create(recursive: true);

      final clientSets = <List<YoutubeApiClient>?>[
        null, // library default
        [YoutubeApiClient.androidVr],
        [YoutubeApiClient.ios],
        [YoutubeApiClient.tv],
        [YoutubeApiClient.safari],
      ];

      var ok = false;
      final errors = <String>[];
      final overall = Stopwatch()..start();
      for (var ci = 0; ci < clientSets.length; ci++) {
        final clients = clientSets[ci];
        if (overall.elapsed.inSeconds > 100) {
          errors.add('time out (100s)');
          break;
        }
        try {
          _status = 'Link එක බලනවා… (${ci + 1}/${clientSets.length})'
              '${errors.isEmpty ? '' : '\nකලින් එක fail: ${errors.last}'}';
          _downloadedBytes = 0;
          _downloadProgress = 0;
          _speedBps = 0;
          _notify();

          final manifest = await yt.videos.streams
              .getManifest(videoId, ytClients: clients)
              .timeout(const Duration(seconds: 15));
          final audioStreams = manifest.audioOnly;
          _addLog('Client ${ci + 1}: audio streams = ${audioStreams.length}');
          if (audioStreams.isEmpty) throw Exception('Audio stream එකක් නෑ');
          final streamInfo = _pickStream(audioStreams, quality);
          _addLog(
            'Picked ${streamInfo.container.name} '
            '${streamInfo.bitrate.bitsPerSecond ~/ 1000}kbps '
            '${(streamInfo.size.totalBytes / 1024).round()} KB',
          );

          file = File(
            '${musicDir.path}/${videoId.value}.${streamInfo.container.name}',
          );
          if (await file.exists()) await file.delete();

          final total = streamInfo.size.totalBytes;
          _totalBytes = total;
          _status = 'Download පටන් ගත්තා…  '
              '${(total / (1024 * 1024)).toStringAsFixed(1)} MB';
          _notify();

          final watch = Stopwatch()..start();
          var done = false;
          if (total > 0) {
            try {
              await _downloadParallel(streamInfo.url, total, file, watch);
              done = true;
            } catch (e) {
              _addLog('Parallel failed: $e');
              // Parallel mode refused – do it the normal way.
              _downloadedBytes = 0;
              _downloadProgress = 0;
              _speedBps = 0;
              watch.reset();
              if (await file.exists()) await file.delete();
            }
          }
          if (!done) {
            _addLog('Normal download…');
            await _downloadSequential(yt, streamInfo, file, watch);
          }
          _addLog('Downloaded ${(await file.length() / 1024).round()} KB');
          if (await file.length() < 10 * 1024) {
            throw Exception('Download උන file එක හිස්');
          }
          ok = true;
          break;
        } catch (e) {
          final m = '$e'.replaceAll('\n', ' ');
          _addLog('Client ${ci + 1} FAILED: $m');
          errors.add(m.length > 70 ? '${m.substring(0, 70)}…' : m);
          try {
            if (file != null && await file.exists()) await file.delete();
          } catch (_) {}
        }
      }
      if (!ok || file == null) {
        throw Exception(
          errors.isEmpty ? 'unknown error' : errors.asMap().entries.map((e) => '#${e.key + 1}: ${e.value}').join(' | '),
        );
      }

      final video = await infoFuture;
      final track = MusicTrack(
        id: videoId.value,
        title: video?.title ?? 'YouTube ${videoId.value}',
        author: video?.author ?? '',
        path: file.path,
      );
      _tracks.add(track);
      await _savePlaylist();

      _addLog('DONE ✓');
      _pendingLabel = null;
      _status = 'Playlist එකට add උනා ✓  ${track.title}';
      _isDownloading = false;
      _downloadProgress = 1;
      _notify();

      if (playAfter) await playIndex(_tracks.length - 1);
      return null;
    } catch (e) {
      _addLog('ERROR: $e');
      _pendingLabel = null;
      _isDownloading = false;
      _status = null;
      _notify();
      final msg = '$e';
      final short = msg.length > 420 ? '${msg.substring(0, 420)}…' : msg;
      return 'Download කරන්න බැරි උනා. Link එක / internet එක බලන්න.\n($short)';
    } finally {
      yt.close();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _player.dispose();
    super.dispose();
  }
}
