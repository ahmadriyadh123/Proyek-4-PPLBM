import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_001/features/models/log_model.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final dynamic currentUser;
  final bool readOnly;

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.currentUser,
    this.readOnly = false,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  bool _isPrivate = true; // Default to private per task 5 requirements
  String _selectedCategory = 'Software';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(
      text: widget.log?.description ?? '',
    );
    _isPrivate = widget.log?.isPrivate ?? true;
    
    final cat = widget.log?.category ?? 'Software';
    if (['Mechanical', 'Electronic', 'Software'].contains(cat)) {
      _selectedCategory = cat;
    } else {
      _selectedCategory = 'Software';
    }

    // TAMBAHKAN INI: Listener agar Pratinjau terupdate otomatis
    _descController.addListener(() {
      setState(() {});
    });
  }

  void _save() {
    if (widget.log == null) {
      widget.controller.addLog(
        _titleController.text,
        _descController.text,
        _selectedCategory, 
        _isPrivate,
      );
    } else {
      widget.controller.updateLog(
        widget.log!,
        _titleController.text,
        _descController.text,
        _selectedCategory,
        _isPrivate,
      );
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    // JANGAN LUPA: Bersihkan controller agar tidak memory leak
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.readOnly 
              ? "Detail Catatan" 
              : (widget.log == null ? "Catatan Baru" : "Edit Catatan")),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Editor"),
              Tab(text: "Pratinjau"),
            ],
          ),
          actions: widget.readOnly 
              ? [] 
              : [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Editor
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(_isPrivate ? "Catatan Privat" : "Catatan Publik", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(_isPrivate ? "Hanya Anda yang bisa melihat catatan ini" : "Semua anggota tim dapat melihat catatan ini"),
                    value: _isPrivate,
                    onChanged: widget.readOnly ? null : (value) {
                      setState(() {
                        _isPrivate = value;
                      });
                    },
                    secondary: Icon(_isPrivate ? Icons.lock : Icons.public),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  TextField(
                    controller: _titleController,
                    readOnly: widget.readOnly,
                    decoration: const InputDecoration(labelText: "Judul"),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: TextField(
                      controller: _descController,
                      maxLines: null,
                      expands: true,
                      readOnly: widget.readOnly,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: "Tulis laporan dengan format Markdown...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: "Kategori Bidang",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Mechanical', child: Text('Mechanical')),
                      DropdownMenuItem(value: 'Electronic', child: Text('Electronic')),
                      DropdownMenuItem(value: 'Software', child: Text('Software')),
                    ],
                    onChanged: widget.readOnly ? null : (value) {
                      setState(() {
                        if (value != null) _selectedCategory = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            // Tab 2: Markdown Preview
            Markdown(data: _descController.text),
          ],
        ),
      ),
    );
  }
}
