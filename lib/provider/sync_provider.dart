// desktop/lib/provider/sync_provider.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_worker.dart';
import 'company_provider.dart';

final syncWorkerProvider = Provider<SyncWorker?>((ref) {
  final activeCompany = ref.watch(activeCompanyProvider);
  if (activeCompany == null) return null;

  final companyId = activeCompany['id']?.toString() ?? 'COMP-101';
  final folderPath = activeCompany['folderPath']?.toString() ?? '';
  final nodeId = 'DESKTOP-${Platform.localHostname}';

  final worker = SyncWorker(
    serverHost: 'localhost:8000',
    companyId: companyId,
    folderPath: folderPath,
    nodeId: nodeId,
  );

  worker.connectWebSocket();

  ref.onDispose(() {
    worker.dispose();
  });

  return worker;
});