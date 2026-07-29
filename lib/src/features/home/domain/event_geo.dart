import 'package:latlong2/latlong.dart';

/// Примерные координаты городов для карты, если у события нет lat/lng.
LatLng? coordinatesForCity(String city) {
  final key = city.trim().toLowerCase();
  const map = <String, LatLng>{
    'almaty': LatLng(43.238949, 76.945465),
    'алматы': LatLng(43.238949, 76.945465),
    'astana': LatLng(51.169392, 71.449074),
    'астана': LatLng(51.169392, 71.449074),
    'nur-sultan': LatLng(51.169392, 71.449074),
    'шымкент': LatLng(42.341667, 69.5901),
    'shymkent': LatLng(42.341667, 69.5901),
    'москва': LatLng(55.7558, 37.6173),
    'moscow': LatLng(55.7558, 37.6173),
    'санкт-петербург': LatLng(59.9343, 30.3351),
    'spb': LatLng(59.9343, 30.3351),
  };
  return map[key];
}
