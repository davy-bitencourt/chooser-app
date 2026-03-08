import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/item_list.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class FileManager {
  // Retorna lista de itens ou null se o usuário cancelou
  static Future<List<ListItem>?> importItems(List<ListItem> existing) async {
    // Aceita qualquer tipo de arquivo (txt, md, csv, etc)
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result == null || result.files.single.path == null) return null;

    final file = File(result.files.single.path!);
    final lines = await file.readAsLines();

    // Nomes já existentes na lista para checar duplicatas
    final existingNames = existing.map((i) => i.name.toLowerCase()).toSet();

    final newItems = lines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        // ignora linhas que já existem na lista (case insensitive)
        .where((l) => !existingNames.contains(l.toLowerCase()))
        // ignora linhas duplicadas dentro do próprio arquivo
        .toSet()
        .map((l) => ListItem(
          id: _uuid.v4(), // gera algo tipo: "f47ac10b-58cc-4372-a567-0e02b2c3d479"
          name: l,
        ))
        .toList();

    return newItems;
  }
}