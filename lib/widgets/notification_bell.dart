import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import '../screens/notifications/notification_screen.dart';

/// AppBar bell icon with unread badge + realtime shake animation.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with SingleTickerProviderStateMixin {
  final _service = NotificationService();

  int _unreadCount = 0;
  Set<String> _myBlogIds = {};
  RealtimeChannel? _channel;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end:  0.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin:  0.15, end: -0.15), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.15, end:  0.10), weight: 2),
      TweenSequenceItem(tween: Tween(begin:  0.10, end: -0.10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.10, end:  0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _init();
  }

  Future<void> _init() async {
    await _loadCount();
    _myBlogIds = await _service.fetchMyBlogIds();
    _subscribeRealtime();
  }

  Future<void> _loadCount() async {
    try {
      final notifications = await _service.fetchNotifications();
      if (mounted) {
        setState(() {
          _unreadCount = notifications.where((n) => !n.isRead).length;
        });
      }
    } catch (_) {}
  }

  void _subscribeRealtime() {
    if (_myBlogIds.isEmpty) return;

    _channel = _service.subscribeToNewComments(
      myBlogIds: _myBlogIds,
      onNew: (_) async {
        await _loadCount();
        if (mounted) _shakeCtrl.forward(from: 0);
      },
    );
  }

  Future<void> _open() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
    _loadCount(); // refresh after user may have read notifications
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    if (_channel != null) _service.unsubscribe(_channel!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) => Transform.rotate(
        angle: _shakeAnim.value,
        child: child,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: Icon(
              _unreadCount > 0
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded,
              color: _unreadCount > 0 ? cs.primary : null,
            ),
            tooltip: 'Notifications',
            onPressed: _open,
          ),
          if (_unreadCount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: IgnorePointer(
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: cs.error,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _unreadCount > 99 ? '99+' : '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
