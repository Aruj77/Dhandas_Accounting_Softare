import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../constants/app_colors.dart';

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
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: Container(
          width: 620,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 40,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 22, 20, 22),
                  decoration: const BoxDecoration(
                    color: AppColors.cardBg,
                    border: Border(
                      bottom: BorderSide(color: AppColors.border, width: 1.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.folderGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.folderShadow,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.folder_rounded, color: AppColors.surface, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set Data Directory',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Choose where your company databases will be saved and persisted',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textSecondary,
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),

                // BODY
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
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
                                hintText: 'C:\\Dhandas\\Data',
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: AppColors.borderFocus,
                                    width: 1.2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: AppColors.folderAmber,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _pickDirectory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.folderAmber,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.drive_file_move_rounded, color: AppColors.surface, size: 18),
                            label: const Text(
                              'Browse',
                              style: TextStyle(
                                color: AppColors.surface,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.warningText,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // FOOTER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  decoration: const BoxDecoration(
                    color: AppColors.cardBg,
                    border: Border(
                      top: BorderSide(color: AppColors.border, width: 1.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
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
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}