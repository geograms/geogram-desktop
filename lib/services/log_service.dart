import 'dart:collection';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Global singleton for logging
class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final int maxLogMessages = 1000;
  final Queue<String> _logMessages = Queue<String>();
  final List<Function(String)> _listeners = [];
  File? _logFile;
  IOSink? _logSink;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${appDir.path}/geogram');

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      _logFile = File('${logDir.path}/log.txt');

      // Open the file sink once and keep it open
      _logSink = _logFile!.openWrite(mode: FileMode.append);
      _initialized = true;

      // Write startup marker
      _logSink!.writeln('\n=== Application Started: ${DateTime.now()} ===');
      await _logSink!.flush();
    } catch (e) {
      // Can't use log() here as we're in init(), use stderr
      stderr.writeln('Error initializing log file: $e');
    }
  }

  void _writeToFile(String message) {
    if (_logSink == null) return;

    try {
      // Write log entry to the open sink
      _logSink!.writeln(message);
    } catch (e) {
      stderr.writeln('Error writing to log file: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _logSink?.flush();
      await _logSink?.close();
    } catch (e) {
      stderr.writeln('Error closing log file: $e');
    }
  }

  void addListener(Function(String) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(String) listener) {
    _listeners.remove(listener);
  }

  List<String> get messages => _logMessages.toList();

  void log(String message) {
    final now = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
    final logEntry = '$date $time | $message';

    _logMessages.add(logEntry);

    // Keep only the last maxLogMessages
    if (_logMessages.length > maxLogMessages) {
      _logMessages.removeFirst();
    }

    // Write to file asynchronously
    _writeToFile(logEntry);

    // Notify all listeners
    for (var listener in _listeners) {
      listener(logEntry);
    }
  }

  void clear() {
    _logMessages.clear();
    for (var listener in _listeners) {
      listener('');
    }
  }
}
