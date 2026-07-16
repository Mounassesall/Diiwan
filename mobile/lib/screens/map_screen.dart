import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../screens/chat_screen.dart';
import '../theme.dart';

/// Écran de carte choroplèthe du Sénégal.
///
/// Charge les polygones GeoJSON depuis {baseUrl}/api/regions/geojson/
/// et colore chaque région selon la valeur d'un indicateur sélectionné
/// dans un menu déroulant. Au tap sur une région, navigue vers l'écran
/// de chat avec une question pré-remplie correspondante.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final String _baseUrl = const String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://diiwan-backend.onrender.com',
  );

  List<RegionFeature> _features = [];
  bool _loading = true;
  String? _errorMessage;
  String _selectedIndicator = 'population';
  int _selectedYear = 2024;
  final ValueNotifier<double> _zoomNotifier = ValueNotifier<double>(6.5);
  final MapController _mapController = MapController();

  /// Liste blanche des indicateurs (identique à celle du backend)
  static const List<String> _indicators = [
    'population',
    'taux_urbanisation_pct',
    'taux_alphabetisation_pct',
    'taux_chomage_pct',
    'taux_pauvrete_pct',
    'acces_internet_pct',
    'centres_sante',
    'taux_scolarisation_pct',
    'production_cerealiere_tonnes',
  ];

  /// Labels lisibles pour le dropdown
  static const Map<String, String> _indicatorLabels = {
    'population': 'la population',
    'taux_urbanisation_pct': "le taux d'urbanisation",
    'taux_alphabetisation_pct': "le taux d'alphabétisation",
    'taux_chomage_pct': 'le taux de chômage',
    'taux_pauvrete_pct': 'le taux de pauvreté',
    'acces_internet_pct': "l'accès à Internet",
    'centres_sante': 'le nombre de centres de santé',
    'taux_scolarisation_pct': 'le taux de scolarisation',
    'production_cerealiere_tonnes': 'la production céréalière',
  };

  static const Map<String, String> _indicatorDropdownLabels = {
    'population': 'Population',
    'taux_urbanisation_pct': 'Urbanisation (%)',
    'taux_alphabetisation_pct': 'Alphabétisation (%)',
    'taux_chomage_pct': 'Chômage (%)',
    'taux_pauvrete_pct': 'Pauvreté (%)',
    'acces_internet_pct': 'Accès Internet (%)',
    'centres_sante': 'Centres de santé',
    'taux_scolarisation_pct': 'Scolarisation (%)',
    'production_cerealiere_tonnes': 'Production céréalière (t)',
  };

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
  }

  Future<void> _loadGeoJson() async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/api/regions/geojson/?indicator=$_selectedIndicator&annee=$_selectedYear',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final geo = jsonDecode(response.body) as Map<String, dynamic>;
        final features = (geo['features'] as List<dynamic>)
            .map((f) => RegionFeature.fromJson(f as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _features = features;
            _loading = false;
            _errorMessage = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
            _errorMessage = 'Erreur serveur (${response.statusCode})';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Erreur réseau : $e';
        });
      }
    }
  }

  /// Indique si un indicateur est "négatif" (rouge) ou "positif" (vert)
  bool _isNegativeIndicator(String indicator) {
    return indicator == 'taux_chomage_pct' || indicator == 'taux_pauvrete_pct';
  }

  /// Palette de couleur identique au web : rouge si négatif, émeraude sinon.
  Color _valueToColor(double value, double minVal, double maxVal) {
    if (maxVal == minVal) return const Color(0xFF10B981); // Emerald par défaut
    
    final pct = ((value - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);
    // Lightness varie de 0.8 (clair) à 0.3 (foncé)
    final lightness = 0.80 - (pct * 0.50);
    
    if (_isNegativeIndicator(_selectedIndicator)) {
      // Rouge (Hue = 0)
      return HSLColor.fromAHSL(1.0, 0.0, 0.75, lightness).toColor();
    } else {
      // Emeraude (Hue = 142)
      return HSLColor.fromAHSL(1.0, 142.0, 0.70, lightness).toColor();
    }
  }

  void _onRegionTap(RegionFeature feature) {
    final indicatorText = _indicatorLabels[_selectedIndicator] ?? _selectedIndicator;
    final unit = _selectedIndicator.contains('pct') ? '%' : (_selectedIndicator == 'population' ? 'hab.' : '');
    final formattedValue = feature.indicatorValue % 1 == 0 
        ? feature.indicatorValue.toInt().toString() 
        : feature.indicatorValue.toStringAsFixed(1);

    // Au lieu de naviguer immédiatement, on affiche un BottomSheet interactif (comme le tooltip web)
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feature.region,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                '${_indicatorDropdownLabels[_selectedIndicator]} : $formattedValue $unit',
                style: const TextStyle(fontSize: 16, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Demander à l\'IA', style: TextStyle(fontSize: 16)),
                  onPressed: () {
                    Navigator.pop(context); // Fermer le bottom sheet
                    final question = 'Quelle est $indicatorText de ${feature.region} en $_selectedYear ?';
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DiiwanChatScreen(prefilledQuestion: question),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Algorithme de ray-casting pour détecter si un point est dans un polygone ---
  bool _pointInPolygon(LatLng point, List<List<LatLng>> polygons) {
    for (final poly in polygons) {
      int intersectCount = 0;
      for (int j = 0; j < poly.length; j++) {
        final a = poly[j];
        final b = poly[(j + 1) % poly.length];
        if (_rayIntersectsSegment(point, a, b)) intersectCount++;
      }
      if ((intersectCount % 2) == 1) return true;
    }
    return false;
  }

  bool _rayIntersectsSegment(LatLng p, LatLng a, LatLng b) {
    final double py = p.latitude;
    final double px = p.longitude;
    double ay = a.latitude, ax = a.longitude;
    double by = b.latitude, bx = b.longitude;

    if (ay > by) {
      // swap
      final ty = ay, tx = ax;
      ay = by;
      ax = bx;
      by = ty;
      bx = tx;
    }
    // Avoid edge cases
    final double adjustedPy = (py == ay || py == by) ? py + 0.0000001 : py;
    if (adjustedPy < ay || adjustedPy > by) return false;
    if (ax == bx) return px <= ax;
    final double xIntersect =
        (adjustedPy - ay) * (bx - ax) / (by - ay) + ax;
    return px <= xIntersect;
  }

  @override
  Widget build(BuildContext context) {
    // Calcul des min/max pour la coloration
    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;
    for (final f in _features) {
      final v = f.indicatorValue;
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
    }
    if (minVal == double.infinity) {
      minVal = 0;
      maxVal = 100;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: DiiwanTheme.background(isDark),
      appBar: AppBar(
        title: Text('Carte des régions', style: TextStyle(color: DiiwanTheme.textPrimary(isDark))),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: DiiwanTheme.primary))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    // ---- Sélecteur d'indicateur ----
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Container(
                            decoration: BoxDecoration(
                              color: DiiwanTheme.surface(isDark),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: DiiwanTheme.border(isDark)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: DropdownButtonFormField<String>(
                              value: _selectedIndicator,
                              isExpanded: true,
                              dropdownColor: DiiwanTheme.surface(isDark),
                              style: TextStyle(color: DiiwanTheme.textPrimary(isDark), fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Indicateur',
                                labelStyle: TextStyle(color: DiiwanTheme.textSecondary(isDark)),
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            items: _indicators
                                .map((ind) => DropdownMenuItem(
                                      value: ind,
                                      child: Text(_indicatorDropdownLabels[ind] ?? ind),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedIndicator = val;
                                  _loading = true;
                                });
                                _loadGeoJson();
                              }
                            },
                          ),
                        ),
                      ),
                      ),
                    ),

                    // ---- Légende (gradient) ----
                    Container(
                      color: const Color(0xFF1E293B),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Row(
                            children: [
                          Text(minVal.toStringAsFixed(0), style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: LinearGradient(
                                  colors: [
                                    _valueToColor(minVal, minVal, maxVal),
                                    _valueToColor(maxVal, minVal, maxVal),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(maxVal.toStringAsFixed(0), style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ))),

                    // ---- Carte ----
                    Expanded(
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: const LatLng(14.5, -14.5), // centre du Sénégal
                          initialZoom: 6.5,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all,
                          ),
                          onPositionChanged: (position, hasGesture) {
                            if (position.zoom != null) {
                              _zoomNotifier.value = position.zoom!;
                            }
                          },
                          onTap: (tapPos, point) {
                            // Chercher quel polygone contient le point tapé
                            for (final f in _features) {
                              if (_pointInPolygon(point, f.geometry)) {
                                _onRegionTap(f);
                                return;
                              }
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c', 'd'],
                            userAgentPackageName: 'com.diiwan.mobile',
                          ),
                          PolygonLayer(
                            polygons: _features.expand((f) {
                              final color = _valueToColor(f.indicatorValue, minVal, maxVal);
                              return f.geometry.map((ring) => Polygon(
                                points: ring,
                                color: color.withOpacity(0.7),
                                isFilled: true,
                                borderStrokeWidth: 1.5,
                                borderColor: const Color(0xFF0F172A), // Bordure comme le fond web
                              ));
                            }).toList(),
                          ),
                          ValueListenableBuilder<double>(
                            valueListenable: _zoomNotifier,
                            builder: (context, currentZoom, child) {
                              return MarkerLayer(
                                markers: const {
                                  'Dakar': LatLng(14.7167, -17.4677),
                                  'Thiès': LatLng(14.7929, -16.9250),
                                  'Diourbel': LatLng(14.6533, -16.2300),
                                  'Fatick': LatLng(14.3353, -16.4069),
                                  'Kaolack': LatLng(14.1500, -16.0667),
                                  'Kaffrine': LatLng(14.1059, -15.5508),
                                  'Louga': LatLng(15.6174, -16.2238),
                                  'Saint-Louis': LatLng(16.0326, -16.4818),
                                  'Matam': LatLng(15.6559, -13.2555),
                                  'Tambacounda': LatLng(13.7689, -13.6673),
                                  'Kédougou': LatLng(12.5539, -12.1793),
                                  'Kolda': LatLng(12.8833, -14.9500),
                                  'Sédhiou': LatLng(12.7081, -15.5569),
                                  'Ziguinchor': LatLng(12.5833, -16.2719),
                                }.entries.where((entry) {
                                  final isSmall = ['Sédhiou', 'Kaffrine', 'Diourbel', 'Dakar', 'Fatick', 'Thiès', 'Kaolack'].contains(entry.key);
                                  return !isSmall || currentZoom >= 6.5;
                                }).map((entry) {
                                  final isSmall = ['Sédhiou', 'Kaffrine', 'Diourbel', 'Dakar', 'Fatick', 'Thiès', 'Kaolack'].contains(entry.key);
                                  
                                  double fontSize = 11.0;
                                  if (isSmall) {
                                    fontSize = currentZoom >= 7.0 ? 9.0 : 8.0;
                                  } else if (['Louga', 'Saint-Louis', 'Kolda', 'Ziguinchor'].contains(entry.key)) {
                                    fontSize = 10.0;
                                  }

                                  return Marker(
                                    point: entry.value,
                                    width: 80,
                                    height: 30,
                                    alignment: Alignment.center,
                                    child: IgnorePointer(
                                      child: Center(
                                        child: Text(
                                          entry.key.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white.withOpacity(0.95),
                                            shadows: const [
                                              Shadow(offset: Offset(-1, -1), color: Color(0xFF0F172A)),
                                              Shadow(offset: Offset(1, -1), color: Color(0xFF0F172A)),
                                              Shadow(offset: Offset(-1, 1), color: Color(0xFF0F172A)),
                                              Shadow(offset: Offset(1, 1), color: Color(0xFF0F172A)),
                                              Shadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black87),
                                            ],
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

// --------------------------------------------------------------------------
// Modèle simplifié pour les features GeoJSON
// --------------------------------------------------------------------------

class RegionFeature {
  final String region;
  final List<List<LatLng>> geometry;
  final double indicatorValue;

  RegionFeature({
    required this.region,
    required this.geometry,
    required this.indicatorValue,
  });

  /// Parse une feature GeoJSON.
  factory RegionFeature.fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final regionName = props['region'] as String? ?? 'Inconnu';

    // Chercher la première valeur numérique (hors "region") comme indicateur
    double indicatorValue = 0;
    for (final entry in props.entries) {
      if (entry.key != 'region' && entry.value is num) {
        indicatorValue = (entry.value as num).toDouble();
        break;
      }
    }

    // Parser la géométrie (Polygon ou MultiPolygon)
    final geom = json['geometry'] as Map<String, dynamic>;
    final type = geom['type'] as String;
    final coords = geom['coordinates'] as List<dynamic>;

    List<List<LatLng>> geometryList = [];
    if (type == 'Polygon') {
      final ring = coords[0] as List<dynamic>;
      final points = ring
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
      geometryList.add(points);
    } else if (type == 'MultiPolygon') {
      for (final polygon in coords) {
        final ring = polygon[0] as List<dynamic>;
        final points = ring
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();
        geometryList.add(points);
      }
    }

    return RegionFeature(
      region: regionName,
      geometry: geometryList,
      indicatorValue: indicatorValue,
    );
  }
}
