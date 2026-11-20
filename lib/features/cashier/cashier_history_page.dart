import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/order.dart';
import '../../services/app_services.dart';
import '../../state/auth_controller.dart';
import '../shared/order_detail_sheet.dart';

/// Halaman Riwayat Transaksi Kasir sesuai PRD Section 4.3 POS-09 & 17
class CashierHistoryPage extends StatefulWidget {
  const CashierHistoryPage({super.key});

  @override
  State<CashierHistoryPage> createState() => _CashierHistoryPageState();
}

class _CashierHistoryPageState extends State<CashierHistoryPage> {
  bool _todayOnly = true;

  @override
  Widget build(BuildContext context) {
    final services = context.read<AppServices>();
    final user = context.watch<AuthController>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Order>>(
          stream: services.orders.watchOrders(),
          builder: (context, snapshot) {
            final allOrders = snapshot.data ?? const <Order>[];
            final myOrders = allOrders
                .where((order) => order.cashierId == user?.uid)
                .toList();
            final now = DateTime.now();
            final todayOrders = myOrders
                .where((order) => isSameDay(order.createdAt, now))
                .toList();
            final paidToday = todayOrders.where((order) => order.isPaid).toList();
            final revenue = paidToday.fold<int>(
              0,
              (sum, order) => sum + order.total,
            );
            final visible = _todayOnly ? todayOrders : myOrders;
            final loading =
                snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Riwayat Transaksi', style: AppTypography.heading1()),
                            const SizedBox(height: 4),
                            Text(
                              'Transaksi yang diproses oleh ${user?.name ?? 'kamu'}.',
                              style: AppTypography.bodyM(),
                            ),
                            const SizedBox(height: 16),

                            // Kartu statistik transaksi hari ini
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isSmall = constraints.maxWidth < 500;
                                final itemWidth = isSmall
                                    ? constraints.maxWidth
                                    : (constraints.maxWidth - 20) / 3;
                                return Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    SizedBox(
                                      width: itemWidth,
                                      child: StatCard(
                                        icon: Icons.receipt_long_rounded,
                                        label: 'Transaksi Hari Ini',
                                        value: '${todayOrders.length}',
                                        accent: AppColors.primary,
                                        background: AppColors.primaryContainer,
                                        compact: true,
                                      ),
                                    ),
                                    SizedBox(
                                      width: itemWidth,
                                      child: StatCard(
                                        icon: Icons.payments_rounded,
                                        label: 'Pendapatan Hari Ini',
                                        value: compactRupiah(revenue),
                                        accent: AppColors.success,
                                        background: AppColors.successSoft,
                                        compact: true,
                                      ),
                                    ),
                                    SizedBox(
                                      width: itemWidth,
                                      child: StatCard(
                                        icon: Icons.schedule_rounded,
                                        label: 'Menunggu Bayar',
                                        value:
                                            '${todayOrders.where((o) => o.paymentStatus == PaymentStatus.pending).length}',
                                        accent: AppColors.warning,
                                        background: AppColors.warningSoft,
                                        compact: true,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // Filter Tab Hari Ini / Semua
                            Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('Hari ini'),
                                  selected: _todayOnly,
                                  onSelected: (_) =>
                                      setState(() => _todayOnly = true),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('Semua'),
                                  selected: !_todayOnly,
                                  onSelected: (_) =>
                                      setState(() => _todayOnly = false),
                                ),
                                const Spacer(),
                                Text(
                                  '${visible.length} transaksi',
                                  style: AppTypography.caption(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                if (loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (visible.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: _todayOnly
                          ? 'Belum ada transaksi hari ini'
                          : 'Belum ada transaksi',
                      message:
                          'Transaksi yang kamu proses akan otomatis tercatat di sini.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final order = visible[index];
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _HistoryCard(order: order),
                              ),
                            ),
                          );
                        },
                        childCount: visible.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: InkWell(
        onTap: () => showOrderDetailSheet(context, order),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  order.items.isEmpty ? '🧾' : order.items.first.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          order.code,
                          style: AppTypography.title().copyWith(fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: order.paymentStatus, compact: true),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${order.itemCount} item • ${dateTimeLabel(order.createdAt)}',
                      style: AppTypography.caption(),
                    ),
                  ],
                ),
              ),
              Text(
                rupiah(order.total),
                style: AppTypography.price(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
