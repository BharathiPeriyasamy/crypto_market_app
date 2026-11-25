import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/format.dart';
import '../models/coin_model.dart';
import '../providers/crypto_provider.dart';
import '../screens/coin_details/coin_details_screen.dart';
import 'app_snack_bar.dart';
import 'skeleton.dart';

// One table row: rank, coin, price, 24h change and market cap.
// Swipe right-to-left to reveal a star; tap the star to add or remove the
// coin from the watchlist.
class CoinCard extends StatefulWidget {
  final Coin coin;

  // Shows a filled star at the end of the row; tapping it removes the coin
  final bool showStar;

  const CoinCard({super.key, required this.coin, this.showStar = false});

  @override
  State<CoinCard> createState() => _CoinCardState();
}

class _CoinCardState extends State<CoinCard>
    with SingleTickerProviderStateMixin {
  static const _actionWidth = 72.0;

  // Only one row stays open at a time; opening another closes this one
  static final _openRow = ValueNotifier<_CoinCardState?>(null);

  // 0 = closed, 1 = star fully revealed
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  Coin get coin => widget.coin;

  @override
  void initState() {
    super.initState();
    _openRow.addListener(_onOpenRowChanged);
  }

  @override
  void dispose() {
    _openRow.removeListener(_onOpenRowChanged);
    if (_openRow.value == this) _openRow.value = null;
    _controller.dispose();
    super.dispose();
  }

  void _onOpenRowChanged() {
    if (_openRow.value != this && _controller.value > 0) {
      _controller.animateTo(0);
    }
  }

  void _open() {
    _controller.animateTo(1);
    _openRow.value = this;
  }

  void _close() {
    _controller.animateTo(0);
    if (_openRow.value == this) _openRow.value = null;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _openRow.value = this;
    _controller.value -= (details.primaryDelta ?? 0) / _actionWidth;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -300 || (velocity <= 300 && _controller.value > 0.5)) {
      _open();
    } else {
      _close();
    }
  }

  void _toggleWatchlist() {
    final crypto = context.read<CryptoProvider>();
    final added = !crypto.isInWatchlist(coin.id);
    final id = coin.id;
    crypto.toggleWatchlist(id);
    showWatchlistSnackBar(
      context,
      coinName: coin.name,
      added: added,
      // Uses the provider directly: this row may be gone by then
      onUndo: () => crypto.toggleWatchlist(id),
    );
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.select<CryptoProvider, bool>(
      (crypto) => crypto.isInWatchlist(coin.id),
    );
    final row = GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: _buildRow(context),
    );

    return AnimatedBuilder(
      animation: _controller,
      child: row,
      builder: (context, row) {
        final revealed = _actionWidth * _controller.value;
        return Stack(
          children: [
            // The star strip only covers the revealed part, so the
            // see-through row never shows it while closed
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: revealed,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: _actionWidth,
                  maxWidth: _actionWidth,
                  child: ColoredBox(
                    color: deepGreen,
                    child: IconButton(
                      tooltip: isFavorite
                          ? 'Remove from watchlist'
                          : 'Add to watchlist',
                      onPressed: _toggleWatchlist,
                      icon: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        color: isFavorite ? starColor : offWhite,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(offset: Offset(-revealed, 0), child: row),
          ],
        );
      },
    );
  }

  Widget _buildRow(BuildContext context) {
    return InkWell(
      // Tapping an open row just closes it
      onTap: () => _controller.value > 0
          ? _close()
          : Navigator.push(
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
          trailing: widget.showStar
              ? IconButton(
                  tooltip: 'Remove from watchlist',
                  onPressed: _toggleWatchlist,
                  icon: const Icon(Icons.star, color: starColor, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  alignment: Alignment.centerRight,
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
              : null,
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
  const CoinTableHeader({super.key, this.showStarColumn = false});

  // Leaves room for the star column so the headers line up with the rows
  final bool showStarColumn;

  @override
  Widget build(BuildContext context) {
    return _CoinRowLayout(
      rank: _cell('#', color: Colors.grey, size: 12, align: TextAlign.left),
      coin: const Text('Coin', style: TextStyle(color: Colors.grey, fontSize: 12)),
      price: _cell('Price', color: Colors.grey, size: 12),
      change: _cell('24H', color: Colors.grey, size: 12),
      marketCap: _cell('Market Cap', color: Colors.grey, size: 12),
      trailing: showStarColumn ? const SizedBox.shrink() : null,
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
    this.trailing,
  });

  final Widget rank;
  final Widget coin;
  final Widget price;
  final Widget change;
  final Widget marketCap;

  // Optional extra column at the end, e.g. the watchlist star
  final Widget? trailing;

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
          if (trailing case final trailing?)
            SizedBox(width: 34, child: trailing),
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
