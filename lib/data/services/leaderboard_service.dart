import 'package:flutter/foundation.dart';
import 'dart:math' as math;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:pipes/data/services/firebase_config.dart';
import 'package:pipes/data/services/online_leaderboard.dart';

class PlayerEntry {
  const PlayerEntry({
    required this.name,
    required this.score,
    required this.levels,
    required this.bestSeconds,
  });

  final String name;
  final int score;
  final int levels;
  final int bestSeconds;

  Map<String, dynamic> toMap() => {
        'name': name,
        'score': score,
        'levels': levels,
        'bestSeconds': bestSeconds,
      };

  factory PlayerEntry.fromMap(Map<dynamic, dynamic> m) => PlayerEntry(
        name: (m['name'] ?? 'Player') as String,
        score: (m['score'] ?? 0) as int,
        levels: (m['levels'] ?? 0) as int,
        bestSeconds: (m['bestSeconds'] ?? 0) as int,
      );
}

/// On-device leaderboard. Every name that plays on this phone is listed.
class LeaderboardService extends ChangeNotifier {
  static const String _boxName = 'pipes_settings';
  static const String _playersKey = 'leaderboard_players';
  static const String _currentKey = 'player_name';

  Box get _box => Hive.box(_boxName);

  final OnlineLeaderboard _online = OnlineLeaderboard();
  OnlineBoard? onlineBoard;
  bool onlineLoading = false;
  String? onlineError;

  bool get onlineEnabled => FirebaseConfig.isConfigured;

  /// Random id for this phone (created once).
  String get deviceId {
    var id = _box.get('device_id') as String?;
    if (id == null || id.isEmpty) {
      final r = math.Random.secure();
      id = List.generate(10, (_) => r.nextInt(36).toRadixString(36)).join();
      _box.put('device_id', id);
    }
    return id;
  }

  PlayerEntry? get me {
    for (final p in players) {
      if (p.name.toLowerCase() == playerName.toLowerCase()) return p;
    }
    return null;
  }

  /// Sends the current player's totals to Firebase (silent on failure).
  Future<void> syncMine() async {
    if (!onlineEnabled || !hasPlayer) return;
    final m = me;
    if (m == null) return;
    try {
      await _online.upload(deviceId, m);
    } catch (_) {}
  }

  Future<void> refreshOnline() async {
    if (!onlineEnabled) return;
    onlineLoading = true;
    onlineError = null;
    notifyListeners();
    try {
      await syncMine();
      onlineBoard = await _online.fetch();
    } catch (e) {
      onlineError = '$e';
    }
    onlineLoading = false;
    notifyListeners();
  }

  String get playerName => ((_box.get(_currentKey) as String?) ?? '').trim();
  bool get hasPlayer => playerName.isNotEmpty;

  List<PlayerEntry> get players {
    final raw = _box.get(_playersKey, defaultValue: const []) as List;
    final list = <PlayerEntry>[];
    for (final item in raw) {
      if (item is Map) list.add(PlayerEntry.fromMap(item));
    }
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  Future<void> _save(List<PlayerEntry> list) async {
    await _box.put(_playersKey, list.map((e) => e.toMap()).toList());
  }

  /// Sets the active player. A new name is added to the board with 0 points.
  Future<void> setPlayer(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) return;
    final shortName = name.length > 18 ? name.substring(0, 18) : name;
    await _box.put(_currentKey, shortName);
    final list = players;
    if (!list.any((p) => p.name.toLowerCase() == shortName.toLowerCase())) {
      list.add(PlayerEntry(name: shortName, score: 0, levels: 0, bestSeconds: 0));
      await _save(list);
    }
    notifyListeners();
    syncMine();
  }

  /// Score for one solved puzzle: fewer moves + less time = more points.
  static int computeScore({
    required int gridSize,
    required int moves,
    required int seconds,
  }) {
    final base = 300 + gridSize * 60;
    final value = base - moves * 4 - seconds * 2;
    return value < 50 ? 50 : value;
  }

  Future<int> addResult({
    required int gridSize,
    required int moves,
    required int seconds,
  }) async {
    if (!hasPlayer) return 0;
    final points = computeScore(gridSize: gridSize, moves: moves, seconds: seconds);
    final list = players;
    final idx =
        list.indexWhere((p) => p.name.toLowerCase() == playerName.toLowerCase());
    if (idx == -1) {
      list.add(PlayerEntry(
        name: playerName,
        score: points,
        levels: 1,
        bestSeconds: seconds,
      ));
    } else {
      final old = list[idx];
      list[idx] = PlayerEntry(
        name: old.name,
        score: old.score + points,
        levels: old.levels + 1,
        bestSeconds: (old.bestSeconds == 0 || seconds < old.bestSeconds)
            ? seconds
            : old.bestSeconds,
      );
    }
    await _save(list);
    notifyListeners();
    syncMine();
    return points;
  }

  Future<void> removePlayer(String name) async {
    final list = players..removeWhere((p) => p.name == name);
    await _save(list);
    if (playerName.toLowerCase() == name.toLowerCase()) {
      await _box.delete(_currentKey);
    }
    notifyListeners();
  }
}
