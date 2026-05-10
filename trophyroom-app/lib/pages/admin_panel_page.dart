/// 管理员面板 — 注册审核 + 在线用户
/// 使用 auth server API（AuthAdminService）替代 Supabase
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_admin_service.dart';
import '../services/auth_service.dart';
import '../services/proxy_service.dart';
import 'browser_tab_page.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _token = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadToken();
  }

  Future<void> _loadToken() async {
    final creds = await AuthService.loadToken();
    if (mounted && creds.token != null) {
      setState(() => _token = creds.token!);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('👑 管理面板',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.purple[300],
          labelColor: Colors.purple[300],
          unselectedLabelColor: Colors.grey[500],
          tabs: const [
            Tab(text: '📋 注册审核', icon: Icon(Icons.person_search, size: 18)),
            Tab(text: '🟢 在线用户', icon: Icon(Icons.wifi_tethering, size: 18)),
            Tab(text: '🔌 代理', icon: Icon(Icons.shield, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _UserReviewTab(token: _token),
          _OnlineUsersTab(token: _token),
          _ProxyDomainsTab(token: _token),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────
// Tab 1：注册审核
// ────────────────────────────────────────────────────

class _UserReviewTab extends StatefulWidget {
  final String token;
  const _UserReviewTab({required this.token});

  @override
  State<_UserReviewTab> createState() => _UserReviewTabState();
}

class _UserReviewTabState extends State<_UserReviewTab> {
  List<Map<String, dynamic>> _pendingUsers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingUsers();
  }

  Future<void> _loadPendingUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await AuthAdminService.getPendingRequests(widget.token);
      if (!mounted) return;
      setState(() {
        _pendingUsers = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '加载失败: $e';
        _loading = false;
      });
    }
  }

  Future<void> _approve(int userId, String username) async {
    final ok = await AuthAdminService.approveUser(widget.token, userId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ $username 已通过审核')),
      );
      _loadPendingUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ 操作失败，请稍后重试'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _reject(int userId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title:
            const Text('确认拒绝？', style: TextStyle(color: Colors.white)),
        content: Text('将拒绝用户 $username 的注册申请',
            style: TextStyle(color: Colors.grey[300])),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确认拒绝'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await AuthAdminService.rejectUser(widget.token, userId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $username 已被拒绝')),
      );
      _loadPendingUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('操作失败，请稍后重试'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.purple),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重试'),
              onPressed: _loadPendingUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[700],
              ),
            ),
          ],
        ),
      );
    }

    if (_pendingUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64,
                color: Colors.green[400]),
            const SizedBox(height: 12),
            Text('🎉 暂无待审核用户',
                style:
                    TextStyle(fontSize: 16, color: Colors.grey[400])),
            const SizedBox(height: 6),
            Text('所有用户都已处理',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('刷新'),
              onPressed: _loadPendingUsers,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingUsers,
      color: Colors.purple,
      backgroundColor: const Color(0xFF1A1A2E),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingUsers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final user = _pendingUsers[i];
          final id = user['id'] as int;
          final username = user['username']?.toString() ?? '?';
          final email = user['email']?.toString() ?? '';
          final createdAt = user['created_at']?.toString() ?? '';

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.purple[800],
                        child: Text(
                          username.isNotEmpty
                              ? username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(username,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            if (email.isNotEmpty)
                              Text(email,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[500])),
                            if (createdAt.isNotEmpty)
                              Text(_formatDate(createdAt),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 70,
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () => _approve(id, username),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                              ),
                              child: const Text('通过',
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 70,
                            height: 32,
                            child: OutlinedButton(
                              onPressed: () => _reject(id, username),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(
                                    color: Colors.redAccent),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                              ),
                              child: const Text('拒绝',
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ────────────────────────────────────────────────────
// Tab 2：在线用户
// ────────────────────────────────────────────────────

class _OnlineUsersTab extends StatefulWidget {
  final String token;
  const _OnlineUsersTab({required this.token});

  @override
  State<_OnlineUsersTab> createState() => _OnlineUsersTabState();
}

class _OnlineUsersTabState extends State<_OnlineUsersTab> {
  List<Map<String, dynamic>> _onlineUsers = [];
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadOnlineUsers();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadOnlineUsers();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOnlineUsers() async {
    try {
      final users = await AuthAdminService.getOnlineUsers(widget.token);
      if (!mounted) return;
      setState(() {
        _onlineUsers = users;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '加载失败: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重试'),
              onPressed: _loadOnlineUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[700],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.15),
                Colors.green.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_tethering,
                  color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                '在线用户: ${_onlineUsers.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.sync, size: 16, color: Colors.grey[600]),
              Text(' 自动刷新',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),

        if (_onlineUsers.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_off,
                      size: 64, color: Colors.grey[700]),
                  const SizedBox(height: 12),
                  Text('暂无在线用户',
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey[500])),
                  const SizedBox(height: 6),
                  Text('没有用户在 5 分钟内活跃',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[700])),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOnlineUsers,
              color: Colors.green,
              backgroundColor: const Color(0xFF1A1A2E),
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _onlineUsers.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 6),
                itemBuilder: (ctx, i) {
                  final user = _onlineUsers[i];
                  final username =
                      user['username']?.toString() ?? '?';
                  final secondsAgo = user['seconds_ago'] as int? ?? 0;
                  final userAgent = user['user_agent']?.toString() ?? '';
                  final recent = secondsAgo < 30;

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: recent
                            ? Colors.green.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.1),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: recent
                            ? Colors.green[700]
                            : Colors.grey[700],
                        child: Text(
                          username.isNotEmpty
                              ? username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      title: Text(username,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 15)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: recent
                                      ? Colors.green
                                      : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AuthAdminService.formatTimeAgo(secondsAgo),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: recent
                                      ? Colors.green[300]
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          if (userAgent.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                userAgent,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                      trailing: recent
                          ? const Icon(Icons.circle,
                              color: Colors.green, size: 10)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────
// Tab 3：代理域名管理
// ────────────────────────────────────────────────────

class _ProxyDomainsTab extends StatefulWidget {
  final String token;
  const _ProxyDomainsTab({required this.token});

  @override
  State<_ProxyDomainsTab> createState() => _ProxyDomainsTabState();
}

class _ProxyDomainsTabState extends State<_ProxyDomainsTab> {
  List<String> _domains = [];
  bool _loading = true;
  final TextEditingController _domainCtrl = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDomains();
  }

  @override
  void dispose() {
    _domainCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDomains() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final domains = await ProxyService.fetchDomains(force: true);
    if (mounted) {
      setState(() {
        _domains = domains;
        _loading = false;
      });
      // 同步到 BrowserTabPage 静态列表（浏览器 Tab 即时生效）
      BrowserTabPage.proxyDomains = domains;
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('proxy_domains_cache');
      if (cached != null) {
        try {
          final list = json.decode(cached) as List;
          final domainsList = list.map((e) => e.toString()).toList();
          // BrowserTabPage 的静态 _BrowserTabWebViewState 会从 SharedPreferences 读取
          // 所以我们只需要确保 SharedPreferences 已更新
          // 而 fetchDomains 内部已经更新了 SharedPreferences
        } catch (_) {}
      }
    }
  }

  Future<void> _addDomain() async {
    final domain = _domainCtrl.text.trim();
    if (domain.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await ProxyService.addDomain(widget.token, domain);
    if (mounted) {
      if (ok) {
        _domainCtrl.clear();
        await _loadDomains();
      } else {
        setState(() {
          _error = '添加失败，请检查权限';
          _loading = false;
        });
      }
    }
  }

  Future<void> _removeDomain(String domain) async {
    setState(() => _loading = true);
    final ok = await ProxyService.removeDomain(widget.token, domain);
    if (mounted) {
      if (ok) {
        await _loadDomains();
      } else {
        setState(() {
          _error = '删除失败';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A12),
      child: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.red[900]?.withOpacity(0.5),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ),
          // 域名列表
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.purple),
                  )
                : _domains.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 48, color: Colors.grey[600]),
                            const SizedBox(height: 12),
                            Text('暂无代理域名',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _domains.length,
                        itemBuilder: (context, index) {
                          final domain = _domains[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16213E),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.language,
                                  color: Colors.purple, size: 22),
                              title: Text(domain,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 15)),
                              trailing: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.redAccent, size: 20),
                                onPressed: () => _removeDomain(domain),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // 底部添加区域
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              border: Border(
                  top: BorderSide(color: Colors.grey[850]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _domainCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '输入域名（如 example.com）',
                      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF16213E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addDomain(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addDomain,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('添加', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
