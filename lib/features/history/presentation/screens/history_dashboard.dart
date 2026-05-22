import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odfinance/features/history/presentation/widgets/stats_summary.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odfinance/features/history/presentation/providers/history_provider.dart';
import 'package:odfinance/features/history/presentation/widgets/voucher_list.dart';

class HistoryDashboardScreen extends ConsumerWidget {
  const HistoryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: Text(
          'تاريخ الشحن',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.black,
          ),
        ),
        // centerTitle: true
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/scanner'); // Open camera scanner view
        },
        backgroundColor: Colors.teal[700],
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text(
          "مسح سريع",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: historyState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text("خطأ في تحميل البيانات: $error")),
        data: (vouchers) {
          return Column(
            children: [
              StatsSummaryHeader(vouchers: vouchers),
              Expanded(
                child: vouchers.isEmpty
                    ? const EmptyStatePlaceholder()
                    : ListView.builder(
                        itemCount: vouchers.length,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemBuilder: (context, index) =>
                            VoucherListCard(voucher: vouchers[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
