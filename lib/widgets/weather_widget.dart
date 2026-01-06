import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  String _temperature = '--';
  String _condition = 'Loading...';
  String _location = '';
  IconData _weatherIcon = Icons.wb_sunny;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      // Get location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _error = 'Location permission denied';
              _isLoading = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _error = 'Location permission denied forever';
            _isLoading = false;
          });
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      // Fetch weather from Open-Meteo (free, no API key required)
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&current=temperature_2m,weather_code&temperature_unit=fahrenheit&timezone=auto',
      );

      final weatherResponse = await http.get(weatherUrl);
      if (weatherResponse.statusCode == 200) {
        final weatherData = json.decode(weatherResponse.body);
        final temp = weatherData['current']['temperature_2m'];
        final weatherCode = weatherData['current']['weather_code'];

        // Get location name using reverse geocoding (Open-Meteo geocoding API)
        final geocodeUrl = Uri.parse(
          'https://geocoding-api.open-meteo.com/v1/search?latitude=${position.latitude}&longitude=${position.longitude}&count=1&language=en&format=json',
        );

        String locationName = 'Current Location';
        try {
          final geocodeResponse = await http.get(geocodeUrl);
          if (geocodeResponse.statusCode == 200) {
            final geocodeData = json.decode(geocodeResponse.body);
            if (geocodeData['results'] != null && geocodeData['results'].isNotEmpty) {
              final result = geocodeData['results'][0];
              locationName = result['name'] ?? locationName;
            }
          }
        } catch (e) {
          // Use default location name if geocoding fails
        }

        if (mounted) {
          setState(() {
            _temperature = '${temp.round()}°F';
            _location = locationName;
            _condition = _getWeatherCondition(weatherCode);
            _weatherIcon = _getWeatherIcon(weatherCode);
            _isLoading = false;
            _error = null;
          });
        }
      } else {
        throw Exception('Failed to load weather');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to fetch weather';
          _isLoading = false;
        });
      }
    }
  }

  String _getWeatherCondition(int code) {
    // WMO Weather interpretation codes
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Partly Cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 57) return 'Drizzle';
    if (code <= 67) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Showers';
    if (code <= 86) return 'Snow Showers';
    return 'Thunderstorm';
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code <= 3) return Icons.wb_cloudy;
    if (code <= 48) return Icons.cloud;
    if (code <= 57) return Icons.grain;
    if (code <= 67) return Icons.water_drop;
    if (code <= 77) return Icons.ac_unit;
    if (code <= 82) return Icons.shower;
    if (code <= 86) return Icons.ac_unit;
    return Icons.thunderstorm;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade300, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isLoading
          ? const SizedBox(
              width: 200,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Loading weather...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? InkWell(
                  onTap: _fetchWeather,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.refresh, color: Colors.white, size: 16),
                    ],
                  ),
                )
              : InkWell(
                  onTap: _fetchWeather,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_weatherIcon, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _temperature,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _condition,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      if (_location.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, color: Colors.white, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                _location,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
