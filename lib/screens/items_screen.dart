import 'dart:math';
import 'package:flutter/material.dart';
import '../models/item_list.dart';
import '../services/file_manager.dart';

class ItemsScreen extends StatefulWidget {
  final ItemList list;
  final Function(ItemList) onListUpdated;

  const ItemsScreen({
    super.key,
    required this.list,
    required this.onListUpdated,
  });

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> with TickerProviderStateMixin {
  late ItemList _list;
  ListItem? _randomResult;
  bool _isRandomizing = false;

  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final AnimationController _resultController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
  );
  late final Animation<double> _resultScaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
    CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
  );
  late final Animation<double> _resultFadeAnim = Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(parent: _resultController, curve: Curves.easeOut),
  );

  final _random = Random();

  @override
  void initState() {
    super.initState();
    _list = widget.list;
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  ListItem get _randomItem => _list.items[_random.nextInt(_list.items.length)];

  void _randomize() async {
    if (_list.items.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Adicione itens à lista primeiro!'),
          backgroundColor: const Color(0xFFFF4757),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isRandomizing = true;
      _randomResult = null;
    });

    _shakeController.forward(from: 0);

    for (int i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      setState(() => _randomResult = _randomItem);
    }

    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    final finalResult = _randomItem;
    setState(() {
      _randomResult = finalResult;
      _isRandomizing = false;
    });

    _resultController.forward(from: 0);
    _showResultBottomSheet(finalResult);
  }

  void _showResultBottomSheet(ListItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(   // <-- adiciona aqui
        child: Container(
          padding: const EdgeInsets.all(32),

        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF333355),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ScaleTransition(
              scale: _resultScaleAnim,
              child: FadeTransition(
                opacity: _resultFadeAnim,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Text('🎲', style: TextStyle(fontSize: 40)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Sorteado!',
                      style: TextStyle(
                        color: Color(0xFF8888AA),
                        fontSize: 14,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Confirmar',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),),
    );
  }

  void _showItemDialog({ListItem? editing}) {
    final nameController = TextEditingController(text: editing?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    editing == null ? 'Novo Item' : 'Editar Item',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // só mostra o botão de importar quando for "Novo Item", não no "Editar"
                  if (editing == null)
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx); // fecha o dialog
                        final newItems = await FileManager.importItems(_list.items);
                        if (newItems == null) return;
                        if (newItems.isEmpty) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Nenhum item novo encontrado!'),
                              backgroundColor: const Color(0xFFFF4757),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        setState(() => _list.items.addAll(newItems));
                        widget.onListUpdated(_list);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.upload_file_rounded,
                            color: Color(0xFF6C63FF), size: 20),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nome do item...',
                  hintStyle: const TextStyle(color: Color(0xFF555577)),
                  filled: true,
                  fillColor: const Color(0xFF0F0F1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
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
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;

                      setState(() {
                        if (editing == null) {
                          _list.items.add(ListItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: name,
                          ));
                        } else {
                          final idx = _list.items.indexWhere((i) => i.id == editing.id);
                          if (idx != -1) _list.items[idx] = editing.copyWith(name: name);
                        }
                      });
                      widget.onListUpdated(_list);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      editing == null ? 'Adicionar' : 'Salvar',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteItem(String id) {
    setState(() {
      _list.items.removeWhere((i) => i.id == id);
      if (_randomResult?.id == id) _randomResult = null;
    });
    widget.onListUpdated(_list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: const Color(0xFF0F0F1A),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_list.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    _list.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(
                    '${_list.items.length} itens',
                    style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: const Color(0xFF6C63FF).withOpacity(0.12),
                  side: BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.3)),
                ),
              ),
            ],
          ),
          _list.items.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Text('📝', style: TextStyle(fontSize: 32)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Nenhum item ainda',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Adicione itens para começar a sortear!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF8888AA), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _list.items[index];
                        return _ItemCard(
                          item: item,
                          isHighlighted: _randomResult?.id == item.id,
                          index: index,
                          onEdit: () => _showItemDialog(editing: item),
                          onDelete: () => _deleteItem(item.id),
                        );
                      },
                      childCount: _list.items.length,
                    ),
                  ),
                ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: GestureDetector(
            onTap: _randomize,
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (ctx, child) => Transform.rotate(
              angle: _isRandomizing ? sin(_shakeAnimation.value * pi * 8) * 0.05 : 0,
              child: child,
            ),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎲', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text(
                    _isRandomizing ? 'Sorteando...' : 'Sortear',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ListItem item;
  final bool isHighlighted;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.item,
    required this.isHighlighted,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color(0xFF6C63FF).withOpacity(0.15)
            : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFF6C63FF)
              : const Color(0xFF6C63FF).withOpacity(0.1),
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: isHighlighted
            ? [BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isHighlighted
                    ? const Color(0xFF6C63FF)
                    : const Color(0xFF6C63FF).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: isHighlighted
                    ? const Icon(Icons.star_rounded, color: Colors.white, size: 18)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isHighlighted ? Colors.white : const Color(0xFF6C63FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  color: isHighlighted ? Colors.white : const Color(0xFFDDDDFF),
                  fontSize: 15,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                ),
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
    );
  }
}
