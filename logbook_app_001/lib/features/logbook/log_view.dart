import 'package:flutter/material.dart';
import 'log_controller.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:intl/intl.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late LogController _controller;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = LogController(widget.username);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _showAddLogDialog() {
    _titleController.clear();
    _contentController.clear();
    String selectedCategory = 'Pekerjaan';
    final categories = ['Pekerjaan', 'Pribadi', 'Urgent'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Tambah Catatan Baru"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: "Judul Catatan"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: "Kategori"),
                  items: categories.map((String category) {
                    return DropdownMenuItem(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setStateDialog(() {
                        selectedCategory = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(labelText: "Isi Deskripsi"),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_titleController.text.isNotEmpty && _contentController.text.isNotEmpty) {
                    _controller.addLog(
                      _titleController.text, 
                      _contentController.text,
                      selectedCategory
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text("Simpan"),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showEditLogDialog(int index, LogModel log) {
    _titleController.text = log.title;
    _contentController.text = log.description;
    String selectedCategory = ['Pekerjaan', 'Pribadi', 'Urgent'].contains(log.category) ? log.category : 'Pekerjaan';
    final categories = ['Pekerjaan', 'Pribadi', 'Urgent'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Edit Catatan"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: "Judul Catatan"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: "Kategori"),
                  items: categories.map((String category) {
                    return DropdownMenuItem(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setStateDialog(() {
                        selectedCategory = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(labelText: "Isi Deskripsi"),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
              ElevatedButton(
                onPressed: () {
                  if (_titleController.text.isNotEmpty && _contentController.text.isNotEmpty) {
                    _controller.updateLog(index, _titleController.text, _contentController.text, selectedCategory);
                    Navigator.pop(context);
                  }
                },
                child: const Text("Update"),
              ),
            ],
          );
        }
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Daily Logger: ${widget.username}"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Munculkan Dialog Konfirmasi
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Konfirmasi Logout"),
                  content: const Text("Apakah Anda yakin ingin keluar?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context), 
                      child: const Text("Batal")
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const OnboardingView()),
                          (route) => false, 
                        );
                      },
                      child: const Text("Keluar", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Latar Belakang Empty State (Tetap di tengah layar, tidak terpengaruh keyboard)
          ValueListenableBuilder<List<LogModel>>(
            valueListenable: _controller.filteredLogs,
            builder: (context, currentLogs, child) {
              if (currentLogs.isEmpty) {
                return Positioned(
                  // Menggunakan fix offset dari atas layar agar tidak terdorong keyboard
                  // atau bisa menggunakan IgnorePointer + Opacity
                  top: MediaQuery.of(context).size.height * 0.25,
                  child: IgnorePointer(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Opacity(
                          opacity: 0.5,
                          child: Image.asset(
                            'assets/empty.jpg',
                            width: 200,
                          ),
                        ),
                        const SizedBox(height: 0),
                        const Text(
                          "Belum ada catatan hari ini.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Konten Utama (Search & List)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  onChanged: (value) => _controller.searchLog(value),
                  decoration: const InputDecoration(
                    labelText: "Cari Catatan...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<List<LogModel>>(
                  valueListenable: _controller.filteredLogs,
                  builder: (context, currentLogs, child) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: currentLogs.length,
                      itemBuilder: (context, index) {
                        final log = currentLogs[index];
                        Color cardColor;
                    Color iconColor;
                    IconData categoryIcon;
                    switch (log.category) {
                      case 'Pribadi':
                        cardColor = Colors.green.shade50;
                        iconColor = Colors.green;
                        categoryIcon = Icons.person;
                        break;
                      case 'Urgent':
                        cardColor = Colors.red.shade50;
                        iconColor = Colors.red;
                        categoryIcon = Icons.warning_amber_rounded;
                        break;
                      case 'Pekerjaan':
                      default:
                        cardColor = Colors.indigo.shade50;
                        iconColor = Colors.indigo;
                        categoryIcon = Icons.work;
                        break;
                    }

                    return Dismissible(
                      key: Key(log.timestamp), // Gunakan identitas unik (timestamp)
                      direction: DismissDirection.endToStart, // Swipe dari kanan ke kiri
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        _controller.removeLog(index);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Catatan dihapus")),
                        );
                      },
                      child: Card(
                        color: cardColor,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: iconColor.withOpacity(0.2),
                              child: Icon(categoryIcon, color: iconColor),
                            ),
                            title: Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 5),
                                    Text(log.description),
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatTimestamp(log.timestamp),
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue), 
                                      onPressed: () => _showEditLogDialog(index, log),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red), 
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("Hapus Catatan"),
                                            content: const Text("Yakin ingin menghapus catatan ini?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context), 
                                                child: const Text("Batal")
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  _controller.removeLog(index);
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text("Catatan dihapus")),
                                                  );
                                                }, 
                                                child: const Text("Hapus", style: TextStyle(color: Colors.red))
                                              ),
                                            ],
                                          )
                                        );
                                      },
                                      tooltip: 'Hapus',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLogDialog,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Tambah Catatan Baru',
      ),
    );
  }
}
