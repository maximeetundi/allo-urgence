import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import '../models/ticket.dart';

class WebSocketService with ChangeNotifier {
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _error;

  // Getters
  bool get isConnected => _isConnected;
  String? get error => _error;

  /// Connect to WebSocket server
  void connect(String baseUrl, String token) {
    try {
      _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('✅ WebSocket connected');
        _isConnected = true;
        _error = null;
        notifyListeners();
      });

      _socket!.onDisconnect((_) {
        debugPrint('❌ WebSocket disconnected');
        _isConnected = false;
        notifyListeners();
      });

      _socket!.onConnectError((error) {
        debugPrint('❌ WebSocket connection error: $error');
        _error = error.toString();
        _isConnected = false;
        notifyListeners();
      });

      _socket!.onError((error) {
        debugPrint('❌ WebSocket error: $error');
        _error = error.toString();
        notifyListeners();
      });

      _socket!.connect();
    } catch (e) {
      debugPrint('❌ WebSocket setup error: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    notifyListeners();
  }

  /// Join a ticket room to receive updates
  void joinTicket(String ticketId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('join_ticket', ticketId);
      debugPrint('📍 Joined ticket room: $ticketId');
    }
  }

  /// Leave a ticket room
  void leaveTicket(String ticketId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('leave_ticket', ticketId);
      debugPrint('📍 Left ticket room: $ticketId');
    }
  }

  /// Join a hospital room (for staff)
  void joinHospital(String hospitalId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('join_hospital', hospitalId);
      debugPrint('📍 Joined hospital room: $hospitalId');
    }
  }

  /// Leave a hospital room
  void leaveHospital(String hospitalId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('leave_hospital', hospitalId);
      debugPrint('📍 Left hospital room: $hospitalId');
    }
  }

  /// Listen to ticket updates
  void onTicketUpdate(Function(Map<String, dynamic>) callback) {
    _socket?.on('ticket_update', (data) {
      debugPrint('📊 Ticket update received: $data');
      callback(data as Map<String, dynamic>);
    });
  }

  /// Listen to queue updates
  void onQueueUpdate(Function(Map<String, dynamic>) callback) {
    _socket?.on('queue_update', (data) {
      debugPrint('📊 Queue update received: $data');
      callback(data as Map<String, dynamic>);
    });
  }

  /// Listen to critical alerts
  void onCriticalAlert(Function(Map<String, dynamic>) callback) {
    _socket?.on('critical_alert', (data) {
      debugPrint('🚨 Critical alert received: $data');
      callback(data as Map<String, dynamic>);
    });
  }

  /// Listen to notifications
  void onNotification(Function(Map<String, dynamic>) callback) {
    _socket?.on('notification', (data) {
      debugPrint('🔔 Notification received: $data');
      callback(data as Map<String, dynamic>);
    });
  }

  /// Remove all listeners
  void removeAllListeners() {
    _socket?.off('ticket_update');
    _socket?.off('queue_update');
    _socket?.off('critical_alert');
    _socket?.off('notification');
  }
}
