from django.contrib import admin
from .models import StatistiqueRegionale, RegionGeometrie

# Ajout du message global pour l'admin
admin.site.site_header = "Administration Diiwan - Données pédagogiques fictives"
admin.site.site_title = "Admin Diiwan"
admin.site.index_title = "Données pédagogiques fictives"

@admin.register(StatistiqueRegionale)
class StatistiqueRegionaleAdmin(admin.ModelAdmin):
    list_display = ('region', 'annee', 'population')
    search_fields = ('region',)
    list_filter = ('annee',)

@admin.register(RegionGeometrie)
class RegionGeometrieAdmin(admin.ModelAdmin):
    list_display = ('region',)
    search_fields = ('region',)
