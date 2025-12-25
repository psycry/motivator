# Weather Widget Setup Guide

## Overview
A real-time weather widget has been added to the top right of the app bar. It displays current temperature, weather conditions, and location based on your device's GPS.

## Features

### **Display Information**
- **Temperature**: Current temperature in Fahrenheit
- **Weather Condition**: Clear, Cloudy, Rain, Snow, etc.
- **Location**: City/area name based on GPS coordinates
- **Weather Icon**: Dynamic icon matching current conditions
- **Auto-refresh**: Click to manually refresh weather data

### **Visual Design**
- Blue gradient background
- Weather-appropriate icons
- Compact, non-intrusive design
- Fits perfectly in the app bar

## Setup Requirements

### **1. Location Permissions**

The app needs location permission to fetch weather for your area.

#### **Windows**
- Windows will prompt for location permission when you first run the app
- Grant permission when asked

#### **Android**
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### **iOS**
Add to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show local weather</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to show local weather</string>
```

### **2. Internet Connection**
The weather widget requires an active internet connection to fetch weather data.

## How It Works

### **Weather Data Source**
- Uses **Open-Meteo API** (free, no API key required!)
- Provides accurate weather data worldwide
- Updates in real-time

### **Location Detection**
1. Requests device location permission
2. Gets GPS coordinates using `geolocator` package
3. Fetches weather for those coordinates
4. Reverse geocodes to get city/area name

### **Weather Codes**
The widget interprets WMO weather codes:
- **0**: Clear sky ☀️
- **1-3**: Partly cloudy ⛅
- **45-48**: Foggy 🌫️
- **51-67**: Rain 🌧️
- **71-77**: Snow ❄️
- **80-86**: Showers 🌦️
- **95-99**: Thunderstorm ⛈️

## Usage

### **First Launch**
1. App requests location permission
2. Grant permission
3. Weather loads automatically
4. Displays in top right of app bar

### **Manual Refresh**
- Click on the weather widget to refresh
- Useful if weather seems outdated

### **Error Handling**
If weather fails to load:
- Shows error message with retry icon
- Click to retry
- Common issues:
  - Location permission denied
  - No internet connection
  - GPS unavailable

## Technical Details

### **Files Added**
1. `lib/widgets/weather_widget.dart` - Weather widget component
2. `WEATHER_SETUP.md` - This documentation

### **Files Modified**
1. `pubspec.yaml` - Added dependencies:
   - `geolocator: ^10.1.0` - Location services
   - `http: ^1.1.0` - HTTP requests
2. `lib/main.dart` - Added weather widget to app bar

### **Dependencies**
```yaml
geolocator: ^10.1.0  # GPS location
http: ^1.1.0         # API requests
```

### **API Endpoints**
- Weather: `https://api.open-meteo.com/v1/forecast`
- Geocoding: `https://geocoding-api.open-meteo.com/v1/search`

## Customization

### **Change Temperature Unit**
Edit `lib/widgets/weather_widget.dart` line 54:
```dart
// Change from Fahrenheit to Celsius
&temperature_unit=celsius  // instead of fahrenheit
```

Then update line 75:
```dart
_temperature = '${temp.round()}°C';  // instead of °F
```

### **Change Update Frequency**
Add auto-refresh timer in `initState()`:
```dart
Timer.periodic(Duration(minutes: 30), (timer) {
  _fetchWeather();
});
```

### **Change Widget Position**
Move from app bar to anywhere else by changing the widget placement in `main.dart`.

### **Change Colors**
Edit the gradient in `weather_widget.dart` line 136-139:
```dart
gradient: LinearGradient(
  colors: [Colors.blue.shade300, Colors.blue.shade500],
  // Change to your preferred colors
),
```

## Privacy & Data

### **What Data Is Collected**
- GPS coordinates (only used for weather lookup)
- No data is stored or transmitted except to Open-Meteo API

### **Data Usage**
- Location is used only to fetch weather
- No tracking or analytics
- All data stays on your device

### **Open-Meteo Privacy**
- Free, open-source weather API
- No API key required
- No user tracking
- See: https://open-meteo.com/en/terms

## Troubleshooting

### **"Location permission denied"**
- Grant location permission in system settings
- Restart the app

### **"Unable to fetch weather"**
- Check internet connection
- Verify GPS is enabled
- Click to retry

### **Weather not updating**
- Click the widget to manually refresh
- Check if location services are enabled

### **Widget not showing**
- Ensure packages are installed: `flutter pub get`
- Check for compile errors: `flutter analyze`

## Future Enhancements

Potential improvements:
- [ ] Hourly forecast on hover/click
- [ ] Weather alerts
- [ ] Multiple location support
- [ ] Weather-based task suggestions
- [ ] Dark mode support
- [ ] Metric/Imperial toggle

## Credits

- **Weather Data**: Open-Meteo (https://open-meteo.com)
- **Location Services**: Geolocator package
- **Icons**: Material Design Icons
