class CounterController {
  int _counter = 0; // Variabel private (Enkapsulasi)
  int _step = 1;
  final List<String> _history = [];

  int get value => _counter; // Getter untuk akses data
  int get step => _step;
  List<String> get history => List.unmodifiable(_history);
  
  set step(int value) {
    if (value > 0) {
        _step = value;
    }
  }

  void increment(){
    _counter += _step;
    _addHistory("Increment → $_counter"); 
  }

  void decrement() { 
    if (_counter - _step >= 0) {
      _counter -= _step; 
      _addHistory("Decrement → $_counter"); } 
    }

  void reset() { 
    _counter = 0; 
    _addHistory("Reset → $_counter"); 
  }

  void _addHistory(String action) { 
    _history.add(action); 
    if (_history.length > 5) {  
      _history.removeAt(0); // buang catatan terlama 
    } 
  }
}
