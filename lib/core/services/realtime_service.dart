import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

// Callback types
typedef IncidentHandler = void Function(Map<String, dynamic> incident);
typedef DispatchHandler = void Function(Map<String, dynamic> dispatch);

class RealtimeService {
  // ── Replace with your Pusher credentials ─────────────────────────────────
  static const _appKey     = String.fromEnvironment('PUSHER_APP_KEY',     defaultValue: '');
  static const _appCluster = String.fromEnvironment('PUSHER_APP_CLUSTER', defaultValue: 'mt1');
  // ─────────────────────────────────────────────────────────────────────────

  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();

  bool _connected = false;

  Future<void> connect() async {
    if (_connected) return;
    try {
      await _pusher.init(
        apiKey:  _appKey,
        cluster: _appCluster,
        onError: (msg, code, e) {
          if (kDebugMode) print('[Pusher] error $code: $msg');
        },
        onConnectionStateChange: (current, previous) {
          if (kDebugMode) print('[Pusher] $previous → $current');
          _connected = current == 'CONNECTED';
        },
      );
      await _pusher.connect();
    } catch (e) {
      if (kDebugMode) print('[Pusher] connect failed: $e');
    }
  }

  Future<void> disconnect() async {
    await _pusher.disconnect();
    _connected = false;
  }

  // TOC dashboard — subscribe to the public incidents channel
  Future<void> listenForIncidents(IncidentHandler onIncident) async {
    await _pusher.subscribe(
      channelName: 'incidents',
      onEvent: (event) {
        if (event.eventName == 'incident.reported') {
          final data = _decode(event.data);
          if (data != null) onIncident(data);
        }
      },
    );
  }

  // Patrol app — subscribe to the private dispatch channel for this unit
  Future<void> listenForDispatch(int patrolUnitId, DispatchHandler onDispatch) async {
    await _pusher.subscribe(
      channelName: 'patrol.$patrolUnitId',
      onEvent: (event) {
        if (event.eventName == 'patrol.dispatched') {
          final data = _decode(event.data);
          if (data != null) onDispatch(data);
        }
      },
    );
  }

  Future<void> unsubscribe(String channelName) async {
    await _pusher.unsubscribe(channelName: channelName);
  }

  Map<String, dynamic>? _decode(dynamic raw) {
    try {
      return raw is String
          ? jsonDecode(raw) as Map<String, dynamic>
          : raw as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
