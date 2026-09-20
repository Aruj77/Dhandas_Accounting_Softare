import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/common/app_confirm_dialog.dart';

class ExportDialogUtils {
  static void openFile(String filePath) {
    if (Platform.isWindows) {
      Process.run('cmd', ['/c', 'start', '', filePath]);
    } else if (Platform.isMacOS) {
      Process.run('open', [filePath]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [filePath]);
    }
  }
  static Future<bool> confirmOverwrite(BuildContext context, String filePath) async {
    if (!await File(filePath).exists()) return true;

    final fileName = filePath.split(Platform.pathSeparator).last;
return AppConfirmDialog.show(
      context: context,
      title: 'File Already Exists',
      message: 'A file named "$fileName" already exists in this folder.\n\nDo you want to overwrite it?',
      confirmLabel: 'Overwrite',
      type: ConfirmDialogType.warning,
    );
  }
  static void showSuccessDialog(BuildContext context, String filePath, String fileType) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
            SizedBox(width: 8),
            Text('Export Successful', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$fileType saved successfully:', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: SelectableText(
                filePath,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Do you want to open this file now?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Dismiss')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              openFile(filePath);
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.white),
            label: const Text('Open File', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}