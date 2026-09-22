// desktop/lib/services/sync_worker.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../database/app_database.dart';

class HlcManager {
  int _millis = 0;
  int _counter = 0;
  final String nodeId;

  HlcManager(this.nodeId);

  String generateNext() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now > _millis) {
      _millis = now;
      _counter = 0;
    } else {
      _counter++;
    }
    return '$_millis:$_counter:$nodeId';
  }

  bool isNewer(String incomingHlc, String localHlc) {
    final incParts = incomingHlc.split(':');
    final locParts = localHlc.split(':');
    if (incParts.length < 3 || locParts.length < 3) return true;

    final incMillis = int.tryParse(incParts[0]) ?? 0;
    final locMillis = int.tryParse(locParts[0]) ?? 0;
    if (incMillis != locMillis) return incMillis > locMillis;

    final incCounter = int.tryParse(incParts[1]) ?? 0;
    final locCounter = int.tryParse(locParts[1]) ?? 0;
    if (incCounter != locCounter) return incCounter > locCounter;

    return incParts[2].compareTo(locParts[2]) > 0;
  }
}

class SyncWorker {
  WebSocketChannel? _channel;
  final String serverHost;
  final String companyId;
  final String folderPath;
  final String nodeId;
  late final HlcManager _hlc;

  // ValueNotifier allows UI widgets (TopBar) to rebuild automatically
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);

  // Callback triggered when a remote mutation arrives so the list screen can reload
  VoidCallback? onRemoteMutationReceived;

  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  final List<Map<String, dynamic>> _offlineMutationQueue = [];

  SyncWorker({
    this.serverHost = 'localhost:8000',
    required this.companyId,
    required this.folderPath,
    required this.nodeId,
  }) {
    _hlc = HlcManager(nodeId);
  }

  void connectWebSocket() {
    if (_isConnecting || isConnected.value) return;
    _isConnecting = true;

    try {
      final uri = Uri.parse('ws://$serverHost/ws/company/$companyId');
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (message) async {
          final data = jsonDecode(message) as Map<String, dynamic>;

          // Handle server connection confirmation
          if (data['type'] == 'CONNECTED') {
            isConnected.value = true;
            _isConnecting = false;
            _reconnectAttempts = 0;
            _flushOfflineQueue();
            return;
          }

          if (data.containsKey('hlc')) {
            await _handleIncomingRemoteMutation(data);
            onRemoteMutationReceived?.call();
          }
        },
        onDone: () => _handleDisconnection('Server closed socket'),
        onError: (err) => _handleDisconnection('WebSocket error: $err'),
        cancelOnError: true,
      );
    } catch (e) {
      _handleDisconnection('Connection initialization failed: $e');
    }
  }

  void _handleDisconnection(String reason) {
    isConnected.value = false;
    _isConnecting = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;
    _reconnectAttempts++;
    final delay = (1 << _reconnectAttempts).clamp(2, 30);

    _reconnectTimer = Timer(Duration(seconds: delay), () {
      connectWebSocket();
    });
  }

  Future<void> pushLocalMutation(AppDatabase db, Map<String, dynamic> voucherData) async {
    final hlcStamp = _hlc.generateNext();
    voucherData['hlc'] = hlcStamp;
    voucherData['nodeId'] = nodeId;

    if (isConnected.value && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(voucherData));
      } catch (_) {
        _offlineMutationQueue.add(voucherData);
        _handleDisconnection('Failed write to socket');
      }
    } else {
      _offlineMutationQueue.add(voucherData);
    }
  }

  void _flushOfflineQueue() {
    if (_offlineMutationQueue.isEmpty || !isConnected.value || _channel == null) return;
    final queued = List<Map<String, dynamic>>.from(_offlineMutationQueue);
    _offlineMutationQueue.clear();

    for (final item in queued) {
      try {
        _channel!.sink.add(jsonEncode(item));
      } catch (_) {
        _offlineMutationQueue.add(item);
        break;
      }
    }
  }

  Future<void> _handleIncomingRemoteMutation(Map<String, dynamic> remotePayload) async {
    final db = AppDatabase.forCompany(folderPath);
    try {
      final id = remotePayload['id'].toString();
      final remoteHlc = remotePayload['hlc'].toString();

      final existing = await (db.select(db.vouchersTable)..where((t) => t.id.equals(id))).getSingleOrNull();

      if (existing == null || _hlc.isNewer(remoteHlc, existing.hlcTimestamp)) {
        await db.into(db.vouchersTable).insertOnConflictUpdate(
          VouchersTableCompanion(
            id: Value(id),
            hlcTimestamp: Value(remoteHlc),
            originNodeId: Value(remotePayload['nodeId'].toString()),
            voucherNumber: Value(remotePayload['voucherNumber'].toString()),
            voucherType: Value(remotePayload['voucherType'].toString()),
            date: Value(remotePayload['date'].toString()),
            series: Value(remotePayload['series']?.toString() ?? 'Main'),
            partyName: Value(remotePayload['party']?.toString() ?? ''),
            grandTotal: Value(double.tryParse(remotePayload['grandTotal'].toString()) ?? 0.0),
            subTotal: Value(double.tryParse(remotePayload['subTotal'].toString()) ?? 0.0),
            totalTax: Value(double.tryParse(remotePayload['totalTax'].toString()) ?? 0.0),
            payloadJson: Value(jsonEncode(remotePayload)),
            isSynced: const Value(true),
          ),
        );
      }
    } finally {
      await db.close();
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    isConnected.dispose();
  }
}