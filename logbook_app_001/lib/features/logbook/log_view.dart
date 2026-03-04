import 'package:flutter/material.dart';
import 'log_controller.dart';
import 'package:logbook_app_001/features/models/log_model.dart';
import 'package:intl/intl.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

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
  String _searchQuery = "";
  late Future<List<LogModel>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _controller = LogController(widget.username);
    _refreshLogs();
  }

  Future<void> _refreshLogs() async {
    setState(() {
      _logsFuture = MongoService().getLogs();
    });
    await _logsFuture;
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
                onPressed: () async {
                  if (_titleController.text.isNotEmpty && _contentController.text.isNotEmpty) {
                    await _controller.addLog(
                      _titleController.text, 
                      _contentController.text,
                      selectedCategory
                    );
                    if (mounted) Navigator.pop(context);
                    _refreshLogs(); // Auto-refresh UI setelah integrasi MongoDB
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

  void _showEditLogDialog(LogModel log) {
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
                onPressed: () async {
                  if (_titleController.text.isNotEmpty && _contentController.text.isNotEmpty) {
                    await _controller.updateLog(log, _titleController.text, _contentController.text, selectedCategory);
                    if (mounted) Navigator.pop(context);
                    _refreshLogs(); // Auto-refresh UI setelah integrasi MongoDB
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
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return "Baru saja";
      } else if (difference.inMinutes < 60) {
        return "${difference.inMinutes} menit yang lalu";
      } else if (difference.inHours < 24) {
        return "${difference.inHours} jam yang lalu";
      } else if (difference.inDays < 7) {
        return "${difference.inDays} hari yang lalu";
      } else {
        return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
      }
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                labelText: "Cari Catatan...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<LogModel>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Menghubungkan ke MongoDB Atlas..."),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, size: 64, color: Colors.blueGrey),
                        const SizedBox(height: 16),
                        const Text("Offline Mode Warning", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        const SizedBox(height: 8),
                        const Text("Gagal menghubungi server MongoDB.\nPeriksa sinyal atau IP Whitelist Anda.", textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refreshLogs, 
                          icon: const Icon(Icons.refresh), 
                          label: const Text("Coba Lagi")
                        ),
                      ],
                    ),
                  );
                }

                final rawLogs = snapshot.data ?? [];
                // Terapkan filter pencarian secara real-time pada data hasil Cloud
                final currentLogs = _searchQuery.isEmpty 
                  ? rawLogs 
                  : rawLogs.where((log) => log.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                if (currentLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text("Belum ada catatan di Cloud / Hasil Pencarian Kosong."),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _showAddLogDialog,
                          child: const Text("Buat Catatan Pertama"),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshLogs,
                  child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: currentLogs.length,
                      itemBuilder: (context, index) {
                        final log = currentLogs[index];
                        // index asli dibutuhkan buat Delete, but wait, if it's filtered, index is wrong!
                        // Remove by log.id or the original log object. Or we can just pass `log` to delete.
                        // Wait, removeLog takes index based on logsNotifier... I will rewrite removeLog to take log object or we must find its true index!
                        // Let's pass `log` to _showEditLogDialog as well... Wait edit dialog needs true index?
                        // No, the Cloud operations rely ONLY on `log.id!`. The index parameter in controller was for local array.
                        // I'll leave the UI passing the loop index for now, but my LogController updateLog/removeLog actually uses that index strictly. This is a bug!
                        // I NEED to fix the LogController in the next step to not use `index` but the `log.id`.
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
                      onDismissed: (direction) async {
                        await _controller.removeLog(log);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Catatan dihapus")),
                          );
                          _refreshLogs();
                        }
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
                                      onPressed: () => _showEditLogDialog(log),
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
                                                onPressed: () async {
                                                  Navigator.pop(context);
                                                  await _controller.removeLog(log);
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text("Catatan dihapus")),
                                                    );
                                                    _refreshLogs();
                                                  }
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
                    ),
                  );
                  },
                ),
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
