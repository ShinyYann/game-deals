import 'package:flutter/material.dart';
import '../models/app_theme.dart';

class TrophyPage extends StatefulWidget {
  const TrophyPage({super.key});

  @override
  State<TrophyPage> createState() => _TrophyPageState();
}

class _TrophyPageState extends State<TrophyPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '我的奖杯',
                      style: TextStyle(
                        color: AppTheme.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'PSN · Steam · 全平台统一',
                      style: TextStyle(color: AppTheme.text2, fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Center(
                    child: Text('🔍', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 3D Trophy shelf placeholder
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accent1.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Text('🏆', style: TextStyle(fontSize: 48)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '3D 奖杯墙',
                    style: TextStyle(
                      color: AppTheme.accent1,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'PSN 和 Steam 成就将在这里\n以 3D 陈列柜形式展示',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.text2, fontSize: 13, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accent1.withOpacity(0.15),
                          AppTheme.accent2.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '⏳ 即将上线',
                      style: TextStyle(color: AppTheme.accent1, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
