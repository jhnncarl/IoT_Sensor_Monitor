# IoT Temperature Humidity App

A Flutter mobile application for viewing the latest temperature and humidity
reading from a Supabase table through the Supabase REST API.

## Features

- Fetches the latest sensor reading when the app starts.
- Supports manual refresh with a button or pull-to-refresh.
- Displays temperature, humidity, and timestamp in a clean responsive layout.
- Uses `http` for REST API calls, `intl` for timestamp formatting, and
  `google_fonts` for Montserrat typography.
- Separates app code into `models`, `services`, `screens`, and `widgets`.

## Supabase Setup

The app is currently in demo mode so you can view and improve the UI without a
Supabase connection.

When you are ready to connect the real backend, update this flag in
`lib/services/supabase_service.dart`:

```dart
static const bool useDemoData = false;
```

Update these placeholder values in `lib/services/supabase_service.dart`:

```dart
static const String supabaseUrl = 'https://your-project-id.supabase.co';
static const String supabaseApiKey = 'YOUR_SUPABASE_ANON_API_KEY';
static const String tableName = 'sensor_readings';
```

Expected table columns:

```text
temperature
humidity
timestamp
```

Example JSON response from Supabase:

```json
[
  {
    "temperature": 28.4,
    "humidity": 64.2,
    "timestamp": "2026-05-28T12:40:00Z"
  }
]
```

The service requests the newest row using:

```text
select=temperature,humidity,timestamp
order=timestamp.desc
limit=1
```

## Run

```powershell
flutter pub get
flutter run
```
