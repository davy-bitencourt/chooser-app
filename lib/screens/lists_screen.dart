import 'package:flutter/material.dart';
import '../models/item_list.dart';
import '../services/storage_service.dart';
import 'items_screen.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen>
    with TickerProviderStateMixin {
  final List<ItemList> _lists = [];
  late AnimationController _fabController;

  final List<String> _emojis = [
    '🎯', '🎲', '🎮', '🍕', '🌟', '🚀', '🎵', '📚',
    '🏆', '💡', '🎨', '🌈', '⚡', '🔥', '💎', '🎭',
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadLists();
  }

  Future<void> _loadLists() async {
    final saved = await StorageService.loadLists();
    setState(() => _lists.addAll(saved));
  }

  Future<void> _save() async {
    await StorageService.saveLists(_lists);
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _showCreateListDialog() {
    final nameController = TextEditingController();
    String selectedEmoji = _emojis[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nova Lista',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Emoji picker
                const Text('Escolha um emoji',
                    style: TextStyle(color: Color(0xFF8888AA), fontSize: 13)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 120,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(_emojis.length, (i) {
                        final isSelected = selectedEmoji == _emojis[i];
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedEmoji = _emojis[i]),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF6C63FF).withOpacity(0.3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6C63FF)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(_emojis[i], style: const TextStyle(fontSize: 15)),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Nome da lista...',
                    hintStyle: const TextStyle(color: Color(0xFF555577)),
                    filled: true,
                    fillColor: const Color(0xFF0F0F1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF6C63FF), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar',
                          style: TextStyle(color: Color(0xFF8888AA))),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          setState(() {
                            _lists.add(ItemList(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              name: nameController.text.trim(),
                              emoji: selectedEmoji,
                            ));
                          });
                          _save();
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Criar',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditListDialog(ItemList list) {
    final nameController = TextEditingController(text: list.name);
    String selectedEmoji = list.emoji;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Editar Lista',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Escolha um emoji',
                    style: TextStyle(color: Color(0xFF8888AA), fontSize: 13)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 120,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemCount: _emojis.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedEmoji = _emojis[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: selectedEmoji == _emojis[i]
                              ? const Color(0xFF6C63FF).withOpacity(0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selectedEmoji == _emojis[i]
                                ? const Color(0xFF6C63FF)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(_emojis[i],
                              style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Nome da lista...',
                    hintStyle: const TextStyle(color: Color(0xFF555577)),
                    filled: true,
                    fillColor: const Color(0xFF0F0F1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF6C63FF), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar',
                          style: TextStyle(color: Color(0xFF8888AA))),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          setState(() {
                            final idx =
                                _lists.indexWhere((l) => l.id == list.id);
                            if (idx != -1) {
                              _lists[idx] = _lists[idx].copyWith(
                                name: nameController.text.trim(),
                                emoji: selectedEmoji,
                              );
                            }
                          });
                          _save();
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Salvar',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteList(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir lista?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Esta ação não pode ser desfeita. Todos os itens serão perdidos.',
          style: TextStyle(color: Color(0xFF8888AA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF8888AA))),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _lists.removeWhere((l) => l.id == id));
              _save();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4757),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F0F1A),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Minhas Listas',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1A)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF6C63FF).withOpacity(0.08),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(
                    '${_lists.length} listas',
                    style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: const Color(0xFF6C63FF).withOpacity(0.12),
                  side: BorderSide(
                      color: const Color(0xFF6C63FF).withOpacity(0.3)),
                ),
              )
            ],
          ),
          _lists.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Center(
                            child: Text('📋',
                                style: TextStyle(fontSize: 40)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Nenhuma lista ainda',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Crie sua primeira lista\npara começar!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF8888AA), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final list = _lists[index];
                        return _ListCard(
                          list: list,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ItemsScreen(
                                  list: list,
                                  onListUpdated: (updated) {
                                    setState(() {
                                      final idx = _lists
                                          .indexWhere((l) => l.id == list.id);
                                      if (idx != -1) _lists[idx] = updated;
                                    });
                                    _save();
                                  },
                                ),
                              ),
                            );
                          },
                          onEdit: () => _showEditListDialog(list),
                          onDelete: () => _deleteList(list.id),
                        );
                      },
                      childCount: _lists.length,
                    ),
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateListDialog,
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final ItemList list;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ListCard({
    required this.list,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6C63FF).withOpacity(0.15),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(list.emoji,
                          style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          list.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${list.items.length} ${list.items.length == 1 ? 'item' : 'itens'}',
                          style: const TextStyle(
                            color: Color(0xFF8888AA),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: const Color(0xFF1A1A2E),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded,
                                color: Color(0xFF6C63FF), size: 18),
                            SizedBox(width: 10),
                            Text('Editar',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded,
                                color: Color(0xFFFF4757), size: 18),
                            SizedBox(width: 10),
                            Text('Excluir',
                                style: TextStyle(color: Color(0xFFFF4757))),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.more_vert_rounded,
                          color: Color(0xFF8888AA), size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}