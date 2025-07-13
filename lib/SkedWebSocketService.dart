import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

class SkedWebSocketService {
  final String url;
  late final StompClient _client;
  final Map<int, Function(bool)> _availabilityCallbacks = {};

  SkedWebSocketService({this.url = 'ws://localhost:8060/ws-skeds'}) {
  // SkedWebSocketService({this.url = 'wss://inventory-3z06.onrender.com/ws-skeds'}) {
    _client = StompClient(
      config: StompConfig(
        url: url,
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) => print('WebSocket Error: $error'),
        onStompError: (frame) => print('STOMP Error: ${frame.body}'),
        onDisconnect: (_) => print('Disconnected'),
        onDebugMessage: (msg) => print('[STOMP DEBUG] $msg'),
      ),
    );
  }

  void connect() => _client.activate();

  void _onConnect(StompFrame frame) {
    print('[WebSocket Connected]');
    _client.subscribe(
      destination: '/topic/sked-updates',
      callback: (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!);
          final skedId = data['skedId'] as int;
          final available = data['available'] as bool;

          _availabilityCallbacks[skedId]?.call(available);
        }
      },
    );
  }

  void listenToAvailability(int skedId, void Function(bool) onUpdate) {
    _availabilityCallbacks[skedId] = onUpdate;
  }

  void pushManualChange(int skedId, bool available) {
    final message = jsonEncode({'skedId': skedId, 'available': available});
    _client.send(
      destination: '/app/skeds/$skedId/availability',
      body: jsonEncode(available),
    );
  }

  void dispose() {
    _client.deactivate();
    _availabilityCallbacks.clear();
  }
}
