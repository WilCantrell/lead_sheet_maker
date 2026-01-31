import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

/// Service for saving and loading lead sheets
class StorageService {
  static const String _fileName = 'lead_sheets.json';

  /// Get the storage directory
  Future<Directory> get _storageDir async {
    if (kIsWeb) {
      throw UnsupportedError('File storage not supported on web');
    }
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}/LeadSheetMaker');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }

  /// Get the storage file
  Future<File> get _storageFile async {
    final dir = await _storageDir;
    return File('${dir.path}/$_fileName');
  }

  /// Save all lead sheets
  Future<void> saveAll(List<LeadSheet> sheets) async {
    if (kIsWeb) {
      // For web, we'd use localStorage - skip for now
      return;
    }
    
    final file = await _storageFile;
    final data = {
      'version': 1,
      'sheets': sheets.map((s) => s.toJson()).toList(),
    };
    await file.writeAsString(jsonEncode(data), flush: true);
  }

  /// Load all lead sheets
  Future<List<LeadSheet>> loadAll() async {
    if (kIsWeb) {
      return [];
    }
    
    try {
      final file = await _storageFile;
      if (!await file.exists()) {
        return [];
      }
      
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final sheetsJson = data['sheets'] as List<dynamic>;
      
      return sheetsJson
          .map((s) => LeadSheet.fromJson(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading lead sheets: $e');
      return [];
    }
  }

  /// Export a single lead sheet to a file
  Future<String?> exportToFile(LeadSheet sheet, String path) async {
    if (kIsWeb) return null;
    
    try {
      final file = File(path);
      final data = sheet.toJson();
      await file.writeAsString(jsonEncode(data), flush: true);
      return path;
    } catch (e) {
      debugPrint('Error exporting lead sheet: $e');
      return null;
    }
  }

  /// Import a lead sheet from a file
  Future<LeadSheet?> importFromFile(String path) async {
    if (kIsWeb) return null;
    
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      return LeadSheet.fromJson(data);
    } catch (e) {
      debugPrint('Error importing lead sheet: $e');
      return null;
    }
  }
}
