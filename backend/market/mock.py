import random
import time

# Sample data used when the live api is down or rate limited
# (id, symbol, name, price, circulating supply, max supply, 24h change)
COINS = [
    ('bitcoin', 'btc', 'Bitcoin', 67000, 19.7e6, 21e6, 1.8),
    ('ethereum', 'eth', 'Ethereum', 3500, 120.2e6, None, -0.9),
    ('tether', 'usdt', 'Tether', 1, 110e9, None, 0.01),
    ('binancecoin', 'bnb', 'BNB', 590, 147.6e6, 200e6, 0.7),
    ('solana', 'sol', 'Solana', 165, 445e6, None, 4.2),
    ('ripple', 'xrp', 'XRP', 0.52, 55e9, 100e9, -2.1),
    ('usd-coin', 'usdc', 'USDC', 1, 33e9, None, 0),
    ('cardano', 'ada', 'Cardano', 0.45, 35.7e9, 45e9, -1.4),
    ('dogecoin', 'doge', 'Dogecoin', 0.15, 144e9, None, 6.3),
    ('avalanche-2', 'avax', 'Avalanche', 35, 394e6, 720e6, 2.5),
    ('tron', 'trx', 'TRON', 0.12, 87e9, None, 0.4),
    ('polkadot', 'dot', 'Polkadot', 7.1, 1.4e9, None, -3.2),
    ('chainlink', 'link', 'Chainlink', 14.5, 587e6, 1e9, 3.1),
    ('litecoin', 'ltc', 'Litecoin', 84, 74.7e6, 84e6, -0.6),
    ('near', 'near', 'NEAR Protocol', 6.2, 1.1e9, None, 5.5),
    ('uniswap', 'uni', 'Uniswap', 9.8, 753e6, 1e9, -1.8),
    ('stellar', 'xlm', 'Stellar', 0.11, 29e9, 50e9, 1.1),
    ('monero', 'xmr', 'Monero', 160, 18.4e6, None, 0.2),
]


def chart(price, days):
    count = 96 if days <= 1 else min(days * 24, 300)
    step = days * 86400000 / count
    walk = [1.0]
    for _ in range(1, count):
        walk.append(walk[-1] * (1 + (random.random() - 0.5) * 0.02))
    scale = price / walk[-1]
    now = int(time.time() * 1000)
    return [[round(now - (count - 1 - i) * step), w * scale] for i, w in enumerate(walk)]


def markets():
    result = []
    for i, (coin_id, symbol, name, base, supply, max_supply, change) in enumerate(COINS):
        price = base * (1 + (random.random() - 0.5) * 0.01)
        cap = price * supply
        week = chart(price, 7)[::6]
        result.append({
            'id': coin_id,
            'symbol': symbol,
            'name': name,
            'image': None,
            'current_price': price,
            'market_cap': cap,
            'market_cap_rank': i + 1,
            'total_volume': cap * 0.05,
            'high_24h': price * 1.03,
            'low_24h': price * 0.97,
            'price_change_percentage_24h': change,
            'circulating_supply': supply,
            'total_supply': max_supply or supply,
            'max_supply': max_supply,
            'ath': base * 1.6,
            'atl': base * 0.02,
            'sparkline_in_7d': {'price': [p[1] for p in week]},
        })
    return result


def detail(coin_id):
    coin = next((c for c in markets() if c['id'] == coin_id), None)
    if not coin:
        return None
    coin.update(
        description=f"Sample data for {coin['name']}. The live API is not available right now.",
        homepage=None,
        categories=[],
    )
    return coin


def global_stats():
    coins = markets()
    total = sum(c['market_cap'] for c in coins)
    weighted = sum(c['price_change_percentage_24h'] * c['market_cap'] for c in coins)
    return {
        'active_cryptocurrencies': 14000,
        'markets': 1100,
        'total_market_cap_usd': total,
        'total_volume_usd': sum(c['total_volume'] for c in coins),
        'market_cap_change_percentage_24h_usd': weighted / total,
        'btc_dominance': coins[0]['market_cap'] / total * 100,
        'eth_dominance': coins[1]['market_cap'] / total * 100,
    }
