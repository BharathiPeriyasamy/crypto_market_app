import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/format.dart';
import '../models/coin_model.dart';
import '../providers/crypto_provider.dart';
import '../screens/coin_details/coin_details_screen.dart';

class CoinCard extends StatelessWidget {
  const CoinCard({super.key, required this.coin});

  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final crypto = context.watch<CryptoProvider>();
    final isFavorite = crypto.isInWatchlist(coin.id);

    return Card(
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CoinDetailsScreen(coin: coin)),
        ),
        leading: CoinLogo(coin: coin),
        title: Text(coin.name),
        subtitle: Text('#${coin.rank}  ${coin.symbol.toUpperCase()}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatPrice(coin.currentPrice)),
                Text(
                  formatPercent(coin.change24h),
                  style: TextStyle(color: changeColor(coin.change24h)),
                ),
              ],
            ),
            IconButton(
              icon: Icon(isFavorite ? Icons.star : Icons.star_border),
              color: isFavorite ? Colors.amber : null,
              onPressed: () => crypto.toggleWatchlist(coin.id),
            ),
          ],
        ),
      ),
    );
  }
}

class CoinLogo extends StatelessWidget {
  const CoinLogo({super.key, required this.coin, this.radius = 20});

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
