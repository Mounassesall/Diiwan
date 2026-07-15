import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';

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
    defaultValue: 'http://localhost:8000',
  );

  List<RegionFeature> _features = [];
  bool _loading = true;
  String? _errorMessage;
  String _selectedIndicator = 'population';
  int _selectedYear = 2024;

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

  /// Palette de couleur : du jaune clair (valeurs basses) au vert foncé (valeurs hautes).
  Color _valueToColor(double value, double minVal, double maxVal) {
    if (maxVal == minVal) return Colors.green.shade400;
    final ratio = ((value - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);
    // Interpolation linéaire HSL : jaune (60°) → vert (120°)
    final hue = 60.0 + ratio * 60.0;
    final lightness = 0.75 - ratio * 0.35; // de clair à foncé
    return HSLColor.fromAHSL(1.0, hue, 0.7, lightness).toColor();
  }

  void _onRegionTap(RegionFeature feature) {
    final question =
        'Quelle est la $_selectedIndicator de ${feature.region} en $_selectedYear ?';
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.sendQuestion(question);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DiiwanChatScreen()),
    );
  }

  // --- Algorithme de ray-casting pour détecter si un point est dans un polygone ---
  bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int j = 0; j < polygon.length; j++) {
      final a = polygon[j];
      final b = polygon[(j + 1) % polygon.length];
      if (_rayIntersectsSegment(point, a, b)) intersectCount++;
    }
    return (intersectCount % 2) == 1;
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

    return Scaffold(
      appBar: AppBar(title: const Text('Carte des régions')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    // ---- Sélecteur d'indicateur ----
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: DropdownButtonFormField<String>(
                        value: _selectedIndicator,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Indicateur',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _indicators
                            .map((ind) => DropdownMenuItem(
                                  value: ind,
                                  child: Text(_indicatorLabels[ind] ?? ind),
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

                    // ---- Légende (gradient) ----
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Text(minVal.toStringAsFixed(0), style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              height: 10,
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
                          const SizedBox(width: 4),
                          Text(maxVal.toStringAsFixed(0), style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),

                    // ---- Carte ----
                    Expanded(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: const LatLng(14.5, -14.5), // centre du Sénégal
                          initialZoom: 6.5,
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
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.diiwan.mobile',
                          ),
                          PolygonLayer(
                            polygons: _features.map((f) {
                              final color = _valueToColor(f.indicatorValue, minVal, maxVal);
                              return Polygon(
                                points: f.geometry,
                                color: color.withOpacity(0.6),
                                borderStrokeWidth: 2,
                                borderColor: Colors.black54,
                              );
                            }).toList(),
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
  final List<LatLng> geometry;
  final double indicatorValue;

  RegionFeature({
    required this.region,
    required this.geometry,
    required this.indicatorValue,
  });

  /// Parse une feature GeoJSON.
  ///
  /// Le JSON attendu de l'API :
  /// ```json
  /// {
  ///   "type": "Feature",
  ///   "properties": {
  ///     "region": "Dakar",
  ///     "taux_chomage_pct": 12.5    // la valeur de l'indicateur demandé
  ///   },
  ///   "geometry": {
  ///     "type": "Polygon",
  ///     "coordinates": [[[lon, lat], ...]]
  ///   }
  /// }
  /// ```
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

    List<LatLng> points;
    if (type == 'MultiPolygon') {
      // Prendre le premier polygone du MultiPolygon
      final firstPolygon = coords[0] as List<dynamic>;
      final ring = firstPolygon[0] as List<dynamic>;
      points = ring
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
    } else {
      // Polygon simple
      final ring = coords[0] as List<dynamic>;
      points = ring
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
    }

    return RegionFeature(
      region: regionName,
      geometry: points,
      indicatorValue: indicatorValue,
    );
  }
}
