/// 登录/注册页
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/auth_admin_service.dart';
import '../services/cookie_isolation.dart';
import 'pending_approval_page.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (user.isEmpty || pass.isEmpty) {
      setState(() => _error = '用户名和密码不能为空');
      return;
    }
    if (user.length < 2 || user.length > 20) {
      setState(() => _error = '用户名 2-20 个字符');
      return;
    }
    if (pass.length < 4) {
      setState(() => _error = '密码至少 4 位');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final result = _isRegister
        ? await AuthService.register(user, pass)
        : await AuthService.login(user, pass);

    if (!mounted) return;

    if (result.success) {
      await AuthService.saveToken(result.token!, result.username!);
      setState(() => _error = null);

      // 强制同步：先下载服务器数据，再上传本地数据
      try {
        final remote = await AuthService.syncDownload(token: result.token!);
        if (remote != null && (remote['psn_id']?.toString() ?? '').isNotEmpty) {
          await AuthService.applyRemoteData(remote);
        }
        // 把当前本地数据推上去覆盖
        await AuthService.syncUpload(token: result.token!);
      } catch (_) {}

      if (!mounted) return;

      // 检查用户审核状态（通过 /download 端点）
      final status = await AuthAdminService.getUserStatus(result.token!);
      if (!mounted) return;

      if (status == 'pending' && result.username!.toLowerCase() != 'shinyyann') {
        // 待审核用户 → 跳转审核等待页（注册和登录都检查）
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PendingApprovalPage(
              username: result.username!,
              token: result.token!,
            ),
          ),
        );
        return;
      } else if (status == 'rejected') {
        // 被拒绝用户 → 提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 审核未通过，请联系管理员'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() {
          _loading = false;
          _error = '审核未通过';
        });
        return;
      }

      // 正常通过 → 清空旧 cookies 进入首页
      await CookieIsolation.onUserSwitch();
      if (!mounted) return;
      widget.onLoginSuccess();
    } else {
      setState(() {
        _loading = false;
        _error = result.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 8),
                  const Text('TrophyRoom',
                    style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold,
                      color: Colors.white, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Text('与云端同步你的收藏',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  const SizedBox(height: 40),

                  // 用户名
                  _field('用户名', Icons.person, _userCtrl),
                  const SizedBox(height: 16),

                  // 密码
                  _field('密码', Icons.lock, _passCtrl, obscure: true),
                  const SizedBox(height: 8),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ),

                  const SizedBox(height: 8),

                  // 提交按钮
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF66C0F4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                          : Text(_isRegister ? '注册并登录' : '登录',
                              style: const TextStyle(fontSize: 16)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 注册/登录 切换
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                            _isRegister = !_isRegister;
                            _error = null;
                          }),
                    child: Text(
                      _isRegister ? '已有账号？去登录' : '没有账号？注册一个',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                  ),

                  // 跳过按钮
                  TextButton(
                    onPressed: _loading ? null : () {
                      // 用空 token 登录（本地模式）
                      AuthService.saveToken('', '').then((_) {
                        widget.onLoginSuccess();
                      });
                    },
                    child: Text('跳过登录，本地使用',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, IconData icon, TextEditingController ctrl,
      {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF66C0F4), width: 1),
        ),
      ),
    );
  }
}
