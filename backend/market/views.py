from django.http import JsonResponse

from . import service


def reply(result, missing='not found'):
    data, source = result
    if not data:
        return JsonResponse({'error': missing}, status=404)
    return JsonResponse({'source': source, 'data': data}, safe=False)


def health(request):
    return JsonResponse({'ok': True})


def coins(request):
    return reply(service.markets())


def global_stats(request):
    return reply(service.global_stats())


def coin_detail(request, coin_id):
    return reply(service.detail(coin_id), 'coin not found')


def coin_chart(request, coin_id):
    days = request.GET.get('days')
    if days not in ('1', '7', '30', '90', '365'):
        days = '7'
    return reply(service.chart(coin_id, days), 'coin not found')
