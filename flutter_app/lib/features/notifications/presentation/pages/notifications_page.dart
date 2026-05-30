import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/supabase_client.dart';

final notificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user   = client.auth.currentUser;
  if (user == null) return [];
  final svc = ref.watch(supabaseServiceProvider);
  return svc.fetchNotifications(user.id);
});

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  Color _typeColor(String type) => switch (type) {
    'order'   => AppTheme.colorBlue,
    'escrow'  => AppTheme.colorPurple,
    'bid'     => AppTheme.colorRed,
    'offer'   => AppTheme.colorBlue,
    'message' => AppTheme.colorGreen,
    'refund'  => AppTheme.goldPrimary,
    _         => AppTheme.textMuted,
  };

  String _typeIcon(String type) => switch (type) {
    'order'   => '📦',
    'escrow'  => '🛡️',
    'bid'     => '🔨',
    'offer'   => '💬',
    'message' => '✉️',
    'refund'  => '↩️',
    _         => '🔔',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOTIFICATIONS'),
        actions: [
          TextButton(
            onPressed: () async {
              final client = ref.read(supabaseClientProvider);
              final svc    = ref.read(supabaseServiceProvider);
              await svc.markNotificationsRead(client.auth.currentUser!.id);
              ref.invalidate(notificationsProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notifsAsync.when(
        data: (notifs) => notifs.isEmpty
            ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('🔔', style: TextStyle(fontSize: 48)),
                SizedBox(height: 16),
                Text('No notifications yet', style: TextStyle(fontSize: 16, color: AppTheme.textMuted)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifs.length,
                itemBuilder: (ctx, i) {
                  final n      = notifs[i];
                  final type   = n['type'] as String? ?? 'system';
                  final isRead = n['is_read'] as bool? ?? false;
                  final color  = _typeColor(type);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isRead ? AppTheme.borderColor : color.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text(_typeIcon(type), style: const TextStyle(fontSize: 18))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n['title'] ?? '', style: TextStyle(fontWeight: isRead ? FontWeight.w500 : FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(n['body'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ])),
                      if (!isRead) Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    ]),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
