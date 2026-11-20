import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/menu_item.dart';
import '../../models/order.dart';
import '../../services/app_services.dart';
import '../../state/auth_controller.dart';
import '../shared/order_detail_sheet.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({
    super.key,
    required this.onOpenMenus,
    required this.onOpenOrders,
  });

  final VoidCallback onOpenMenus;
  final VoidCallback onOpenOrders;

  @override
  Widget build(BuildContext context) {
    final services = context.read<AppServices>();
    final user = context.watch<AuthController>().user;

    return SafeArea(
      bottom: false,
      child: StreamBuilder<List<MenuItem>>(
        stream: services.menus.watchMenus(),
        builder: (context, menuSnapshot) {
          return StreamBuilder<List<Order>>(
            stream: services.orders.watchOrders(),
            builder: (context, orderSnapshot) {
              final loading =
                  menuSnapshot.connectionState == ConnectionState.waiting &&
                  !menuSnapshot.hasData;
              if (loading) {
                return const Center(child: CircularProgressIndicator());
              }

              final menus = menuSnapshot.data ?? const <MenuItem>[];
              final orders = orderSnapshot.data ?? const <Order>[];
              return _DashboardContent(
                menus: menus,
                orders: orders,
                name: user?.name ?? 'Admin',
                onOpenMenus: onOpenMenus,
                onOpenOrders: onOpenOrders,
              );
            },
          );
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.menus,
    required this.orders,
    required this.name,
    required this.onOpenMenus,
    required this.onOpenOrders,
  });

  final List<MenuItem> menus;
  final List<Order> orders;
  final String name;
  final VoidCallback onOpenMenus;
  final VoidCallback onOpenOrders;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayOrders = orders
        .where((order) => isSameDay(order.createdAt, now))
        .toList();
    final paidToday = todayOrders.where((order) => order.isPaid).toList();
    final pendingToday = todayOrders
        .where((order) => order.paymentStatus == PaymentStatus.pending)
        .length;
    final revenue = paidToday.fold<int>(0, (sum, order) => sum + order.total);
    final firstName = name.trim().split(RegExp(r'\s+')).first;
    final activeMenus = menus.where((menu) => menu.isAvailable).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 34),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(name: firstName, date: now),
              const SizedBox(height: 20),
              _WelcomeBanner(
                paidCount: paidToday.length,
                revenue: revenue,
                onOpenMenus: onOpenMenus,
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 980 ? 4 : 2;
                  const spacing = 12.0;
                  final width =
                      (constraints.maxWidth - spacing * (columns - 1)) /
                      columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      SizedBox(
                        width: width,
                        child: StatCard(
                          icon: Icons.restaurant_menu_rounded,
                          label: 'Menu aktif',
                          value: '$activeMenus',
                          accent: AppColors.coral,
                          background: AppColors.coralSoft,
                          hint: '${menus.length} total',
                          compact: width < 180,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: StatCard(
                          icon: Icons.receipt_long_rounded,
                          label: 'Pesanan hari ini',
                          value: '${todayOrders.length}',
                          accent: AppColors.primary,
                          background: AppColors.primarySoft,
                          hint: '${paidToday.length} lunas',
                          compact: width < 180,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: StatCard(
                          icon: Icons.payments_rounded,
                          label: 'Pendapatan hari ini',
                          value: compactRupiah(revenue),
                          accent: AppColors.mint,
                          background: AppColors.mintSoft,
                          hint: 'Real-time',
                          compact: width < 180,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: StatCard(
                          icon: Icons.schedule_rounded,
                          label: 'Menunggu bayar',
                          value: '$pendingToday',
                          accent: const Color(0xFFB77900),
                          background: AppColors.amberSoft,
                          hint: pendingToday > 0 ? 'Perlu dicek' : 'Aman',
                          compact: width < 180,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 900;
                  final chart = _WeeklyRevenueCard(orders: orders);
                  final topMenus = _TopMenuCard(orders: orders);
                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        chart,
                        const SizedBox(height: 16),
                        topMenus,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: chart),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: topMenus),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _RecentOrdersCard(
                orders: orders.take(5).toList(),
                onOpenOrders: onOpenOrders,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.date});

  final String name;
  final DateTime date;

  String get _greeting {
    final hour = date.hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_greeting, $name 👋',
                    style: TextStyle(
                      fontSize: compact ? 21 : 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ini ringkasan operasional tokomu hari ini.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (!compact)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${dayName(date)}, ${shortDate(date)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({
    required this.paidCount,
    required this.revenue,
    required this.onOpenMenus,
  });

  final int paidCount;
  final int revenue;
  final VoidCallback onOpenMenus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -52,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 80,
            bottom: -70,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.coral.withValues(alpha: 0.22),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final info = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConfig.storeName.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    paidCount == 0
                        ? 'Belum ada transaksi hari ini'
                        : '$paidCount pesanan sudah lunas',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Pendapatan terkumpul ${rupiah(revenue)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );

              final button = TextButton.icon(
                onPressed: onOpenMenus,
                icon: const Icon(Icons.add_rounded, size: 17),
                label: const Text('Kelola menu'),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryDeep,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    info,
                    const SizedBox(height: 16),
                    Align(alignment: Alignment.centerLeft, child: button),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: info),
                  const SizedBox(width: 16),
                  button,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeeklyRevenueCard extends StatelessWidget {
  const _WeeklyRevenueCard({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (index) {
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - index));
      final value = orders
          .where(
            (order) =>
                order.isPaid && isSameDay(order.createdAt, date),
          )
          .fold<int>(0, (sum, order) => sum + order.total);
      return (date: date, value: value);
    });
    final maxValue = days.fold<int>(
      0,
      (max, day) => math.max(max, day.value),
    );
    final total = days.fold<int>(0, (sum, day) => sum + day.value);

    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionTitle(
                  title: 'Pendapatan 7 hari',
                  subtitle: 'Transaksi lunas per hari',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  compactRupiah(total),
                  style: const TextStyle(
                    color: AppColors.mint,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final ratio = maxValue == 0 ? 0.06 : day.value / maxValue;
                final isToday = isSameDay(day.date, now);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Tooltip(
                          message: rupiah(day.value),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            height: 8 + (92 * ratio),
                            decoration: BoxDecoration(
                              gradient: isToday
                                  ? AppColors.warmGradient
                                  : LinearGradient(
                                      colors: [
                                        AppColors.primary.withValues(
                                          alpha: 0.32,
                                        ),
                                        AppColors.primary.withValues(
                                          alpha: 0.16,
                                        ),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dayName(day.date).substring(0, 3),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: isToday
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isToday
                                ? AppColors.coral
                                : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopMenuCard extends StatelessWidget {
  const _TopMenuCard({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final quantities = <String, ({String name, String emoji, int qty})>{};
    for (final order in orders.where((order) => order.isPaid)) {
      for (final item in order.items) {
        final current = quantities[item.menuId];
        quantities[item.menuId] = (
          name: item.name,
          emoji: item.emoji,
          qty: (current?.qty ?? 0) + item.quantity,
        );
      }
    }
    final top = quantities.values.toList()
      ..sort((a, b) => b.qty.compareTo(a.qty));
    final visible = top.take(4).toList();
    final maxQty = visible.isEmpty ? 1 : visible.first.qty;

    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Menu terlaris',
            subtitle: 'Berdasarkan seluruh transaksi',
          ),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: Text(
                  'Belum ada data penjualan.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            ...visible.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? AppColors.amberSoft
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              Text(
                                '${item.qty}x',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: item.qty / maxQty,
                              minHeight: 5,
                              backgroundColor: AppColors.background,
                              valueColor: AlwaysStoppedAnimation(
                                index == 0
                                    ? AppColors.coral
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _RecentOrdersCard extends StatelessWidget {
  const _RecentOrdersCard({
    required this.orders,
    required this.onOpenOrders,
  });

  final List<Order> orders;
  final VoidCallback onOpenOrders;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionTitle(
                  title: 'Pesanan terbaru',
                  subtitle: 'Aktivitas transaksi terakhir',
                ),
              ),
              TextButton(
                onPressed: onOpenOrders,
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (orders.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Belum ada pesanan',
              message: 'Transaksi dari kasir akan muncul di sini secara real-time.',
              compact: true,
            )
          else
            ...orders.map(
              (order) => _RecentOrderRow(order: order),
            ),
        ],
      ),
    );
  }
}

class _RecentOrderRow extends StatelessWidget {
  const _RecentOrderRow({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showOrderDetailSheet(context, order),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Text(
                order.items.isEmpty ? '🧾' : order.items.first.emoji,
                style: const TextStyle(fontSize: 19),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.code,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.cashierName} • ${timeOnly(order.createdAt)}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  rupiah(order.total),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                StatusBadge(status: order.paymentStatus, compact: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
