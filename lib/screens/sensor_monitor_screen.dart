import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sensor_reading.dart';
import '../services/supabase_service.dart';
import '../widgets/sensor_card.dart';

class SensorMonitorScreen extends StatefulWidget {
  const SensorMonitorScreen({super.key});

  @override
  State<SensorMonitorScreen> createState() => _SensorMonitorScreenState();
}

class _SensorMonitorScreenState extends State<SensorMonitorScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy - h:mm a');

  SensorReading? _latestReading;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLatestReading();
  }

  @override
  void dispose() {
    _supabaseService.dispose();
    super.dispose();
  }

  Future<void> _fetchLatestReading() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reading = await _supabaseService.fetchLatestReading();
      if (!mounted) {
        return;
      }

      setState(() {
        _latestReading = reading;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Unable to load sensor data. Check your Supabase URL, API key, table name, and network connection.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IoT Sensor Monitor')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchLatestReading,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 36,
                  ),
                  child: _buildContent(isWide),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isWide) {
    if (_isLoading && _latestReading == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _latestReading == null) {
      return _ErrorState(
        message: _errorMessage!,
        onRetry: _fetchLatestReading,
        isLoading: _isLoading,
      );
    }

    final reading = _latestReading;
    if (reading == null) {
      return _ErrorState(
        message: 'No sensor readings are available yet.',
        onRetry: _fetchLatestReading,
        isLoading: _isLoading,
      );
    }

    final cards = [
      SizedBox(
        height: 190,
        child: SensorCard(
          title: 'Temperature',
          value: reading.temperature.toStringAsFixed(1),
          unit: '°C',
          caption: 'Ambient room temperature',
          icon: Icons.thermostat_rounded,
          accentColor: const Color(0xFFEA580C),
        ),
      ),
      SizedBox(
        height: 190,
        child: SensorCard(
          title: 'Humidity',
          value: reading.humidity.toStringAsFixed(1),
          unit: '%',
          caption: 'Relative humidity level',
          icon: Icons.water_drop_rounded,
          accentColor: const Color(0xFF0891B2),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusHeader(
          timestamp: _dateFormat.format(reading.timestamp),
          isLoading: _isLoading,
          onRefresh: _fetchLatestReading,
        ),
        const SizedBox(height: 20),
        if (_errorMessage != null) ...[
          _InlineError(message: _errorMessage!),
          const SizedBox(height: 14),
        ],
        const _SectionLabel(),
        const SizedBox(height: 12),
        if (isWide)
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 14),
              Expanded(child: cards[1]),
            ],
          )
        else
          Column(
            children: [
              cards[0],
              const SizedBox(height: 14),
              cards[1],
            ],
          ),
        const SizedBox(height: 16),
        _DataSourcePanel(
          source: SupabaseService.useDemoData
              ? 'Demo sensor feed'
              : 'Supabase REST API',
          status: SupabaseService.useDemoData
              ? 'Offline preview'
              : 'Connected backend',
        ),
      ],
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.timestamp,
    required this.isLoading,
    required this.onRefresh,
  });

  final String timestamp;
  final bool isLoading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260F172A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _ConnectionChip(),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: isLoading ? null : onRefresh,
                tooltip: 'Refresh readings',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                  disabledForegroundColor: Colors.white70,
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Latest Reading',
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 18,
                color: Color(0xFFB8F3EA),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  timestamp,
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFE6FFFA),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectionChip extends StatelessWidget {
  const _ConnectionChip();

  @override
  Widget build(BuildContext context) {
    final label = SupabaseService.useDemoData ? 'Demo Mode' : 'Live Data';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF34D399),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            'Sensor Metrics',
            style: textTheme.titleMedium?.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          'Auto updated',
          style: textTheme.labelMedium?.copyWith(
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DataSourcePanel extends StatelessWidget {
  const _DataSourcePanel({
    required this.source,
    required this.status,
  });

  final String source;
  final String status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              color: Color(0xFF0F766E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source,
                  style: textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  status,
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.isLoading,
  });

  final String message;
  final VoidCallback onRetry;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 42,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF374151),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: isLoading ? null : onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB91C1C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF7F1D1D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
