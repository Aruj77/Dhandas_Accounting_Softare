import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_worker.dart';
import 'company_provider.dart';

final syncWorkerProvider = Provider<SyncWorker?>((ref) {
  final activeCompany = ref.watch(activeCompanyProvider);
  if (activeCompany == null) return null;

  final companyId = activeCompany.id.isNotEmpty ? activeCompany.id : 'COMP-101';
  final folderPath = activeCompany.folderPath;
  if (folderPath.isEmpty) return null;

  final worker = SyncWorker(
    serverHost: 'localhost:8000',
    companyId: companyId,
    folderPath: folderPath,
    nodeId: 'DESKTOP-${Platform.localHostname}',
  );

  worker.connectWebSocket();
  ref.onDispose(worker.dispose);

  return worker;
});