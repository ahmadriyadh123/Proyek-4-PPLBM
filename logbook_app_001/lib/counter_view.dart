import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});
  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LogBook: SRP Version")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Total Hitungan:"),
            Text('${_controller.value}', 
            style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 20),
            Text("Step: ${_controller.step}"),
            SizedBox( 
                width: 100, 
                child: TextField( 
                    keyboardType: TextInputType.number, 
                    decoration: const InputDecoration(labelText: "Step"), 
                    onSubmitted: (val) { final stepValue = int.tryParse(val); 
                    if (stepValue != null && stepValue > 0) { setState(() => _controller.step = stepValue); 
                    } 
                },
                ),
            ),
                const SizedBox(height: 20), 
                const Text("History:"), 
                ..._controller.history.map((item) => Text(item)).toList(),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
            FloatingActionButton(
                onPressed: () => setState(() => _controller.increment()),
                child: const Icon(Icons.add),
            ),
            FloatingActionButton(
                onPressed: () => setState(() => _controller.decrement()),
                child: const Icon(Icons.remove),
            ),
            FloatingActionButton(
                onPressed: () => setState(() => _controller.reset()),
                child: const Icon(Icons.refresh),
            ),
        ],
      ),

    );
  }
}
