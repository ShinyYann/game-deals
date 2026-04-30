import 'package:flutter/material.dart';
import '../models/app_theme.dart';

class DealsPage extends StatefulWidget {
  const DealsPage({super.key});

  @override
  State<DealsPage> createState() => _DealsPageState();
}

class _DealsPageState extends State<DealsPage> {
  int _selectedPlatform = 0;
  final List<String> _platforms = ['PSN', 'Steam', 'Switch', 'Top5'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '游戏折扣',
              style: TextStyle(
                color: AppTheme.text,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Platform tabs
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _platforms.length,
              itemBuilder: (context, index) {
                final isActive = _selectedPlatform == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPlatform = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.card : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive
                            ? AppTheme.accent2.withOpacity(0.3)
                            : AppTheme.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _platforms[index],
                        style: TextStyle(
                          color: isActive ? AppTheme.accent2 : AppTheme.text2,
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📡', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text(
                    '数据加载中...',
                    style: TextStyle(color: AppTheme.text2, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accent2.withOpacity(0.5),
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
