import 'package:flutter/material.dart';
import '../../models/predictive_health_score.dart';
import '../../models/predictive_alert.dart';
import '../../services/predictive_health_engine.dart';
import 'dart:async';

class PredictiveHealthDashboardScreen extends StatefulWidget {
  const PredictiveHealthDashboardScreen({super.key});

  @override
  State<PredictiveHealthDashboardScreen> createState() => _PredictiveHealthDashboardScreenState();
}

class _PredictiveHealthDashboardScreenState extends State<PredictiveHealthDashboardScreen> {
  PredictiveHealthScore _currentScore = PredictiveHealthEngine.instance.currentScore;
  List<PredictiveAlert> _activeAlerts = PredictiveHealthEngine.instance.activeAlerts;
  
  StreamSubscription? _scoreSub;
  StreamSubscription? _alertsSub;

  @override
  void initState() {
    super.initState();
    _scoreSub = PredictiveHealthEngine.instance.scoreStream.listen((score) {
      if (mounted) setState(() => _currentScore = score);
    });
    _alertsSub = PredictiveHealthEngine.instance.alertsStream.listen((alerts) {
      if (mounted) setState(() => _activeAlerts = alerts);
    });
  }

  @override
  void dispose() {
    _scoreSub?.cancel();
    _alertsSub?.cancel();
    super.dispose();
  }

  Color _getColorForScore(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _getColorForSeverity(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info: return Colors.blue;
      case AlertSeverity.warning: return Colors.orange;
      case AlertSeverity.critical: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Health'),
        actions: [
          if (_activeAlerts.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.warning_amber_rounded, color: Colors.orange),
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOverallHealthGauge(context),
            const SizedBox(height: 24),
            Text('Subsystem Health', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ..._currentScore.subsystems.values.map((s) => _buildSubsystemBar(context, s)),
            const SizedBox(height: 32),
            Text('Predictive Alerts', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (_activeAlerts.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No predictive alerts. All systems nominal.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              ..._activeAlerts.map((a) => _buildAlertCard(context, a)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallHealthGauge(BuildContext context) {
    final color = _getColorForScore(_currentScore.overallScore);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text('Overall Vehicle Health', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: _currentScore.overallScore / 100.0,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentScore.overallScore.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color),
                    ),
                    Text(
                      '/ 100',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubsystemBar(BuildContext context, SubsystemHealth health) {
    final color = _getColorForScore(health.score);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                health.subsystem.name.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.black87),
              ),
              Text(
                '${health.score.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: health.score / 100.0,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, PredictiveAlert alert) {
    final severityColor = _getColorForSeverity(alert.severity);
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: severityColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: severityColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(alert.description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.build, size: 20, color: severityColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alert.recommendedAction,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: severityColor),
                    ),
                  ),
                ],
              ),
            ),
            if (alert.estimatedTimeToFailure != null) ...[
              const SizedBox(height: 12),
              Text(
                'Est. time to failure: ${alert.estimatedTimeToFailure!.inDays} days',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
