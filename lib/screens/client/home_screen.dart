import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/brand.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/product_card.dart';
import 'category_products_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final offers = state.activeProducts.where((p) => p.onSale).toList();
    final featured = state.activeProducts.where((p) => p.featured).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _Header()),
            const SliverToBoxAdapter(child: _SearchField()),
            const SliverToBoxAdapter(child: _PromoCarousel()),
            SliverToBoxAdapter(
              child: SectionTitle(
                title: 'Categorías',
                actionLabel: 'Ver todas',
                onAction: () => state.setClientTab(1),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.categories.length,
                  separatorBuilder: (context, i) => const SizedBox(width: 10),
                  itemBuilder: (context, i) =>
                      _CategoryBubble(category: state.categories[i]),
                ),
              ),
            ),
            if (offers.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: SectionTitle(title: 'Ofertas de la semana 🔥'),
              ),
              ProductSliverGrid(products: offers),
            ],
            if (featured.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: SectionTitle(title: 'Lo más pedido'),
              ),
              ProductSliverGrid(products: featured),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          const BrandLogo(size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  Brand.appName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 14, color: primary),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        state.deliveryEnabled
                            ? 'Entregar en: ${state.customerAddress}'
                            : 'Retiro en tienda',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => showSnack(context, 'No tienes notificaciones nuevas'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: Colors.grey.shade500),
                const SizedBox(width: 10),
                Text(
                  '¿Qué necesitas hoy?',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Promo {
  const _Promo(this.title, this.subtitle, this.colors, this.emoji);

  final String title;
  final String subtitle;
  final List<Color> colors;
  final String emoji;
}

class _PromoCarousel extends StatefulWidget {
  const _PromoCarousel();

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  int _page = 0;
  Timer? _timer;
  static const _count = 3;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_controller.hasClients) return;
      _controller.animateToPage(
        (_page + 1) % _count,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final banners = [
      _Promo(
        'Envío gratis 🚚',
        'En compras desde ${usd(state.freeDeliveryFrom)}',
        [Brand.primary, Color.lerp(Brand.primary, Colors.black, 0.3)!],
        '🛒',
      ),
      const _Promo(
        'Ofertas de la semana',
        'Descuentos en productos seleccionados',
        [Color(0xFFF97316), Color(0xFFDC2626)],
        '🏷️',
      ),
      const _Promo(
        'Paga como prefieras',
        'Pago Móvil, Zelle, efectivo o punto de venta',
        [Color(0xFF6366F1), Color(0xFF7C3AED)],
        '💳',
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 146,
          child: PageView.builder(
            controller: _controller,
            itemCount: _count,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: _PromoCard(promo: banners[i]),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_count, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? Brand.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.promo});

  final _Promo promo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: promo.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  promo.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  promo.subtitle,
                  style: TextStyle(
                    color: Colors.white.withAlpha(230),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(promo.emoji, style: const TextStyle(fontSize: 52)),
        ],
      ),
    );
  }
}

class _CategoryBubble extends StatelessWidget {
  const _CategoryBubble({required this.category});

  final ProductCategory category;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CategoryProductsScreen(category: category),
      )),
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: category.color.withAlpha(45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(category.emoji, style: const TextStyle(fontSize: 30)),
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
