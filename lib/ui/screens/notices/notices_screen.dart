import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/portal_shell.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({Key? key}) : super(key: key);

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Unread', 'Responded', 'Urgent', 'Expired'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final portalProv = Provider.of<PortalProvider>(context);
    final notices = portalProv.notices;

    // KPI Card counts
    final unreadCount = notices.where((n) => n.status.toLowerCase() == 'unread').length;
    final respondedCount = notices.where((n) => n.status.toLowerCase() == 'responded' || n.status.toLowerCase() == 'replied').length;
    final urgentCount = notices.where((n) => n.priority?.toLowerCase() == 'urgent' && n.status.toLowerCase() == 'unread').length;
    final expiredCount = notices.where((n) => n.status.toLowerCase() == 'expired').length;

    // Filter list logic
    final filteredList = notices.where((n) {
      final matchesSearch = n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          n.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (n.noticeNo?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (n.noticeType?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      bool matchesKpi = true;
      if (_selectedFilter == 'Unread') {
        matchesKpi = n.status.toLowerCase() == 'unread';
      } else if (_selectedFilter == 'Responded') {
        matchesKpi = n.status.toLowerCase() == 'responded' || n.status.toLowerCase() == 'replied';
      } else if (_selectedFilter == 'Urgent') {
        matchesKpi = n.priority?.toLowerCase() == 'urgent' && n.status.toLowerCase() == 'unread';
      } else if (_selectedFilter == 'Expired') {
        matchesKpi = n.status.toLowerCase() == 'expired';
      }

      return matchesSearch && matchesKpi;
    }).toList();

    final isMobile = MediaQuery.of(context).size.width < 900;

    return PortalShell(
      breadcrumbs: const ['My Portal', 'Notices'],
      showBackButton: true,
      body: portalProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                // reload logic
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title Block
                    Row(
                      children: [
                        Text(
                          'Notices & Notifications',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$unreadCount Unread',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage all notices, alerts and notifications.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),

                    // KPI Cards Grid (Desktop horizontal row, mobile stacked)
                    isMobile
                        ? Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: StatCard(
                                      title: 'Unread',
                                      value: '$unreadCount',
                                      icon: Icons.mark_email_unread_outlined,
                                      iconColor: AppColors.primary,
                                      onTap: () => setState(() => _selectedFilter = 'Unread'),
                                      isSelected: _selectedFilter == 'Unread',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: StatCard(
                                      title: 'Responded',
                                      value: '$respondedCount',
                                      icon: Icons.reply_outlined,
                                      iconColor: AppColors.success,
                                      onTap: () => setState(() => _selectedFilter = 'Responded'),
                                      isSelected: _selectedFilter == 'Responded',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: StatCard(
                                      title: 'Urgent',
                                      value: '$urgentCount',
                                      icon: Icons.warning_amber_outlined,
                                      iconColor: AppColors.error,
                                      onTap: () => setState(() => _selectedFilter = 'Urgent'),
                                      isSelected: _selectedFilter == 'Urgent',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: StatCard(
                                      title: 'Expired',
                                      value: '$expiredCount',
                                      icon: Icons.calendar_today_outlined,
                                      iconColor: Colors.grey,
                                      onTap: () => setState(() => _selectedFilter = 'Expired'),
                                      isSelected: _selectedFilter == 'Expired',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: StatCard(
                                    title: 'Unread',
                                    value: '$unreadCount',
                                    icon: Icons.mark_email_unread_outlined,
                                    iconColor: AppColors.primary,
                                    onTap: () => setState(() => _selectedFilter = 'Unread'),
                                    isSelected: _selectedFilter == 'Unread',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: StatCard(
                                    title: 'Responded',
                                    value: '$respondedCount',
                                    icon: Icons.reply_outlined,
                                    iconColor: AppColors.success,
                                    onTap: () => setState(() => _selectedFilter = 'Responded'),
                                    isSelected: _selectedFilter == 'Responded',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: StatCard(
                                    title: 'Urgent',
                                    value: '$urgentCount',
                                    icon: Icons.warning_amber_outlined,
                                    iconColor: AppColors.error,
                                    onTap: () => setState(() => _selectedFilter = 'Urgent'),
                                    isSelected: _selectedFilter == 'Urgent',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: StatCard(
                                    title: 'Expired',
                                    value: '$expiredCount',
                                    icon: Icons.calendar_today_outlined,
                                    iconColor: Colors.grey,
                                    onTap: () => setState(() => _selectedFilter = 'Expired'),
                                    isSelected: _selectedFilter == 'Expired',
                                  ),
                                ),
                              ],
                            ),
                          ),
                    const SizedBox(height: 24),

                    // Search & Filters Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search, size: 20),
                              hintText: 'Search by notice no, subject, taxpayer, type...',
                              filled: true,
                              fillColor: isDark ? AppColors.backgroundDark : const Color(0xFFF5F5F5),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade300),
                              ),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                          ),
                          if (_selectedFilter != 'All') ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text('Filtered by: ', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600, fontSize: 13)),
                                Text(_selectedFilter, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, fontSize: 13)),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => setState(() => _selectedFilter = 'All'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.cancel_outlined, size: 14, color: Colors.red),
                                        SizedBox(width: 4),
                                        Text('Clear', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Notices List
                    filteredList.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No notices or notifications matching filters.',
                                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final notice = filteredList[index];
                              final isUnread = notice.status.toLowerCase() == 'unread';
                              final isResponded = notice.status.toLowerCase() == 'responded' || notice.status.toLowerCase() == 'replied';

                              Color badgeColor = Colors.grey;
                              if (isUnread) badgeColor = AppColors.primary;
                              if (isResponded) badgeColor = AppColors.success;

                              final priorityColor = notice.priority?.toLowerCase() == 'high' ? AppColors.error : Colors.grey;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isDark ? AppColors.borderDark : Colors.grey.shade200,
                                  ),
                                ),
                                elevation: 0,
                                color: isDark ? AppColors.surfaceDark : Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.backgroundDark
                                              : (isResponded ? Colors.grey.shade100 : Colors.blue.shade50),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isResponded ? Icons.settings_outlined : Icons.notifications_active_outlined,
                                          color: isResponded ? Colors.grey : AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Monospace NTC, Priority & Status badges
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              alignment: WrapAlignment.spaceBetween,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                Text(
                                                  notice.noticeNo ?? 'NTC-${notice.id.toRadixString(16).toUpperCase()}',
                                                  style: TextStyle(
                                                    fontFamily: 'monospace',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? AppColors.primary : AppColors.primary,
                                                  ),
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
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: priorityColor,
                                                          ),
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
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: badgeColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),

                                            // Subject / Title
                                            Text(
                                              notice.title,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 8),

                                            // Message body snippet
                                            Text(
                                              notice.message,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade700,
                                                height: 1.4,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 16),

                                            // Footer items row
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Wrap(
                                                    spacing: 12,
                                                    runSpacing: 6,
                                                    children: [
                                                      _buildMetaItem(Icons.person_outline, 'System', isDark),
                                                      _buildMetaItem(Icons.calendar_today_outlined, notice.date ?? '—', isDark),
                                                      _buildMetaItem(Icons.people_outline, notice.noticeType ?? 'Specific Taxpayer', isDark),
                                                    ],
                                                  ),
                                                ),
                                                OutlinedButton.icon(
                                                  onPressed: () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      '/notice-details',
                                                      arguments: notice.id,
                                                    );
                                                  },
                                                  icon: const Icon(Icons.visibility, size: 14),
                                                  label: const Text('View', style: TextStyle(fontSize: 12)),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: AppColors.primary,
                                                    side: const BorderSide(color: AppColors.primary),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 20),

                    // Pagination row block
                    if (filteredList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Showing 1-${filteredList.length} of ${filteredList.length}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: null,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  ),
                                  child: const Text('Prev', style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 6),
                                OutlinedButton(
                                  onPressed: null,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  ),
                                  child: const Text('Next', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textSecondaryDark.withOpacity(0.8) : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
