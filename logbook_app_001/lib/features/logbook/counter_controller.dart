import 'package:shared_preferences/shared_preferences.dart';

class CounterController {
  int _counter = 0;
  int _step = 1;
  List<String> _history = [];

  int get value => _counter;
  int get step => _step;
  List<String> get history => List.unmodifiable(_history);
  
  set step(int value) {
    if (value > 0) {
        _step = value;
    }
  }

  // Load data dari storage
  Future<void> loadData(String username) async {
    final prefs = await SharedPreferences.getInstance();
    _counter = prefs.getInt('counter_value_$username') ?? 0;
    _history = prefs.getStringList('counter_history_$username') ?? [];
    
    // Potong history jika lebih dari 5 (dari sesi sebelumnya)
    if (_history.length > 5) {
      _history = _history.sublist(0, 5);
      await _saveData(username);
    }
  }

  // Simpan data ke storage
  Future<void> _saveData(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('counter_value_$username', _counter);
    await prefs.setStringList('counter_history_$username', _history);
  }

  void increment(String username) {
    _counter += _step;
    _addHistory(username, "menambah +$_step", _counter);
    _saveData(username);
  }

  void decrement(String username) {
    if (_counter - _step >= 0) {
      _counter -= _step;
      _addHistory(username, "mengurangi -$_step", _counter);
      _saveData(username);
    }
  }

  void reset(String username) {
    _counter = 0;
    _addHistory(username, "melakukan Reset", _counter);
    _saveData(username);
  }

  void _addHistory(String username, String action, int finalValue) {
    final now = DateTime.now();
    final timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final log = "User $username $action (Total: $finalValue) pada jam $timeString";
    
    _history.insert(0, log);
    
    while (_history.length > 5) {
      _history.removeLast();
    }
  }
}
