import os
import re
import time

import requests

from . import mock

API = 'https://api.coingecko.com/api/v3'
KEY = os.environ.get('COINGECKO_API_KEY')
FORCE_MOCK = os.environ.get('MOCK') == '1'

RETRY_AFTER = 60  # seconds to wait after a failed live call

cache = {}
failed_at = {}


def call_api(path):
    headers = {'x-cg-demo-api-key': KEY} if KEY else {}
    res = requests.get(API + path, headers=headers, timeout=8)
    res.raise_for_status()
    return res.json()


def load(key, seconds, fetch, fallback):
    # order: fresh cache, live api, old cache, mock data
    hit = cache.get(key)
    if hit and time.time() - hit['time'] < seconds:
        return hit['data'], hit['source']
    # after a failure, wait before calling the live api again so we
    # don't keep hammering it while it is rate limiting or blocking us
    cooling = time.time() - failed_at.get(key, 0) < RETRY_AFTER
    if not FORCE_MOCK and not cooling:
        try:
            data = fetch()
            cache[key] = {'time': time.time(), 'data': data, 'source': 'live'}
            failed_at.pop(key, None)
            return data, 'live'
        except Exception as e:
            failed_at[key] = time.time()
            print(f'live api failed for {key}: {e}', flush=True)
    if hit:
        return hit['data'], 'stale'
    return fallback(), 'mock'


def markets():
    return load(
        'markets', 60,
        lambda: call_api('/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&sparkline=true'),
        mock.markets,
    )


def global_stats():
    def fetch():
        g = call_api('/global')['data']
        return {
            'active_cryptocurrencies': g['active_cryptocurrencies'],
            'markets': g['markets'],
            'total_market_cap_usd': g['total_market_cap']['usd'],
            'total_volume_usd': g['total_volume']['usd'],
            'market_cap_change_percentage_24h_usd': g['market_cap_change_percentage_24h_usd'],
            'btc_dominance': g['market_cap_percentage']['btc'],
            'eth_dominance': g['market_cap_percentage']['eth'],
        }

    return load('global', 120, fetch, mock.global_stats)


def detail(coin_id):
    def fetch():
        c = call_api(f'/coins/{coin_id}?localization=false&tickers=false&community_data=false&developer_data=false')
        m = c['market_data']
        return {
            'id': c['id'],
            'symbol': c['symbol'],
            'name': c['name'],
            'image': c['image']['large'],
            'current_price': m['current_price']['usd'],
            'market_cap': m['market_cap']['usd'],
            'market_cap_rank': c['market_cap_rank'],
            'total_volume': m['total_volume']['usd'],
            'high_24h': m['high_24h']['usd'],
            'low_24h': m['low_24h']['usd'],
            'price_change_percentage_24h': m['price_change_percentage_24h'],
            'circulating_supply': m['circulating_supply'],
            'total_supply': m['total_supply'],
            'max_supply': m['max_supply'],
            'ath': m['ath']['usd'],
            'atl': m['atl']['usd'],
            'description': re.sub(r'<[^>]+>', '', c['description'].get('en') or ''),
            'homepage': (c['links']['homepage'] or [None])[0] or None,
            'categories': c.get('categories') or [],
        }

    return load(f'detail:{coin_id}', 120, fetch, lambda: mock.detail(coin_id))


def chart(coin_id, days):
    def fetch():
        return call_api(f'/coins/{coin_id}/market_chart?vs_currency=usd&days={days}')['prices']

    def fallback():
        coin = next((c for c in mock.markets() if c['id'] == coin_id), None)
        sample_days = 1825 if days == 'max' else int(days)
        return mock.chart(coin['current_price'], sample_days) if coin else None

    return load(f'chart:{coin_id}:{days}', 120, fetch, fallback)
