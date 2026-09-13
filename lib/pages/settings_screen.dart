import 'package:flutter/material.dart';
import '../services/loading_service.dart';

class SettingsScreen extends StatefulWidget {
  final String? currentDirectory;
  final VoidCallback? onChangeDirectory;

  const SettingsScreen({
    super.key,
    this.currentDirectory,
    this.onChangeDirectory,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentVersion = '1.0.0';
  String? _lastCheckedTime = 'Never';
  bool _isUpToDate = true;
  String _selectedChannel = 'Stable';

  Future<void> _checkForUpdates() async {
    await LoadingService.wrap(() async {
      // Simulate remote update check latency
      await Future.delayed(const Duration(milliseconds: 900));

      if (mounted) {
        final now = DateTime.now();
        final formattedTime =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

        setState(() {
          _lastCheckedTime = 'Today at $formattedTime';
          _isUpToDate = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Dhandas is up to date! (v1.0.0 is the latest build)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Color(0xFF11A25B),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }, message: 'Checking for updates...');
  }

  @override
  Widget build(BuildContext context) {
    final hasDir =
        widget.currentDirectory != null && widget.currentDirectory!.isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          const Text(
            'Settings & Preferences',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F1B38),
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage storage locations, application updates, and runtime configurations.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF637392),
            ),
          ),
          const SizedBox(height: 28),

          // CHECK FOR UPDATES CARD
          _buildSettingsCard(
            icon: Icons.system_update_rounded,
            badgeColor: const Color(0xFF11A25B),
            title: 'Application Updates',
            subtitle:
                'Check for software upgrades, bug fixes, and feature releases',
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFD),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2EAF4)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F8EE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF11A25B),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Dhandas Desktop v$_currentVersion',
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF101B39),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Latest',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Last verified: $_lastCheckedTime',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7B9B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _checkForUpdates,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F62FE),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Check for Updates',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFE5EDF7), height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Release Channel',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF101C38),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Receive verified production releases or early previews',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF6B7B9B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD6E3F2)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedChannel,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Color(0xFF677793),
                            ),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF101C38),
                            ),
                            items: ['Stable', 'Beta (Preview)']
                                .map(
                                  (channel) => DropdownMenuItem(
                                    value: channel,
                                    child: Text(channel),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedChannel = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // STORAGE CONFIGURATION CARD
          _buildSettingsCard(
            icon: Icons.folder_shared_rounded,
            badgeColor: const Color(0xFF0F62FE),
            title: 'Storage & Database Location',
            subtitle:
                'Configure the root path where all organization data is saved',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2EAF4)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.dns_rounded,
                    color: Color(0xFF0F62FE),
                    size: 20,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Database Directory',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7B9B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasDir
                              ? widget.currentDirectory!
                              : 'No directory configured',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: hasDir
                                ? const Color(0xFF101B39)
                                : const Color(0xFFEE4343),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: widget.onChangeDirectory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F62FE),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(
                      Icons.edit_location_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Change',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // APPLICATION INFORMATION
          _buildSettingsCard(
            icon: Icons.info_outline_rounded,
            badgeColor: const Color(0xFF7034E6),
            title: 'Application Information',
            subtitle: 'Dhandas build details, licensing, and dependencies',
            child: Column(
              children: [
                _buildInfoRow('Product Name', 'Dhandas Desktop Accounting'),
                const Divider(color: Color(0xFFEBF0F7), height: 16),
                _buildInfoRow('Current Version', '$_currentVersion (Release)'),
                const Divider(color: Color(0xFFEBF0F7), height: 16),
                _buildInfoRow(
                  'Engine Architecture',
                  'Windows x64 Native / Flutter Desktop',
                ),
                const Divider(color: Color(0xFFEBF0F7), height: 16),
                _buildInfoRow(
                  'Storage Driver',
                  'Local File JSON / Sequential FIN-Index',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required Color badgeColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EDF7), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06092B60),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF101B3A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7B9B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF637392),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF101B3A),
          ),
        ),
      ],
    );
  }
}