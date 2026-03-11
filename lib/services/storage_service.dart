import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item_list.dart';

class StorageService {
  static const _sessionsKey = 'sessions_data';
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  // ── Sessões ──────────────────────────────────────────

  static Future<void> saveSessions(List<Session> sessions) async {
    final prefs = await _instance;
    await prefs.setString(
      _sessionsKey,
      jsonEncode(sessions.map(_sessionToJson).toList()),
    );
  }

  static Future<List<Session>> loadSessions() async {
    final prefs = await _instance;
    final raw = prefs.getString(_sessionsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((j) => _sessionFromJson(j)).toList();
  }

  // ── Listas de uma sessão ─────────────────────────────

  static Future<void> saveSessionLists(
      String sessionId, List<ItemList> lists) async {
    final prefs = await _instance;
    await prefs.setString(
      'session_$sessionId',
      jsonEncode(lists.map(_listToJson).toList()),
    );
  }

  static Future<List<ItemList>> loadSessionLists(String sessionId) async {
    final prefs = await _instance;
    final raw = prefs.getString('session_$sessionId');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((j) => _listFromJson(j)).toList();
  }

  static Future<void> deleteSessionLists(String sessionId) async {
    final prefs = await _instance;
    await prefs.remove('session_$sessionId');
  }

  // ── JSON helpers ─────────────────────────────────────

  static Map<String, dynamic> _sessionToJson(Session s) => {
        'id': s.id,
        'name': s.name,
        'emoji': s.emoji,
        'createdAt': s.createdAt.toIso8601String(),
      };

  static Session _sessionFromJson(Map<String, dynamic> j) => Session(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: j['emoji'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  static Map<String, dynamic> _listToJson(ItemList l) => {
        'id': l.id,
        'name': l.name,
        'emoji': l.emoji,
        'createdAt': l.createdAt.toIso8601String(),
        'items': l.items.map(_itemToJson).toList(),
      };

  static Map<String, dynamic> _itemToJson(ListItem i) => {
        'id': i.id,
        'name': i.name,
      };

  static ItemList _listFromJson(Map<String, dynamic> j) => ItemList(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: j['emoji'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        items: (j['items'] as List)
            .map((i) => _itemFromJson(i as Map<String, dynamic>))
            .toList(),
      );

  static ListItem _itemFromJson(Map<String, dynamic> j) => ListItem(
        id: j['id'] as String,
        name: j['name'] as String,
      );
}