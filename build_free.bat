@echo off
REM Build script for Motivator Free version

echo ========================================
echo Building Motivator FREE Version
echo ========================================
echo.

set BUILD_TYPE=%1
if "%BUILD_TYPE%"=="" set BUILD_TYPE=apk

echo Build type: %BUILD_TYPE%
echo.

if "%BUILD_TYPE%"=="apk" (
    echo Building APK...
    flutter build apk --flavor free -t lib/main_free.dart --release
    echo.
    echo APK built successfully!
    echo Location: build\app\outputs\flutter-apk\app-free-release.apk
) else if "%BUILD_TYPE%"=="appbundle" (
    echo Building App Bundle for Google Play...
    flutter build appbundle --flavor free -t lib/main_free.dart --release
    echo.
    echo App Bundle built successfully!
    echo Location: build\app\outputs\bundle\freeRelease\app-free-release.aab
) else if "%BUILD_TYPE%"=="debug" (
    echo Running in debug mode...
    flutter run --flavor free -t lib/main_free.dart
) else (
    echo Invalid build type: %BUILD_TYPE%
    echo Usage: build_free.bat [apk^|appbundle^|debug]
    exit /b 1
)

echo.
echo ========================================
echo Build Complete!
echo ========================================
