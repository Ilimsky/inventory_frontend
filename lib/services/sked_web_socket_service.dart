import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

class SkedWebSocketService {
  final String url;
  late final StompClient _client;
  final Map<int, Function(bool)> _availabilityCallbacks = {};
  final List<Function(int, bool)> _broadcastCallbacks = [];

  // SkedWebSocketService({this.url = 'ws://localhost:8060/ws-skeds'}) {
  SkedWebSocketService({this.url = 'wss://inventory-3z06.onrender.com/ws-skeds'}) {
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

  void listenToAvailability(int skedId, void Function(bool) onUpdate) {
    if (skedId == -1) {
      // Исправляем тип для широковещательных callback'ов
      _broadcastCallbacks.add((int id, bool available) => onUpdate(available));
    } else {
      _availabilityCallbacks[skedId] = onUpdate;
    }
  }

  void _onConnect(StompFrame frame) {
    _client.subscribe(
      destination: '/topic/sked-updates',
      callback: (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!);
          final skedId = data['skedId'] as int;
          final available = data['available'] as bool;

          _availabilityCallbacks[skedId]?.call(available);

          // Широковещательная рассылка
          for (final callback in _broadcastCallbacks) {
            callback(skedId, available); // Передаем оба параметра
          }
        }
      },
    );
  }

  void listenToAllUpdates(void Function(int, bool) onUpdate) {
    _broadcastCallbacks.add(onUpdate);
  }

  void pushManualChange(int skedId, bool available) {
    _client.send(
      destination: '/app/skeds/$skedId/availability',
      body: jsonEncode(available),
    );
  }

  void dispose() {
    _client.deactivate();
    _availabilityCallbacks.clear();
    _broadcastCallbacks.clear();
  }

  // В SkedWebSocketService.dart
  void pushDateChange(DateTime date) {
    _client.send(
      destination: '/app/selected-date',
      body: jsonEncode({
        'date': date.toIso8601String(),
      }),
    );
  }
}