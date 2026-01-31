import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models/models.dart';
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
  final List<LeadSheet> _leadSheets = [];
  LeadSheet? _currentSheet;

  @override
  void initState() {
    super.initState();
    // Create an initial empty lead sheet
    _createNewSheet();
  }

  void _createNewSheet() {
    final newSheet = LeadSheet(
      id: const Uuid().v4(),
      title: 'Untitled',
      lines: [const LeadSheetLine(lyrics: '')],
    );
    setState(() {
      _leadSheets.add(newSheet);
      _currentSheet = newSheet;
    });
  }

  void _updateCurrentSheet(LeadSheet updated) {
    setState(() {
      _currentSheet = updated;
      final index = _leadSheets.indexWhere((s) => s.id == updated.id);
      if (index >= 0) {
        _leadSheets[index] = updated;
      }
    });
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
        _createNewSheet();
      }
    });
  }

  void _exportAsText() {
    if (_currentSheet == null) return;

    final text = _currentSheet!.toPlainText();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export as Text'),
        content: SingleChildScrollView(
          child: SelectableText(
            text,
            style: const TextStyle(fontFamily: 'monospace'),
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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.music_note),
            const SizedBox(width: 8),
            const Text('LeadSheetMaker'),
            if (_currentSheet != null) ...[
              const SizedBox(width: 16),
              Text(
                '— ${_currentSheet!.title}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(179),
                ),
              ),
            ],
          ],
        ),
        actions: [
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
          if (isWideScreen)
            const VerticalDivider(width: 1),
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
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _deleteSheet(sheet),
                ),
                onTap: () {
                  _selectSheet(sheet);
                  if (!MediaQuery.of(context).size.width.isFinite ||
                      MediaQuery.of(context).size.width <= 800) {
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
