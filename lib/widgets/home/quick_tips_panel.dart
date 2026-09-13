import 'package:flutter/material.dart';

class QuickTipsPanel extends StatelessWidget {
  const QuickTipsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EDF7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08092B60),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFFE09B16),
                    size: 21,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Quick Tips',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF101C3A),
                    ),
                  ),
                ],
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {},
                  child: Row(
                    children: const [
                      Text(
                        'View All Tips',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F62FE),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFF0F62FE),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildTipBullet('Create a company to start accounting'),
          const SizedBox(height: 8),
          _buildTipBullet('Keep regular backups of your data'),
          const SizedBox(height: 8),
          _buildTipBullet(
            'Set a safe data directory (preferably a different drive)',
          ),
        ],
      ),
    );
  }

  Widget _buildTipBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFF33415D),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4C5D7F),
            ),
          ),
        ),
      ],
    );
  }
}