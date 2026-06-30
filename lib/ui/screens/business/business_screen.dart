import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';

class BusinessScreen extends StatelessWidget {
  const BusinessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final portalProv = Provider.of<PortalProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Businesses & VAT')),
      body: portalProv.businesses.isEmpty
          ? const Center(child: Text('No business structures registered.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: portalProv.businesses.length,
              itemBuilder: (context, index) {
                final biz = portalProv.businesses[index];
                Color statusColor = biz.vatStatus.toLowerCase() == 'active' 
                    ? AppColors.success 
                    : AppColors.warning;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              biz.name,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'VAT: ${biz.vatStatus}',
                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.badge_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Trade License: ${biz.tradeLicenseNo}',
                              style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                        if (biz.address != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  biz.address!,
                                  style: theme.textTheme.bodyMedium,
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
