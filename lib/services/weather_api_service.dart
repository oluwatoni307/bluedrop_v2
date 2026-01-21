// lib/services/weather_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  final http.Client _client = http.Client();

  // Simple in-memory cache
  String? _cachedCity;
  double? _cachedTemp;
  int? _cachedHumidity;
  DateTime? _cachedAt;

  Future<Map<String, dynamic>> getWeather(String city) async {
    // Try API first
    try {
      final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
      if (apiKey != null && apiKey.isNotEmpty) {
        final url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$city,NG&appid=$apiKey&units=metric',
        );

        final response = await _client.get(url).timeout(Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final temp = (data['main']['temp'] as num).toDouble();
          final humidity = data['main']['humidity'] as int;

          // Cache it
          _cachedCity = city;
          _cachedTemp = temp;
          _cachedHumidity = humidity;
          _cachedAt = DateTime.now();

          return {'temp': temp, 'humidity': humidity, 'source': 'api'};
        }
      }
    } catch (e) {
      print('Weather API failed: $e');
    }

    // Use cache if available (< 6 hours old)
    if (_cachedCity == city &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < Duration(hours: 6)) {
      return {
        'temp': _cachedTemp!,
        'humidity': _cachedHumidity!,
        'source': 'cache',
      };
    }

    // Fall back to defaults
    return _getDefaults(city);
  }

  Map<String, dynamic> _getDefaults(String city) {
    final month = DateTime.now().month;
    final isDrySeason = month >= 11 || month <= 3;

    final defaults = {
      'Lagos': {'temp': 30.0, 'humidityDry': 50, 'humidityRainy': 80},
      'Abuja': {'temp': 28.0, 'humidityDry': 45, 'humidityRainy': 75},
      'Port Harcourt': {'temp': 31.0, 'humidityDry': 55, 'humidityRainy': 85},
      'Kano': {'temp': 29.0, 'humidityDry': 35, 'humidityRainy': 65},
      'Ibadan': {'temp': 29.5, 'humidityDry': 48, 'humidityRainy': 78},
    };

    final cityData = defaults[city] ?? defaults['Lagos']!;

    return {
      'temp': cityData['temp']!,
      'humidity': isDrySeason
          ? cityData['humidityDry']!
          : cityData['humidityRainy']!,
      'source': 'default',
    };
  }

  void clearCache() {
    _cachedCity = null;
    _cachedTemp = null;
    _cachedHumidity = null;
    _cachedAt = null;
  }
}
