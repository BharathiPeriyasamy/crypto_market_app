import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/crypto_provider.dart';
import '../../widgets/coin_card.dart';
import '../../widgets/state_message.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coins = context.watch<CryptoProvider>().watchlistCoins;
    if (coins.isEmpty) {
      return const StateMessage(
        icon: Icons.star_border,
        message: 'Your watchlist is empty.\n'
            'Swipe a coin left and tap the star to add it.',
      );
    }
    return ListView(
      children: [
        const CoinTableHeader(showStarColumn: true),
        for (final coin in coins)
          CoinCard(key: ValueKey(coin.id), coin: coin, showStar: true),
      ],
    );
  }
}
