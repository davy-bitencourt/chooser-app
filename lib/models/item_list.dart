class ItemList {
  String id;
  String name;
  String emoji;
  List<ListItem> items;
  DateTime createdAt;

  ItemList({
    required this.id,
    required this.name,
    required this.emoji,
    List<ListItem>? items,
    DateTime? createdAt,
  })  : items = items ?? [],
        createdAt = createdAt ?? DateTime.now();

  ItemList copyWith({
    String? id,
    String? name,
    String? emoji,
    List<ListItem>? items,
  }) {
    return ItemList(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      items: items ?? this.items,
      createdAt: createdAt,
    );
  }
}

class ListItem {
  String id;
  String name;

  ListItem({
    required this.id,
    required this.name,
  });

  ListItem copyWith({
    String? id,
    String? name,
  }) {
    return ListItem(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}