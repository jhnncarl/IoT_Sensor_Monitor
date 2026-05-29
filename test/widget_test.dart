import 'package:flutter_test/flutter_test.dart';

import 'package:iot_temperature_humidity_app/main.dart';

void main() {
  testWidgets('shows IoT Sensor Monitor title', (WidgetTester tester) async {
    await tester.pumpWidget(const IoTSensorMonitorApp());

    expect(find.text('IoT Sensor Monitor'), findsOneWidget);
    expect(find.text('Latest Reading'), findsNothing);
  });
}
