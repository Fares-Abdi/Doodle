import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle; // Add this import
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  WebSocketService._internal() {
    connect(); // Initialize connection in constructor
  }

  WebSocketChannel? _channel;
  bool _isConnected = false;
  final _gameUpdatesController = StreamController<Map<String, dynamic>>.broadcast();
  final _gamesListController = StreamController<List<dynamic>>.broadcast();
  final _drawingUpdatesController = StreamController<Map<String, dynamic>>.broadcast();

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final configContent = await rootBundle.loadString('assets/config.json'); // Load the config file from assets
      final config = jsonDecode(configContent);
      final webSocketServerUrl = config['webSocketServerUrl'];

      _channel = WebSocketChannel.connect(
        Uri.parse(webSocketServerUrl),
      );
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            switch (data['type']) {
              case 'game_update':
                _gameUpdatesController.add(data['payload']);
                break;
              case 'games_list':
                _gamesListController.add(data['payload']);
                break;
              case 'drawing_update':
                _drawingUpdatesController.add(data);
                break;
            }
          } catch (e) {
            print('Error processing message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          print('WebSocket connection closed');
          _handleDisconnect();
        },
      );
    } catch (e) {
      print('Failed to connect: $e');
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    // Try to reconnect after a delay
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isConnected) connect();
    });
  }

  void sendMessage(String type, String gameId, dynamic payload) {
    if (!_isConnected || _channel == null) {
      print('Cannot send message: WebSocket not connected');
      connect(); // Try to reconnect
      return;
    }

    try {
      _channel!.sink.add(jsonEncode({
        'type': type,
        'gameId': gameId,
        'payload': payload,
      }));
    } catch (e) {
      print('Error sending message: $e');
      _handleDisconnect();
    }
  }

  Stream<Map<String, dynamic>> get gameUpdates => _gameUpdatesController.stream;
  Stream<List<dynamic>> get gamesList => _gamesListController.stream;
  Stream<Map<String, dynamic>> get drawingUpdates => _drawingUpdatesController.stream;

  void dispose() {
    _channel?.sink.close();
    _gameUpdatesController.close();
    _gamesListController.close();
    _drawingUpdatesController.close();
    _isConnected = false;
  }
}
