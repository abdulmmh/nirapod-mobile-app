import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/portal_shell.dart';

class NoticeDetailScreen extends StatefulWidget {
  const NoticeDetailScreen({Key? key}) : super(key: key);

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  final _responseController = TextEditingController();
  bool _showReplyEditor = false;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final portalProv = Provider.of<PortalProvider>(context);

    // Get notice ID from route settings arguments
    final int? noticeId = ModalRoute.of(context)?.settings.arguments as int?;

    if (noticeId == null) {
      return const PortalShell(
        breadcrumbs: ['My Portal', 'Notices', 'Details'],
        showBackButton: true,
        body: Center(
          child: Card(
            margin: EdgeInsets.all(20),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Error: No Notice Selected', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      );
    }

    // Find notice from provider state list
    final notice = portalProv.notices.firstWhere(
      (n) => n.id == noticeId,
      orElse: () => Notice(
        id: 0,
        title: 'Unknown Notice',
        message: 'No record details found.',
        status: 'Unknown',
      ),
    );

    if (notice.id == 0) {
      return const PortalShell(
        breadcrumbs: ['My Portal', 'Notices', 'Details'],
        showBackButton: true,
        body: Center(
          child: Card(
            margin: EdgeInsets.all(20),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Error: Notice Record Not Found', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      );
    }

    final isUnread = notice.status.toLowerCase() == 'unread';
    final isResponded = notice.status.toLowerCase() == 'responded' || notice.status.toLowerCase() == 'replied';

    Color badgeColor = Colors.grey;
    if (isUnread) badgeColor = AppColors.primary;
    if (isResponded) badgeColor = AppColors.success;

    final priorityColor = notice.priority?.toLowerCase() == 'high' ? AppColors.error : Colors.grey;

    return PortalShell(
      breadcrumbs: const ['My Portal', 'Notices', 'Details'],
      showBackButton: true,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sub-header Breadcrumb and Back to List Action Button Row
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notice Details',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Full notice information.',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 14),
                  label: const Text('Back to List'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Premium Header Notice Info Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
              ),
              color: isDark ? AppColors.surfaceDark : Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.backgroundDark : Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.notifications_active, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // NTC, Priority & Status
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    notice.noticeNo ?? 'NTC-${notice.id.toRadixString(16).toUpperCase()}',
                                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    notice.noticeType ?? 'Reminder',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (notice.priority != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: priorityColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        notice.priority!,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor),
                                      ),
                                    ),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      notice.status,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Notice Title
                          Text(
                            notice.title,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),

                          // Meta Pills
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              _buildMetaPill(Icons.person_outline, 'System', isDark),
                              _buildMetaPill(Icons.calendar_today_outlined, notice.date ?? '—', isDark),
                              _buildMetaPill(Icons.badge_outlined, 'Tasrif Zaman (TIN-000000005)', isDark),
                              _buildMetaPill(Icons.people_outline, 'Specific Taxpayer', isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Message Body Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
              ),
              color: isDark ? AppColors.surfaceDark : Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mail_outline, color: Colors.teal.shade700, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Message',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      notice.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14.5,
                        height: 1.5,
                      ),
                    ),
                    if (!isResponded && !_showReplyEditor) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showReplyEditor = true;
                          });
                        },
                        icon: const Icon(Icons.reply, size: 16),
                        label: const Text('Reply to Notice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Response editor panel OR replied history card
            if (isResponded)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.success.withOpacity(0.3)),
                ),
                color: isDark ? AppColors.surfaceDark : AppColors.success.withOpacity(0.04),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.reply_all_outlined, color: AppColors.success, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Your Response',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.success),
                              ),
                            ],
                          ),
                          if (notice.replyDate != null)
                            Text(
                              'Replied on: ${notice.replyDate}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        notice.replyMessage ?? 'Response details submitted successfully.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (!isResponded && _showReplyEditor)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade300),
                ),
                color: isDark ? AppColors.surfaceDark : Colors.white,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.reply, color: Colors.teal.shade700, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Your Response',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      TextField(
                        controller: _responseController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: 'Enter your response here...',
                          filled: true,
                          fillColor: isDark ? AppColors.backgroundDark : const Color(0xFFF9F9F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showReplyEditor = false;
                                _responseController.clear();
                              });
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final text = _responseController.text.trim();
                              if (text.isEmpty) return;

                              final success = await portalProv.replyNotice(notice.id, text);
                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Response submitted successfully!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                                setState(() {
                                  _showReplyEditor = false;
                                });
                              }
                            },
                            icon: const Icon(Icons.send, size: 14),
                            label: const Text('Send Response'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaPill(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
