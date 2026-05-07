/// PSN 登录页面 — 改为系统浏览器方案
///
/// Sony 的 OAuth/登录流有自定义 scheme 重定向，
/// WebView 无法正确处理。改为在系统浏览器中打开，
/// 用户登录后通过 NPSSO 方式验证。
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PSNLoginPage extends StatefulWidget {
  const PSNLoginPage({super.key});

  @override
  State<PSNLoginPage> createState() => _PSNLoginPageState();
}

class _PSNLoginPageState extends State<PSNLoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('PSN 登录',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              '三步完成 PSN 登录',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 24),

            // Step 1
            _stepCard(
              step: '1',
              title: '在浏览器打开 PSN 登录',
              desc: '点击下方按钮，用系统浏览器打开索尼官方登录页',
              color: Colors.blue,
              buttonText: '打开 PSN 登录页',
              icon: Icons.open_in_browser,
              onTap: () async {
                final uri = Uri.parse('https://www.playstation.com/');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),

            const SizedBox(height: 16),

            // Step 2
            _stepCard(
              step: '2',
              title: '登录后获取 NPSSO',
              desc: '在浏览器完成登录后，返回这里，点击下方按钮获取 NPSSO 令牌',
              color: Colors.amber,
              buttonText: '获取 NPSSO',
              icon: Icons.vpn_key,
              onTap: () async {
                final uri = Uri.parse('http://8.153.97.56/api/npsso');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),

            const SizedBox(height: 16),

            // Step 3
            _stepCard(
              step: '3',
              title:  '粘贴 NPSSO 回 App',
              desc: '浏览器页面会显示你的 NPSSO 令牌，复制后关掉浏览器，在设置页粘贴即可',
              color: Colors.green,
              buttonText: '返回设置页',
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),

            const SizedBox(height: 24),

            // Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.amber[400], size: 18),
                      const SizedBox(width: 8),
                      Text('小提示',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.amber[300])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 如果 NPSSO 页面是空白，请确认浏览器已登录 PSN\n'
                    '• NPSSO 是一个长字符串，完整复制即可\n'
                    '• NPSSO 有效期为 30 天，过期后重新获取',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepCard({
    required String step,
    required String title,
    required String desc,
    required MaterialColor color,
    required String buttonText,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Step number
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(step,
                  style: TextStyle(
                      color: color[300],
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[200],
                        fontSize: 15)),
                const SizedBox(height: 4),
                Text(desc,
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(0, 36),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14),
                const SizedBox(width: 4),
                Text(buttonText, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
