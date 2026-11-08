import 'dart:convert';
import 'dart:io';

import 'package:pipes/data/services/firebase_config.dart';
import 'package:pipes/data/services/leaderboard_service.dart';

class OnlineBoard {
  const OnlineBoard({required this.players, required this.totalPlayers});
  final List<PlayerEntry> players;
  final int totalPlayers;
}

/// Talks to Firestore through its REST API (no extra packages needed).
class OnlineLeaderboard {
  static const _collection = 'players';

  String get _base =>
      'https://firestore.googleapis.com/v1/projects/${FirebaseConfig.projectId}/databases/(default)/documents';

  Future<dynamic> _send(String method, String url, [Object? body]) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final req = await client.openUrl(method, Uri.parse(url));
      req.headers.contentType = ContentType.json;
      if (body != null) req.add(utf8.encode(jsonEncode(body)));
      final res = await req.close().timeout(const Duration(seconds: 20));
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw HttpException('Firestore ${res.statusCode}: $text');
      }
      return text.isEmpty ? null : jsonDecode(text);
    } finally {
      client.close(force: true);
    }
  }

  /// Document id = this phone + player name, so the same name on two phones
  /// never overwrites each other.
  static String docId(String deviceId, String name) {
    final hex = utf8
        .encode(name.toLowerCase())
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${deviceId}_$hex';
  }

  Future<void> upload(String deviceId, PlayerEntry p) async {
    if (!FirebaseConfig.isConfigured) return;
    final id = docId(deviceId, p.name);
    final mask = ['name', 'score', 'levels', 'bestSeconds', 'updatedAt']
        .map((f) => 'updateMask.fieldPaths=$f')
        .join('&');
    final url = '$_base/$_collection/$id?$mask&key=${FirebaseConfig.apiKey}';
    await _send('PATCH', url, {
      'fields': {
        'name': {'stringValue': p.name},
        'score': {'integerValue': '${p.score}'},
        'levels': {'integerValue': '${p.levels}'},
        'bestSeconds': {'integerValue': '${p.bestSeconds}'},
        'updatedAt': {'integerValue': '${DateTime.now().millisecondsSinceEpoch}'},
      },
    });
  }

  int _int(Map? f, String key) {
    final v = f?[key];
    if (v is Map && v['integerValue'] != null) {
      return int.tryParse('${v['integerValue']}') ?? 0;
    }
    return 0;
  }

  Future<OnlineBoard> fetch({int limit = 50}) async {
    if (!FirebaseConfig.isConfigured) {
      throw const HttpException('Firebase not configured');
    }
    final key = FirebaseConfig.apiKey;

    final rows = await _send('POST', '$_base:runQuery?key=$key', {
      'structuredQuery': {
        'from': [
          {'collectionId': _collection}
        ],
        'orderBy': [
          {
            'field': {'fieldPath': 'score'},
            'direction': 'DESCENDING'
          }
        ],
        'limit': limit,
      },
    }) as List;

    final players = <PlayerEntry>[];
    for (final r in rows) {
      final doc = (r as Map)['document'] as Map?;
      if (doc == null) continue;
      final f = doc['fields'] as Map?;
      final nameField = f?['name'];
      players.add(PlayerEntry(
        name: nameField is Map ? '${nameField['stringValue'] ?? 'Player'}' : 'Player',
        score: _int(f, 'score'),
        levels: _int(f, 'levels'),
        bestSeconds: _int(f, 'bestSeconds'),
      ));
    }

    // Total number of players (not just the top 50).
    var total = players.length;
    try {
      final agg = await _send('POST', '$_base:runAggregationQuery?key=$key', {
        'structuredAggregationQuery': {
          'structuredQuery': {
            'from': [
              {'collectionId': _collection}
            ]
          },
          'aggregations': [
            {'alias': 'c', 'count': <String, dynamic>{}}
          ],
        },
      }) as List;
      final fields = ((agg.first as Map)['result'] as Map)['aggregateFields'] as Map;
      total = int.tryParse('${(fields['c'] as Map)['integerValue']}') ?? total;
    } catch (_) {}

    return OnlineBoard(players: players, totalPlayers: total);
  }
}
