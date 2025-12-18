import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final _chatMessagesController = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationsController = StreamController<Map<String, dynamic>>.broadcast();

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      // First, try to get the URL from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? webSocketServerUrl = prefs.getString('webSocketServerUrl');

      // If not found in preferences, load from config.json
      if (webSocketServerUrl == null) {
        final configContent = await rootBundle.loadString('assets/config.json');
        final config = jsonDecode(configContent);
        webSocketServerUrl = config['webSocketServerUrl'] as String?;
      }

      if (webSocketServerUrl == null || webSocketServerUrl.isEmpty) {
        throw Exception('WebSocket URL not configured');
      }

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
              case 'chat_message':
                _chatMessagesController.add(data);
                break;
            }
            // Notify listeners about server-side notifications
            if (data['type'] == 'game_destroyed') {
              _notificationsController.add(data);
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

  Future<void> reconnectWithNewUrl(String newUrl) async {
    // Close existing connection
    await disconnect();
    
    // Save new URL to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('webSocketServerUrl', newUrl);
    
    // Reconnect with new URL
    await connect();
  }

  Future<void> disconnect() async {
    _channel?.sink.close();
    _isConnected = false;
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
  Stream<Map<String, dynamic>> get chatMessages => _chatMessagesController.stream;
  Stream<Map<String, dynamic>> get notifications => _notificationsController.stream;

  void dispose() {
    _channel?.sink.close();
    _gameUpdatesController.close();
    _gamesListController.close();
    _drawingUpdatesController.close();
    _chatMessagesController.close();
    _notificationsController.close();
    _isConnected = false;
  }
}
