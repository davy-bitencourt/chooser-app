import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/item_list.dart';
import '../services/storage_service.dart';
import 'items_screen.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> with TickerProviderStateMixin {
  final List<Session> _sessions = [];
  final Map<String, List<ItemList>> _listsMap = {};
  late TabController _tabController;

  final List<String> _emojis = [
    '🎯', '🎲', '🎮', '🍕', '🌟', '🚀', '🎵', '📚',
    '🏆', '💡', '🎨', '🌈', '⚡', '🔥', '💎', '🎭',
  ];

  List<ItemList> get _currentLists =>
      _sessions.isEmpty ? [] : (_listsMap[_sessions[_tabController.index].id] ?? []);

  Session? get _currentSession =>
      _sessions.isEmpty ? null : _sessions[_tabController.index];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await StorageService.loadSessions();
    for (final s in sessions) {
      _listsMap[s.id] = await StorageService.loadSessionLists(s.id);
    }
    setState(() {
      _sessions.addAll(sessions);
      _rebuildTabController();
    });
  }

  void _rebuildTabController() {
    final old = _tabController;
    final oldIndex = old.index;
    _tabController = TabController(
      length: _sessions.length,
      vsync: this,
      initialIndex: oldIndex.clamp(0, _sessions.isEmpty ? 0 : _sessions.length - 1),
    );
    _tabController.addListener(() => setState(() {}));
    old.dispose();
  }

  Future<void> _saveSessions() async {
    await StorageService.saveSessions(_sessions);
  }

  Future<void> _saveCurrentLists() async {
    final session = _currentSession;
    if (session == null) return;
    await StorageService.saveSessionLists(session.id, _currentLists);
  }

  void _randomizeAll() {
    final lists = _currentLists;
    if (lists.isEmpty) return;

    final results = lists
        .where((l) => l.items.isNotEmpty)
        .map((l) => MapEntry(l, l.items[Random().nextInt(l.items.length)]))
        .toList();

    if (results.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.95,
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
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text('Sorteio do Dia 🎲',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          final text = results
                              .map((e) => '${e.key.name}: ${e.value.name}')
                              .join('\n');
                          Clipboard.setData(ClipboardData(text: text));
                        },
                        child: const Icon(Icons.copy_rounded, color: Color(0xFF6C63FF), size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: results.map((entry) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F1A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Text(entry.key.emoji,
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.key.name,
                                      style: const TextStyle(
                                          color: Color(0xFF8888AA), fontSize: 12)),
                                  Text(entry.value.name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateSessionDialog() {
    final nameController = TextEditingController();
    String selectedEmoji = _emojis[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nova Sessão',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
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
                                  ? const Color(0xFF6C63FF).withValues(alpha: 0.3)
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
                              child: Text(_emojis[i],
                                  style: const TextStyle(fontSize: 15)),
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
                    hintText: 'Nome da sessão...',
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
                        if (nameController.text.trim().isNotEmpty) {
                          final newSession = Session(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: nameController.text.trim(),
                            emoji: selectedEmoji,
                          );
                          setState(() {
                            _sessions.add(newSession);
                            _listsMap[newSession.id] = [];
                            _rebuildTabController();
                            _tabController.animateTo(_sessions.length - 1);
                          });
                          _saveSessions();
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

  void _showCreateListDialog() {
    final nameController = TextEditingController();
    String selectedEmoji = _emojis[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nova Lista',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
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
                                  ? const Color(0xFF6C63FF).withValues(alpha: 0.3)
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
                              child: Text(_emojis[i],
                                  style: const TextStyle(fontSize: 15)),
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
                        if (nameController.text.trim().isNotEmpty) {
                          setState(() {
                            _currentLists.add(ItemList(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              name: nameController.text.trim(),
                              emoji: selectedEmoji,
                            ));
                          });
                          _saveCurrentLists();
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Editar Lista',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
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
                                  ? const Color(0xFF6C63FF).withValues(alpha: 0.3)
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
                              child: Text(_emojis[i],
                                  style: const TextStyle(fontSize: 15)),
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
                        if (nameController.text.trim().isNotEmpty) {
                          setState(() {
                            final lists = _currentLists;
                            final idx = lists.indexWhere((l) => l.id == list.id);
                            if (idx != -1) {
                              lists[idx] = lists[idx].copyWith(
                                name: nameController.text.trim(),
                                emoji: selectedEmoji,
                              );
                            }
                          });
                          _saveCurrentLists();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              setState(() => _currentLists.removeWhere((l) => l.id == id));
              _saveCurrentLists();
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

void _showEditSessionDialog(Session session) {
  final nameController = TextEditingController(text: session.name);
  String selectedEmoji = session.emoji;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Editar Sessão',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
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
                                ? const Color(0xFF6C63FF).withValues(alpha: 0.3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
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
                  hintText: 'Nome da sessão...',
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
                    child: const Text('Cancelar', style: TextStyle(color: Color(0xFF8888AA))),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (nameController.text.trim().isNotEmpty) {
                        setState(() {
                          final idx = _sessions.indexWhere((s) => s.id == session.id);
                          if (idx != -1) {
                            _sessions[idx] = _sessions[idx].copyWith(
                              name: nameController.text.trim(),
                              emoji: selectedEmoji,
                            );
                          }
                        });
                        _saveSessions();
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Salvar', style: TextStyle(fontWeight: FontWeight.bold)),
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

void _deleteSession(String id) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Excluir sessão?', style: TextStyle(color: Colors.white)),
      content: const Text(
        'Todas as listas e itens desta sessão serão perdidos.',
        style: TextStyle(color: Color(0xFF8888AA)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar', style: TextStyle(color: Color(0xFF8888AA))),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _listsMap.remove(id);
              _sessions.removeWhere((s) => s.id == id);
              _rebuildTabController();
            });
            StorageService.deleteSessionLists(id);
            _saveSessions();
            Navigator.pop(ctx);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF4757),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final lists = _currentLists;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F0F1A),
            leading: IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF8888AA)),
              onPressed: () {
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _currentSession?.name ?? 'Minhas Listas',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 48),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1A)],
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: _randomizeAll,
                  child: Chip(
                    label: Text(
                      '${lists.length} listas',
                      style: const TextStyle(
                          color: Color(0xFF6C63FF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.12),
                    side: BorderSide(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ],
            bottom: _sessions.isEmpty ? null : TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: const Color(0xFF6C63FF),
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: const Color(0xFF6C63FF),
              unselectedLabelColor: const Color(0xFF8888AA),
              dividerColor: Colors.transparent,
              tabs: [
                ..._sessions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  return GestureDetector(
                    onLongPress: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => SafeArea(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(s.name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 20),
                                ListTile(
                                  leading: const Icon(Icons.edit_rounded, color: Color(0xFF6C63FF)),
                                  title: const Text('Editar', style: TextStyle(color: Colors.white)),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _showEditSessionDialog(s);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.delete_rounded, color: Color(0xFFFF4757)),
                                  title: const Text('Excluir', style: TextStyle(color: Color(0xFFFF4757))),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _deleteSession(s.id);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: Tab(text: '${s.emoji} ${s.name}'),
                  );
                }),
                // botão de nova sessão
                GestureDetector(
                  onTap: _showCreateSessionDialog,
                  child: const Tab(
                    child: Icon(Icons.add_rounded, color: Color(0xFF8888AA), size: 20),
                  ),
                ),
              ],
            ),
          ),
          if (_sessions.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      child: const Center(
                        child: Icon(Icons.folder, size: 85), // TODO: colocar um ícone
                      )
                    ),
                    const SizedBox(height: 20),
                    const Text('Nenhuma sessão ainda',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Crie sua primeira sessão!',
                        style: TextStyle(color: Color(0xFF8888AA), fontSize: 14)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showCreateSessionDialog,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Nova Sessão'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (lists.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      child: const Center(
                        child: Icon(Icons.list_alt_rounded, size: 85),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Nenhuma lista ainda',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'Crie sua primeira lista\npara começar!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8888AA), fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final list = lists[index];
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
                                  final idx = lists.indexWhere((l) => l.id == list.id);
                                  if (idx != -1) lists[idx] = updated;
                                });
                                _saveCurrentLists();
                              },
                            ),
                          ),
                        );
                      },
                      onEdit: () => _showEditListDialog(list),
                      onDelete: () => _deleteList(list.id),
                    );
                  },
                  childCount: lists.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _sessions.isEmpty ? null : FloatingActionButton(
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
                color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    child: Center(
                      child: Text(list.emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(list.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)
                            ),
                        const SizedBox(height: 4),
                        Text(
                          '${list.items.length} ${list.items.length == 1 ? 'item' : 'itens'}',
                          style: const TextStyle(
                              color: Color(0xFF8888AA), fontSize: 13),
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
                            Text('Editar', style: TextStyle(color: Colors.white)),
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