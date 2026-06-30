import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/custom_button.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({Key? key}) : super(key: key);

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _openNoticeDetail(BuildContext context, Notice notice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.backgroundDark
          : AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            final hasReplied = notice.status.toLowerCase() == 'replied';

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 24,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notice.title,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Issued on: ${notice.date ?? "N/A"}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? AppColors.surfaceDark
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.brightness == Brightness.dark
                              ? AppColors.borderDark
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        notice.message,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (hasReplied) ...[
                      Text(
                        'Your Clarification Response',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: Text(
                          notice.replyMessage ?? '',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Replied on: ${notice.replyDate ?? ""}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ] else ...[
                      Text(
                        'Write Clarification Response',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _replyController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Enter your response or document details here...',
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Send Clarification',
                        onPressed: () async {
                          if (_replyController.text.trim().isEmpty) return;
                          final success = await Provider.of<PortalProvider>(context, listen: false)
                              .replyNotice(notice.id, _replyController.text.trim());
                          
                          if (success && mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notice reply sent successfully!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            _replyController.clear();
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final portalProv = Provider.of<PortalProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Official Notices')),
      body: portalProv.notices.isEmpty
          ? const Center(child: Text('No official notices received.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: portalProv.notices.length,
              itemBuilder: (context, index) {
                final notice = portalProv.notices[index];
                final isUnread = notice.status.toLowerCase() == 'unread';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isUnread 
                            ? AppColors.warning.withOpacity(0.1) 
                            : AppColors.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isUnread ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined,
                        color: isUnread ? AppColors.warning : AppColors.primary,
                      ),
                    ),
                    title: Text(
                      notice.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(notice.date ?? 'N/A'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isUnread ? AppColors.warning.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              notice.status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isUnread ? AppColors.warning : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () => _openNoticeDetail(context, notice),
                  ),
                );
              },
            ),
    );
  }
}
