import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../services/storage_service.dart';
import '../../common/app_dialog_frame.dart';

class SetDirectoryDialog extends StatefulWidget {
  final String? initialPath;

  const SetDirectoryDialog({super.key, this.initialPath});

  @override
  State<SetDirectoryDialog> createState() => _SetDirectoryDialogState();
}

class _SetDirectoryDialogState extends State<SetDirectoryDialog> {
  late final TextEditingController _pathController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController(text: widget.initialPath ?? '');
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _pickDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Dhandas Data Storage Directory',
      initialDirectory: _pathController.text.isNotEmpty ? _pathController.text : null,
    );

    if (result != null) {
      setState(() {
        _pathController.text = result;
        _errorMessage = null;
      });
    }
  }

  Future<void> _confirmDirectory() async {
    final selectedPath = _pathController.text.trim();
    if (selectedPath.isEmpty) {
      setState(() => _errorMessage = 'Please select or type a directory path.');
      return;
    }

    try {
      final dir = Directory(selectedPath);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      await StorageService.saveDirectory(selectedPath);
      if (mounted) {
        Navigator.of(context).pop(selectedPath);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to access directory: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: 'Set Data Directory',
      subtitle: 'Choose where your company databases will be saved and persisted',
      icon: Icons.folder_rounded,
      iconColor: AppColors.surface,
      iconBgColor: AppColors.folderAmber,
      maxWidth: 620,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Database Storage Folder',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _pathController,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: r'C:\Dhandas\Data',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.folder_open_rounded,
                      color: AppColors.folderAmber,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: AppColors.cardBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border, width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.folderAmber, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _pickDirectory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.folderAmber,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.drive_file_move_rounded, color: AppColors.surface, size: 18),
                label: const Text(
                  'Browse',
                  style: TextStyle(color: AppColors.surface, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warningBorder),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dhandas will automatically save this path and remember it on all future app startups. Companies created will be written as secure JSON databases in this folder.',
                    style: TextStyle(fontSize: 12, color: AppColors.warningText, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.borderMedium),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _confirmDirectory,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'Save Directory',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.surface),
          ),
        ),
      ],
    );
  }
}