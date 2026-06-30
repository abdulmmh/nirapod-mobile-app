import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';

class AuditsScreen extends StatelessWidget {
  const AuditsScreen({Key? key}) : super(key: key);

  String _formatAmount(double? amt) {
    if (amt == null || amt == 0.0) return '৳ 0';
    return NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 0).format(amt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final portalProv = Provider.of<PortalProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Audits & Queries')),
      body: portalProv.audits.isEmpty
          ? const Center(child: Text('No active audit investigations found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: portalProv.audits.length,
              itemBuilder: (context, index) {
                final audit = portalProv.audits[index];
                Color statusColor;
                switch (audit.status.toLowerCase()) {
                  case 'closed':
                    statusColor = AppColors.success;
                    break;
                  case 'initiated':
                    statusColor = AppColors.info;
                    break;
                  case 'demand issued':
                    statusColor = AppColors.error;
                    break;
                  default:
                    statusColor = AppColors.warning;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Audit Year: ${audit.year}',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                audit.status,
                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (audit.description != null) ...[
                          Text(
                            'Comments / Findings:',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            audit.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                          ),
                        ],
                        if (audit.demandAmount != null && audit.demandAmount! > 0) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Outstanding Fine / Demand:',
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _formatAmount(audit.demandAmount),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
