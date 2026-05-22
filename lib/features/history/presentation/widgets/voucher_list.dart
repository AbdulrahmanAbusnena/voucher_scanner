import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:odfinance/core/constants/carrier_configs.dart';
import 'package:odfinance/core/services/service_providers.dart';
import 'package:odfinance/features/history/domain/models/voucher.dart';
import 'package:odfinance/features/history/presentation/providers/history_provider.dart';

class VoucherListCard extends ConsumerWidget {
  final Voucher voucher;
  const VoucherListCard({required this.voucher});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedData = DateFormat(
      'yyyy-MM-dd • hh:mm a',
    ).format(voucher.scannedAt);
    final String fullUssdCode = CarrierConfigs.generateCode(
      voucher.carrier,
      voucher.serialCode,
    );

    final isLibyana = voucher.carrier == CarrierType.libyana;
    final carrierColor = isLibyana
        ? Colors.blue.shade700
        : (voucher.carrier == CarrierType.almadar
              ? Colors.orange.shade700
              : Colors.teal.shade700);
    final carrierName = isLibyana
        ? "ليبيانا"
        : (voucher.carrier == CarrierType.almadar ? "المدار" : "LTT");

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              // Brand Line Indicator
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: carrierColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Voucher Details Text Blocks
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          carrierName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: carrierColor,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (voucher.isUsed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "تم الشحن",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      voucher.serialCode,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        decoration: voucher.isUsed
                            ? TextDecoration.lineThrough
                            : null,
                        color: voucher.isUsed ? Colors.black38 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedData,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),

              // Action Utility Center
              Column(
                children: [
                  ElevatedButton(
                    onPressed: voucher.isUsed
                        ? null
                        : () async {
                            final success = await ref
                                .read(dialerServiceProvider)
                                .launchUssd(fullUssdCode);
                            if (success && context.mounted) {
                              ref
                                  .read(historyProvider.notifier)
                                  .toggleVoucherStatus(voucher.id);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[600],
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[200],
                      disabledForegroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      "تعبئة الآن",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(historyProvider.notifier)
                        .toggleVoucherStatus(voucher.id),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      voucher.isUsed ? "تراجع" : "تعديل كمستعمل",
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyStatePlaceholder extends StatelessWidget {
  const EmptyStatePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.center_focus_weak, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            "قائمة الشحن فارغة",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "إضغط على زر المسح السريع بالأسفل لتبدأ",
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
