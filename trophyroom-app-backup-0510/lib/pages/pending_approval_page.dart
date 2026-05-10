/// 待审核页面 — 注册后 status='pending' 时显示
/// 使用 auth server API（AuthAdminService）获取状态
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_admin_service.dart';
import '../services/auth_service.dart';

class PendingApprovalPage extends StatefulWidget {
  final String username;
  final String token;

  const PendingApprovalPage({
    super.key,
    required this.username,
    required this.token,
  });

  @override
  State<PendingApprovalPage> createState() => _PendingApprovalPageState();
}

class _PendingApprovalPageState extends State<PendingApprovalPage> {
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    // 每 15 秒自动检查审核状态
    _checkTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkStatus();
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        widget.username.toLowerCase() == 'shinyyann';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图标
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.hourglass_bottom,
                  size: 48,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 24),

              // 标题
              const Text(
                '审核中',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // 说明
              Text(
                isAdmin
                    ? '管理员账号无需审核，即将进入 App…'
                    : '你的账号正在等待管理员审核\n审核通过后即可使用全部功能',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 8),

              // 管理员提示
              if (!isAdmin)
                Text(
                  '请耐心等待，或联系管理员加速审核',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),

              const SizedBox(height: 32),

              // 加载动画
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.amber,
                ),
              ),

              const SizedBox(height: 8),
              Text(
                '状态查询中…',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 32),

              // 自动刷新按钮
              TextButton.icon(
                onPressed: () {
                  // 手动检查状态
                  _checkStatus();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('检查审核状态'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.amber[300],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkStatus() async {
    final status = await AuthAdminService.getUserStatus(widget.token);
    if (!mounted) return;

    if (status == 'active') {
      // 已通过审核，回到主页
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 审核已通过，欢迎使用！')),
      );
      // 先清除 pending, 然后导航到主页
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } else if (status == 'rejected') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ 审核未通过，请联系管理员'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else if (status == null) {
      // null 可能表示网络问题或 token 已过期
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('无法连接审核服务器，稍后将自动重试'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    // pending 则继续等待，不提示
  }
}
