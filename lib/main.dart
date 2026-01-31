import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models/models.dart';
import 'services/services.dart';
import 'widgets/widgets.dart';

void main() {
  runApp(const LeadSheetMakerApp());
}

class LeadSheetMakerApp extends StatelessWidget {
  const LeadSheetMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LeadSheetMaker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StorageService _storage = StorageService();
  final List<LeadSheet> _leadSheets = [];
  LeadSheet? _currentSheet;
  bool _isLoading = true;
  bool _isSaving = false;
  DateTime? _lastSaved;

  @override
  void initState() {
    super.initState();
    _loadSheets();
  }

  Future<void> _loadSheets() async {
    setState(() => _isLoading = true);
    
    try {
      final loaded = await _storage.loadAll();
      setState(() {
        _leadSheets.clear();
        _leadSheets.addAll(loaded);
        if (_leadSheets.isEmpty) {
          _createNewSheet(save: false);
        } else {
          _currentSheet = _leadSheets.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _createNewSheet(save: false);
      });
    }
  }

  Future<void> _saveSheets() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    
    try {
      await _storage.saveAll(_leadSheets);
      setState(() {
        _lastSaved = DateTime.now();
        _isSaving = false;
      });
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _createNewSheet({bool save = true}) {
    final newSheet = LeadSheet(
      id: const Uuid().v4(),
      title: 'Untitled',
      lines: [const LeadSheetLine(lyrics: '')],
    );
    setState(() {
      _leadSheets.add(newSheet);
      _currentSheet = newSheet;
    });
    if (save) _saveSheets();
  }

  void _updateCurrentSheet(LeadSheet updated) {
    setState(() {
      _currentSheet = updated;
      final index = _leadSheets.indexWhere((s) => s.id == updated.id);
      if (index >= 0) {
        _leadSheets[index] = updated;
      }
    });
    _saveSheets(); // Auto-save on changes
  }

  void _selectSheet(LeadSheet sheet) {
    setState(() {
      _currentSheet = sheet;
    });
  }

  void _deleteSheet(LeadSheet sheet) {
    setState(() {
      _leadSheets.remove(sheet);
      if (_currentSheet?.id == sheet.id) {
        _currentSheet = _leadSheets.isNotEmpty ? _leadSheets.first : null;
      }
      if (_leadSheets.isEmpty) {
        _createNewSheet(save: false);
      }
    });
    _saveSheets();
  }

  void _duplicateSheet(LeadSheet sheet) {
    final duplicate = LeadSheet(
      id: const Uuid().v4(),
      title: '${sheet.title} (Copy)',
      artist: sheet.artist,
      key: sheet.key,
      tempo: sheet.tempo,
      lines: sheet.lines,
    );
    setState(() {
      _leadSheets.add(duplicate);
      _currentSheet = duplicate;
    });
    _saveSheets();
  }

  void _exportAsText() {
    if (_currentSheet == null) return;

    final text = _currentSheet!.toPlainText();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.text_snippet),
            const SizedBox(width: 8),
            const Text('Export as Text'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Loading lead sheets...', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.music_note),
            const SizedBox(width: 8),
            const Text('LeadSheetMaker'),
            if (_currentSheet != null) ...[
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  '— ${_currentSheet!.title}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(179),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Save indicator
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_lastSaved != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Tooltip(
                message: 'Last saved: ${_lastSaved!.hour}:${_lastSaved!.minute.toString().padLeft(2, '0')}',
                child: Icon(
                  Icons.cloud_done,
                  size: 20,
                  color: theme.colorScheme.primary.withAlpha(179),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.text_snippet),
            onPressed: _currentSheet != null ? _exportAsText : null,
            tooltip: 'Export as Text',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isWideScreen ? null : _buildDrawer(context),
      body: Row(
        children: [
          // Side panel for sheets list (on wide screens)
          if (isWideScreen)
            SizedBox(
              width: 280,
              child: _buildSheetsList(context),
            ),
          // Divider
          if (isWideScreen) const VerticalDivider(width: 1),
          // Main editor
          Expanded(
            child: _currentSheet != null
                ? LeadSheetEditor(
                    key: ValueKey(_currentSheet!.id),
                    leadSheet: _currentSheet!,
                    onChanged: _updateCurrentSheet,
                  )
                : const Center(
                    child: Text('No lead sheet selected'),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewSheet,
        tooltip: 'New Lead Sheet',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: _buildSheetsList(context),
    );
  }

  Widget _buildSheetsList(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(Icons.library_music, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Lead Sheets', style: theme.textTheme.titleMedium),
              const Spacer(),
              Text(
                '${_leadSheets.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _leadSheets.length,
            itemBuilder: (context, index) {
              final sheet = _leadSheets[index];
              final isSelected = sheet.id == _currentSheet?.id;

              return ListTile(
                selected: isSelected,
                leading: const Icon(Icons.description),
                title: Text(
                  sheet.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: sheet.artist.isNotEmpty
                    ? Text(
                        sheet.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 18),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteSheet(sheet);
                    } else if (value == 'duplicate') {
                      _duplicateSheet(sheet);
                    }
                  },
                ),
                onTap: () {
                  _selectSheet(sheet);
                  if (MediaQuery.of(context).size.width <= 800) {
                    Navigator.pop(context); // Close drawer on mobile
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
