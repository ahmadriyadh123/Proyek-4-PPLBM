import 'package:flutter/material.dart';
import 'counter_controller.dart';
import '../onboarding/onboarding_view.dart';
import 'log_view.dart';

class CounterView extends StatefulWidget {
  final String username;

  // Update constructor agar mewajibkan (required) kiriman nama
  const CounterView({super.key, required this.username});
  
  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return 'Selamat Pagi';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat Siang';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    await _controller.loadData(widget.username);
    setState(() {}); // Refresh UI setelah data dimuat
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("LogBook: ${widget.username}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.book),
            tooltip: 'Daily Logger',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LogView(username: widget.username)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // 1. Munculkan Dialog Konfirmasi
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Konfirmasi Logout"),
                    content: const Text("Apakah Anda yakin? Data yang belum disimpan mungkin akan hilang."),
                    actions: [
                      // Tombol Batal
                      TextButton(
                        onPressed: () => Navigator.pop(context), // Menutup dialog saja
                        child: const Text("Batal"),
                      ),
                      // Tombol Ya, Logout
                      TextButton(
                        onPressed: () {
                          // Menutup dialog
                          Navigator.pop(context); 
                          
                          // 2. Navigasi kembali ke Onboarding (Membersihkan Stack)
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const OnboardingView()),
                            (route) => false,
                          );
                        },
                        child: const Text("Ya, Keluar", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Banner
            Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                   Icon(
                    DateTime.now().hour >= 18 || DateTime.now().hour < 6 
                        ? Icons.nightlight_round 
                        : Icons.wb_sunny,
                    color: Colors.orange,
                    size: 40,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(), // Panggil fungsi greeting
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]), 
                        ),
                        Text(
                          widget.username,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Counter Display Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
                child: Column(
                  children: [
                    const Text("Total Hitungan", style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Text(
                      '${_controller.value}',
                      style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Step Configuration
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Step:", style: TextStyle(fontSize: 16)),
                const SizedBox(width: 15),
                SizedBox(
                  width: 80,
                  child: TextField(
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                       contentPadding: const EdgeInsets.symmetric(vertical: 8),
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    controller: TextEditingController(text: _controller.step.toString()),
                    onSubmitted: (val) {
                      final stepValue = int.tryParse(val);
                      if (stepValue != null && stepValue > 0) {
                        setState(() => _controller.step = stepValue);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // History Log
            const Text("History Log", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView( // Changed from Map to ListView for better scrolling if needed, but constrained height
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _controller.history.isEmpty
                    ? [const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text("-")))]
                    : _controller.history.map((item) {
                        Color textColor = Colors.black87;
                        IconData icon = Icons.circle; 
                        Color iconColor = Colors.grey;

                        if (item.toLowerCase().contains('increment')) {
                          textColor = Colors.green[800]!;
                          icon = Icons.arrow_upward;
                          iconColor = Colors.green;
                        } else if (item.toLowerCase().contains('decrement')) {
                          textColor = Colors.red[800]!;
                          icon = Icons.arrow_downward;
                          iconColor = Colors.red;
                        } else if (item.toLowerCase().contains('reset')) {
                           icon = Icons.refresh;
                           iconColor = Colors.blue;
                        }

                        return ListTile(
                          leading: Icon(icon, color: iconColor, size: 20),
                          title: Text(item, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                          dense: true,
                        );
                      }).toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
            FloatingActionButton(
              onPressed: () => setState(() => _controller.increment(widget.username)),
              backgroundColor: Colors.green,
              child: const Icon(Icons.add),
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              onPressed: () => setState(() => _controller.decrement(widget.username)),
              backgroundColor: Colors.red,
              child: const Icon(Icons.remove),
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Konfirmasi Reset"),
                    content: const Text("Apakah kamu yakin ingin mereset counter?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal"),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _controller.reset(widget.username));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Counter berhasil di-reset")),
                          );
                        },
                        child: const Text("Ya, Reset"),
                      ),
                    ],
                  ),
                );
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.refresh),
            ),
        ],
      ),

    );
  }
}
