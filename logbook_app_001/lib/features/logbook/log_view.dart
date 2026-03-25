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
import 'dart:async';

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
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _controller = LogController(widget.username, widget.teamId, widget.role);
    _refreshLogs();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isNowOffline = results.contains(ConnectivityResult.none) || results.isEmpty;
      if (!isNowOffline && _wasOffline) {
        // Otomatis sinkronisasi ketika jaringan internet kembali terhubung
        _refreshLogs();
      }
      _wasOffline = isNowOffline;
    });
  }

  Future<void> _refreshLogs() async {
    if (!mounted) return;
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
      await _controller.loadLogs();
      return;
    }

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
    _connectivitySubscription.cancel();
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

  void _navigateToEditLog(LogModel log, {bool readOnly = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          controller: _controller,
          currentUser: {'uid': widget.username, 'teamId': widget.teamId},
          readOnly: readOnly,
        ),
      ),
    );
    if (!readOnly) _refreshLogs();
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) return "Baru saja";
      if (difference.inMinutes < 60)
        return "${difference.inMinutes} menit yang lalu";
      if (difference.inHours < 24) return "${difference.inHours} jam yang lalu";
      if (difference.inDays < 7) return "${difference.inDays} hari yang lalu";

      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
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
            Text(
              "Tim: ${widget.teamId} | Peran: ${widget.role}",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Konfirmasi Logout"),
                  content: const Text("Apakah Anda yakin ingin keluar?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OnboardingView(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        "Keluar",
                        style: TextStyle(color: Colors.red),
                      ),
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
                final bool isSearchEmpty =
                    _controller.logsNotifier.value.isNotEmpty &&
                    currentLogs.isEmpty;
                Widget content;

                if (_isLoading && _controller.logsNotifier.value.isEmpty) {
                  content = const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Menyinkronkan data..."),
                      ],
                    ),
                  );
                } else if (_isOffline &&
                    _controller.logsNotifier.value.isEmpty) {
                  content = Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Offline Mode Warning",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Gagal menghubungi server MongoDB.\nData lokal juga kosong.",
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refreshLogs,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Coba Lagi"),
                        ),
                      ],
                    ),
                  );
                } else if (isSearchEmpty) {
                  content = const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Tidak ada catatan yang cocok.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (_controller.logsNotifier.value.isEmpty) {
                  // Hanya tampilkan lottie jika memang database kosong secara keseluruhan
                  content = Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isOffline)
                          const Icon(
                            Icons.cloud_off,
                            size: 64,
                            color: Colors.grey,
                          )
                        else
                          Lottie.network(
                            'https://raw.githubusercontent.com/xvrh/lottie-flutter/master/example/assets/LottieLogo1.json',
                            height: 150,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.inbox,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          _isOffline
                              ? "Anda sedang offline. Belum ada catatan lokal."
                              : "Belum ada aktivitas hari ini?\nMulai catat kemajuan proyek Anda!",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _navigateToAddLog,
                          child: const Text("Buat Catatan Pertama"),
                        ),
                      ],
                    ),
                  );
                } else {
                  content = ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: currentLogs.length,
                    itemBuilder: (context, index) {
                      final log = currentLogs[index];
                      final bool canEdit = AccessControlService.canPerform(
                        widget.role,
                        AccessControlService.actionUpdate,
                        isOwner: log.authorId == widget.username,
                        isPrivate: log.isPrivate,
                      );
                      final bool canDelete = AccessControlService.canPerform(
                        widget.role,
                        AccessControlService.actionDelete,
                        isOwner: log.authorId == widget.username,
                        isPrivate: log.isPrivate,
                      );

                      Color cardColor = Colors.orange.shade50;
                      Color iconColor = Colors.orange;
                      IconData categoryIcon = Icons.computer;

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
                      }

                      Widget cardLayout = Card(
                        color: cardColor,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              onTap: () => _navigateToEditLog(log, readOnly: !canEdit),
                              leading: CircleAvatar(
                                backgroundColor: iconColor.withOpacity(0.2),
                                child: Icon(categoryIcon, color: iconColor),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      log.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (log.authorId == widget.username)
                                    const Text(
                                      ' (Milik Anda)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 5),
                                  MarkdownBody(data: log.description),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatTimestamp(log.timestamp),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (canEdit)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () => _navigateToEditLog(log),
                                    ),
                                  if (canDelete)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        bool confirm = await showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("Hapus Catatan"),
                                            content: const Text("Yakin ingin menghapus catatan ini?"),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
                                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
                                            ],
                                          ),
                                        ) ?? false;

                                        if (confirm) {
                                          await _controller.removeLog(log, widget.role);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Catatan dihapus")),
                                            );
                                          }
                                          _refreshLogs();
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 12.0,
                                bottom: 8.0,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    log.isSynced
                                        ? Icons.cloud_done
                                        : Icons.cloud_off,
                                    color: log.isSynced
                                        ? Colors.green
                                        : Colors.red,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    log.isSynced
                                        ? "Tersinkronisasi"
                                        : "Menunggu jaringan...",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );

                      if (canDelete) {
                        return Dismissible(
                          key: Key(log.timestamp),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (direction) async {
                            await _controller.removeLog(log, widget.role);
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Catatan dihapus"),
                                ),
                              );
                            _refreshLogs();
                          },
                          child: cardLayout,
                        );
                      }
                      return cardLayout;
                    },
                  );
                }

                // Agar RefreshIndicator bekerja pada kondisi kosong
                return RefreshIndicator(
                  onRefresh: _refreshLogs,
                  child: currentLogs.isEmpty
                      ? LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Container(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: content,
                                ),
                              ),
                        )
                      : content,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddLog,
        child: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }
}
