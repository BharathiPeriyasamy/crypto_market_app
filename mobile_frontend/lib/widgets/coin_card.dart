import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/format.dart';
import '../models/coin_model.dart';
import '../screens/coin_details/coin_details_screen.dart';
import 'skeleton.dart';

// One table row: rank, coin, price, 24h change and market cap
class CoinCard extends StatelessWidget {
  final Coin coin;
  const CoinCard({super.key, required this.coin});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CoinDetailsScreen(coin: coin)),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: _CoinRowLayout(
          rank: _cell(
            '${coin.rank}',
            color: Colors.grey,
            size: 14,
            align: TextAlign.left,
          ),
          coin: Row(
            children: [
              CoinLogo(coin: coin),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  coin.symbol.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          price: _cell(formatPrice(coin.currentPrice), size: 14),
          change: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(child: ChangeBadge(change: coin.change24h)),
          ),
          marketCap: _cell(formatMoney(coin.marketCap), size: 14),
        ),
      ),
    );
  }
}

class CoinTableHeader extends StatelessWidget {
  const CoinTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return _CoinRowLayout(
      rank: _cell('#', color: Colors.grey, size: 12, align: TextAlign.left),
      coin: const Text('Coin', style: TextStyle(color: Colors.grey, fontSize: 12)),
      price: _cell('Price', color: Colors.grey, size: 12),
      change: _cell('24H', color: Colors.grey, size: 12),
      marketCap: _cell('Market Cap', color: Colors.grey, size: 12),
    );
  }
}

class CoinListSkeleton extends StatelessWidget {
  const CoinListSkeleton({super.key});

  static const _rightAligned = Align(
    alignment: Alignment.centerRight,
    child: SkeletonBox(width: 56, height: 12),
  );

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const CoinTableHeader(),
          for (var i = 0; i < 12; i++)
            const _CoinRowLayout(
              rank: Align(
                alignment: Alignment.centerLeft,
                child: SkeletonBox(width: 16, height: 12),
              ),
              coin: Row(
                children: [
                  SkeletonBox(width: 28, height: 28, radius: 14),
                  SizedBox(width: 8),
                  SkeletonBox(width: 40, height: 12),
                ],
              ),
              price: _rightAligned,
              change: _rightAligned,
              marketCap: _rightAligned,
            ),
        ],
      ),
    );
  }
}

// Column widths are defined once so the header and rows line up
class _CoinRowLayout extends StatelessWidget {
  const _CoinRowLayout({
    required this.rank,
    required this.coin,
    required this.price,
    required this.change,
    required this.marketCap,
  });

  final Widget rank;
  final Widget coin;
  final Widget price;
  final Widget change;
  final Widget marketCap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 28, child: rank),
          Expanded(flex: 7, child: coin),
          Expanded(flex: 8, child: price),
          Expanded(flex: 7, child: change),
          Expanded(flex: 7, child: marketCap),
        ],
      ),
    );
  }
}

Widget _cell(
  String text, {
  Color? color,
  double size = 13,
  TextAlign align = TextAlign.right,
}) {
  return Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    textAlign: align,
    style: TextStyle(color: color, fontSize: size),
  );
}

// Percent change in a pill with an up or down arrow, tinted green or red
class ChangeBadge extends StatelessWidget {
  const ChangeBadge({super.key, required this.change});

  final double change;

  @override
  Widget build(BuildContext context) {
    final color = changeColor(change);
    return Container(
      padding: const EdgeInsets.fromLTRB(2, 4, 8, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            change >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            size: 18,
            color: color,
          ),
          Text(
            formatPercent(change),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class CoinLogo extends StatelessWidget {
  const CoinLogo({super.key, required this.coin, this.radius = 14});

  final Coin coin;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final image = coin.image;
    return CircleAvatar(
      radius: radius,
      backgroundImage: image == null ? null : NetworkImage(image),
      child: image == null ? Text(coin.symbol[0].toUpperCase()) : null,
    );
  }
}
