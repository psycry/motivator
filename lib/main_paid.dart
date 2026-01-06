import 'package:flutter/material.dart';
import 'config/flavor_config.dart';
import 'main.dart' as app;

void main() {
  // Initialize flavor configuration for paid version
  FlavorConfig.initialize(flavor: 'paid');
  
  // Run the main app
  app.main();
}
