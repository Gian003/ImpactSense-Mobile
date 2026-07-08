import 'dart:async';
import 'package:multicast_dns/multicast_dns.dart';

/// Resolves "impactsense.local" to an IP via mDNS at runtime, so the app
/// doesn't need a hardcoded backend IP that breaks every time the backend
/// machine's DHCP lease changes.
///
/// The matching pieces of this fix live in the other two repos: the backend
/// machine advertises this name via ImpactSenceAdmin/scripts/mdns-advertise.js
/// (started by `composer run dev`), and the ESP32 firmware resolves the same
/// name in ImpactSense-Device/src/connectivity.cpp (resolveApiHost()).
///
/// Unlike iOS/macOS, Android does not transparently resolve ".local" names
/// through its normal DNS resolver, so this does an explicit mDNS query
/// instead of just embedding "impactsense.local" in a URL. Requires the
/// ACCESS_WIFI_STATE / CHANGE_WIFI_MULTICAST_STATE permissions declared in
/// AndroidManifest.xml. Some routers/campus WiFi block multicast entirely
/// (AP client isolation, IGMP snooping disabled) - if resolution keeps
/// failing on a given network, fall back to the raw-IP option in
/// api_client.dart instead.
class HostResolver {
  static const String mdnsName = 'impactsense.local';
  static const Duration _reresolveInterval = Duration(minutes: 5);
  static const Duration _queryTimeout = Duration(seconds: 3);

  static String? _cachedIp;
  static DateTime? _lastResolvedAt;

  /// Returns a resolved IP if mDNS succeeds, otherwise the last known-good
  /// IP from a previous successful resolution, otherwise null.
  static Future<String?> resolveApiHost() async {
    final isFresh = _lastResolvedAt != null &&
        DateTime.now().difference(_lastResolvedAt!) < _reresolveInterval;
    if (_cachedIp != null && isFresh) {
      return _cachedIp;
    }

    final client = MDnsClient();
    try {
      await client.start();
      final query = client.lookup<IPAddressResourceRecord>(
        ResourceRecordQuery.addressIPv4(mdnsName),
      );
      await for (final record in query.timeout(
        _queryTimeout,
        onTimeout: (sink) => sink.close(),
      )) {
        _cachedIp = record.address.address;
        _lastResolvedAt = DateTime.now();
        break;
      }
    } catch (_) {
      // Fall through and return whatever was cached, if anything.
    } finally {
      client.stop();
    }

    return _cachedIp;
  }
}
