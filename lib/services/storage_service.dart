import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item_list.dart';

class StorageService {
  static const _key = 'lists_data';
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  static Future<void> saveLists(List<ItemList> lists) async {
    final prefs = await _instance;
    await prefs.setString(_key, jsonEncode(lists.map(_listToJson).toList()));
  }

  static Future<List<ItemList>> loadLists() async {
    final prefs = await _instance;
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((j) => _listFromJson(j)).toList();
  }

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