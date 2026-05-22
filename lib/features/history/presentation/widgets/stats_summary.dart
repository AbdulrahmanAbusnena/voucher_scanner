import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:odfinance/features/history/presentation/widgets/stat_item.dart';
import 'package:odfinance/features/history/presentation/widgets/stats_summary.dart';
import 'package:odfinance/features/history/domain/models/voucher.dart';

class StatsSummaryHeader extends StatelessWidget {
  final List<Voucher> vouchers;
  const StatsSummaryHeader({required this.vouchers});

  @override
  Widget build(BuildContext context) {
    final total = vouchers.length;
    final libyanaCount = vouchers
        .where((v) => v.carrier == CarrierType.libyana)
        .length;
    final almadarCount = vouchers
        .where((v) => v.carrier == CarrierType.almadar)
        .length;
    final othersCount = total - (libyanaCount + almadarCount);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          StatItem(label: "الإجمالي", count: total, color: Colors.black87),
          StatItem(
            label: "ليبيانا",
            count: libyanaCount,
            color: Colors.blue.shade700,
          ),
          StatItem(
            label: "المدار",
            count: almadarCount,
            color: Colors.orange.shade700,
          ),
          StatItem(
            label: "أخرى",
            count: othersCount,
            color: Colors.teal.shade700,
          ),
        ],
      ),
    );
  }
}
