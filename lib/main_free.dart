import 'package:flutter/material.dart';
import 'config/flavor_config.dart';
import 'main.dart' as app;

void main() {
  // Initialize flavor configuration for free version
  FlavorConfig.initialize(flavor: 'free');
  
  // Run the main app
  app.main();
}
