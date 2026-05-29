import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/sensor_monitor_screen.dart';

void main() {
  runApp(const IoTSensorMonitorApp());
}

class IoTSensorMonitorApp extends StatelessWidget {
  const IoTSensorMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF0F766E);
    final textTheme = GoogleFonts.montserratTextTheme();

    return MaterialApp(
      title: 'IoT Sensor Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FA),
        textTheme: textTheme,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFFF4F7FA),
          foregroundColor: Color(0xFF111827),
          titleTextStyle: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w800,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: const Color(0x1A0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE6EAF0)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      home: const SensorMonitorScreen(),
    );
  }
}
