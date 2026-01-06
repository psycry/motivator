@echo off
REM Build script for Motivator Paid version

echo ========================================
echo Building Motivator PAID Version
echo ========================================
echo.

set BUILD_TYPE=%1
if "%BUILD_TYPE%"=="" set BUILD_TYPE=apk

echo Build type: %BUILD_TYPE%
echo.

if "%BUILD_TYPE%"=="apk" (
    echo Building APK...
    flutter build apk --flavor paid -t lib/main_paid.dart --release
    echo.
    echo APK built successfully!
    echo Location: build\app\outputs\flutter-apk\app-paid-release.apk
) else if "%BUILD_TYPE%"=="appbundle" (
    echo Building App Bundle for Google Play...
    flutter build appbundle --flavor paid -t lib/main_paid.dart --release
    echo.
    echo App Bundle built successfully!
    echo Location: build\app\outputs\bundle\paidRelease\app-paid-release.aab
) else if "%BUILD_TYPE%"=="debug" (
    echo Running in debug mode...
    flutter run --flavor paid -t lib/main_paid.dart
) else (
    echo Invalid build type: %BUILD_TYPE%
    echo Usage: build_paid.bat [apk^|appbundle^|debug]
    exit /b 1
)

echo.
echo ========================================
echo Build Complete!
echo ========================================
