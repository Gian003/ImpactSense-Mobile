import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import 'api_client.dart';
import 'session_service.dart';

// Callback types
typedef IncidentHandler       = void Function(Map<String, dynamic> incident);
typedef IncidentUpdateHandler = void Function(Map<String, dynamic> update);
typedef DispatchHandler       = void Function(Map<String, dynamic> dispatch);

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
        onAuthorizer: _authorizeChannel,
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

  // TOC dashboard — subscribe to the public incidents channel.
  // Handles both incident.reported and incident.status_updated events.
  Future<void> listenForIncidents(
    IncidentHandler onIncident, {
    IncidentUpdateHandler? onStatusUpdate,
  }) async {
    await _pusher.subscribe(
      channelName: 'incidents',
      onEvent: (event) {
        final data = _decode(event.data);
        if (data == null) return;

        if (event.eventName == 'incident.reported') {
          onIncident(data);
        } else if (event.eventName == 'incident.status_updated') {
          onStatusUpdate?.call(data);
        }
      },
    );
  }

  // Patrol app — subscribe to the private dispatch channel for this unit.
  // Requires the "private-" prefix so the Pusher client knows to run the
  // auth handshake (see _authorizeChannel below) before subscribing.
  Future<void> listenForDispatch(int patrolUnitId, DispatchHandler onDispatch) async {
    await _pusher.subscribe(
      channelName: 'private-patrol.$patrolUnitId',
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

  // Authorizes private-channel subscriptions against the Laravel backend's
  // Sanctum-guarded broadcasting auth route (routes/api.php →
  // Broadcast::routes(['middleware' => ['auth:sanctum']])), using the same
  // bearer token every other authenticated API call already uses.
  Future<dynamic> _authorizeChannel(
    String channelName,
    String socketId,
    dynamic options,
  ) async {
    final token = await SessionService.getToken();
    if (token == null) {
      throw Exception('Cannot authorize private channel: no session token.');
    }

    final base = await ApiClient.baseUrl;
    final response = await http.post(
      Uri.parse('$base/broadcasting/auth'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'socket_id':    socketId,
        'channel_name': channelName,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Channel auth failed (${response.statusCode}): ${response.body}',
      );
    }

    return jsonDecode(response.body);
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