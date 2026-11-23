from django.urls import path

from . import views

urlpatterns = [
    path('health', views.health),
    path('coins', views.coins),
    path('coins/<str:coin_id>', views.coin_detail),
    path('coins/<str:coin_id>/chart', views.coin_chart),
    path('global', views.global_stats),
]
