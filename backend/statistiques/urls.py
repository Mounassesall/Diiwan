from django.urls import path
from .views import QuestionView, RegionGeoJSONView

urlpatterns = [
    path('question/', QuestionView.as_view(), name='question'),
    path('regions-geojson/', RegionGeoJSONView.as_view(), name='regions_geojson'),
]
