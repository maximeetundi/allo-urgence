import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/constants.dart';

class SocketService {
  IO.Socket? _socket;
  bool _connected = false;

  bool get isConnected => _connected;

  void connect(String? token) {
    _socket = IO.io(AppConstants.wsBaseUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .enableAutoConnect()
      .setExtraHeaders(token != null ? {'Authorization': 'Bearer $token'} : {})
      .build());

    _socket!.onConnect((_) {
      _connected = true;
      print('🔌 WebSocket connecté');
    });

    _socket!.onDisconnect((_) {
      _connected = false;
      print('❌ WebSocket déconnecté');
    });
  }

  void joinHospital(String hospitalId) {
    _socket?.emit('join_hospital', hospitalId);
  }

  void joinTicket(String ticketId) {
    _socket?.emit('join_ticket', ticketId);
  }

  void leaveHospital(String hospitalId) {
    _socket?.emit('leave_hospital', hospitalId);
  }

  void onQueueUpdate(Function(dynamic) callback) {
    _socket?.on('queue_update', callback);
  }

  void onTicketUpdate(Function(dynamic) callback) {
    _socket?.on('ticket_update', callback);
  }

  void onNewTicket(Function(dynamic) callback) {
    _socket?.on('new_ticket', callback);
  }

  void onPatientCheckin(Function(dynamic) callback) {
    _socket?.on('patient_checkin', callback);
  }

  void onCriticalAlert(Function(dynamic) callback) {
    _socket?.on('critical_alert', callback);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _connected = false;
  }
}

final socketService = SocketService();
