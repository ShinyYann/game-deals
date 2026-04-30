import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _effectsEnabled = true;
  bool _onlyWifiImage = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '设置',
              style: TextStyle(
                color: AppTheme.text,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            // Account
            _sectionHeader('👤 账户'),
            const SizedBox(height: 8),
            _buildCard([
              _settingItem('PSN ID', '尚未设置', Icons.edit, AppTheme.accent1, () {}),
              _divider(),
              _settingItem('Steam ID', '尚未绑定', Icons.add, AppTheme.accent2, () {}),
              _divider(),
              _settingItem('Switch FC', '尚未绑定', Icons.add, AppTheme.accent3, () {}),
            ]),
            const SizedBox(height: 20),
            // Display
            _sectionHeader('🎨 外观'),
            const SizedBox(height: 8),
            _buildCard([
              _toggleItem('粒子特效', _effectsEnabled, (val) {
                setState(() => _effectsEnabled = val);
              }),
              _divider(),
              _toggleItem('仅 Wi-Fi 加载图片', _onlyWifiImage, (val) {
                setState(() => _onlyWifiImage = val);
              }),
            ]),
            const SizedBox(height: 20),
            // Data
            _sectionHeader('📦 数据'),
            const SizedBox(height: 8),
            _buildCard([
              _actionItem('手动更新数据', Icons.refresh, AppTheme.accent2, () {}),
              _divider(),
              _actionItem('清除本地缓存', Icons.delete_outline, AppTheme.accent3, () {}),
            ]),
            const SizedBox(height: 20),
            // About
            _sectionHeader('ℹ️ 关于'),
            const SizedBox(height: 8),
            _buildCard([
              _infoItem('版本', '1.0.0'),
              _divider(),
              _infoItem('数据源', 'PSN · Steam · Switch'),
              _divider(),
              _infoItem('更新渠道', 'Gitee Release'),
            ]),
            const SizedBox(height: 32),
            // Footer
            Center(
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppTheme.accent1, AppTheme.accent2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Text('🏆', style: TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'TrophyRoom · 奖杯屋',
                    style: TextStyle(
                      color: AppTheme.text2,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v1.0.0 · Made with 🔥 by King 👑',
                    style: TextStyle(
                      color: AppTheme.text2.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.text2,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(children: items),
    );
  }

  Widget _settingItem(String label, String value, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.text2,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppTheme.text2, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _toggleItem(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accent1,
            activeTrackColor: AppTheme.accent1.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _actionItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppTheme.text2, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.text2,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Divider(
        height: 1,
        color: AppTheme.border.withOpacity(0.5),
      ),
    );
  }
}
