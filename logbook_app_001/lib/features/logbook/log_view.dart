import 'package:flutter/material.dart';
import 'log_controller.dart';
import 'package:logbook_app_001/features/models/log_model.dart';
import 'package:intl/intl.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logbook_app_001/features/logbook/log_editor_page.dart';
import 'package:logbook_app_001/services/access_policy.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lottie/lottie.dart';

class LogView extends StatefulWidget {
  final String username;
  final String role;
  final String teamId;
  const LogView({
    super.key, 
    required this.username, 
    required this.role, 
    required this.teamId,
  });

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late LogController _controller;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _controller = LogController(widget.username, widget.teamId, widget.role);
    _refreshLogs();
  }

  Future<void> _refreshLogs() async {
    setState(() {
      _isLoading = true;
      _isOffline = false;
    });

    var connectivityResult = await (Connectivity().checkConnectivity());
    bool isOffline = connectivityResult.contains(ConnectivityResult.none);

    if (isOffline) {
      if (mounted) {
        setState(() {
          _isOffline = true;
          _isLoading = false;
        });
      }
      // Kita tetap load logs dari memori lokal (Hive) meskipun offline
      await _controller.loadLogs();
      return;
    }

    // Jika online, LogController akan otomatis melakukan push _syncUnsyncedLogs_
    // dan menarik data terbaru.
    await _controller.loadLogs();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isOffline = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _navigateToAddLog() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          controller: _controller,
          currentUser: {'uid': widget.username, 'teamId': widget.teamId},
        ),
      ),
    );
    _refreshLogs();
  }

  void _navigateToEditLog(LogModel log) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          controller: _controller,
          currentUser: {'uid': widget.username, 'teamId': widget.teamId},
        ),
      ),
    );
    _refreshLogs();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Daily Logger: ${widget.username}"),
            Text("Tim: ${widget.teamId} | Peran: ${widget.role}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
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
                if (_isLoading && currentLogs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Menyinkronkan data..."),
                      ],
                    ),
                  );
                }

                if (_isOffline && currentLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text("Offline Mode Warning", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        const SizedBox(height: 8),
                        const Text("Gagal menghubungi server MongoDB.\nData lokal juga kosong.", textAlign: TextAlign.center),
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

                if (currentLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isOffline)
                          const Icon(Icons.cloud_off, size: 64, color: Colors.grey)
                        else
                          Lottie.network(
                            'https://raw.githubusercontent.com/xvrh/lottie-flutter/master/example/assets/LottieLogo1.json',
                            height: 150,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.inbox, size: 64, color: Colors.grey),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          _isOffline ? "Anda sedang offline. Belum ada catatan lokal." : "Belum ada aktivitas hari ini?\nMulai catat kemajuan proyek Anda!",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _navigateToAddLog,
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
                      final bool canEdit = AccessControlService.canPerform(widget.role, AccessControlService.actionUpdate, isOwner: log.authorId == widget.username);
                      final bool canDelete = AccessControlService.canPerform(widget.role, AccessControlService.actionDelete, isOwner: log.authorId == widget.username);
                      
                      Color cardColor;
                      Color iconColor;
                      IconData categoryIcon;
                      
                      switch (log.category) {
                        case 'Mechanical':
                          cardColor = Colors.green.shade50;
                          iconColor = Colors.green;
                          categoryIcon = Icons.precision_manufacturing;
                          break;
                        case 'Electronic':
                          cardColor = Colors.cyan.shade50;
                          iconColor = Colors.cyan;
                          categoryIcon = Icons.electrical_services;
                          break;
                        case 'Software':
                        default:
                          cardColor = Colors.orange.shade50;
                          iconColor = Colors.orange;
                          categoryIcon = Icons.computer;
                          break;
                      }

                      Widget cardLayout = Card(
                        color: cardColor,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0, left: 0.0, right: 0.0),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: iconColor.withAlpha((255 * 0.2).toInt()),
                                  child: Icon(categoryIcon, color: iconColor),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(child: Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    if (widget.role == 'Ketua' && log.authorId == widget.username)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo.withAlpha(25),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.indigo.withAlpha(100)),
                                        ),
                                        child: const Text('Milik Anda', style: TextStyle(fontSize: 10, color: Colors.indigo, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 5),
                                    MarkdownBody(data: log.description), // Render otomatis markdown ke header
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
                                if (canEdit || canDelete)
                                  ...[
                                    if (canEdit)
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue), 
                                        onPressed: () => _navigateToEditLog(log),
                                        tooltip: 'Edit',
                                      ),
                                    if (canDelete)
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red), 
                                        onPressed: () {
                                          if (!mounted) return;
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
                                                    final navigator = Navigator.of(context);
                                                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                                                    
                                                    navigator.pop();
                                                    await _controller.removeLog(log, widget.role);
                                                    if (mounted) {
                                                      scaffoldMessenger.showSnackBar(
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
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0, bottom: 8.0, right: 12.0),
                          child: Row(
                            children: [
                              Icon(
                                log.isSynced ? Icons.cloud_done : Icons.cloud_off,
                                color: log.isSynced ? Colors.green : Colors.red,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                log.isSynced ? "Tersinkronisasi" : "Menunggu jaringan...",
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );

                      if (canDelete) {
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
                            await _controller.removeLog(log, widget.role);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Catatan dihapus")),
                              );
                              _refreshLogs();
                            }
                          },
                          child: cardLayout,
                        );
                      } else {
                        return cardLayout;
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddLog,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        tooltip: 'Tambah Catatan Baru',
        child: const Icon(Icons.add),
      ),
    );
  }
}