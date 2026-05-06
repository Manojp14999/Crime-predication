import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'map_screen.dart';
import 'predict_screen.dart';
import 'alert_screen.dart';

const List<String> kAreas = [
  'Mysuru City', 'Bannur', 'Nanjangud', 'Hunsur',
  'T Narasipura', 'KRS', 'Periyapatna', 'HD Kote', 'Saragur',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedArea = 'Mysuru City';
  Map<String, dynamic> _analytics = {};
  bool _loading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedArea();
    _fetchData();
  }

  Future<void> _loadSavedArea() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _selectedArea = prefs.getString('selected_area') ?? 'Mysuru City');
  }

  Future<void> _saveArea(String area) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_area', area);
    await NotificationService.subscribeToArea(area);
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getAnalytics();
      setState(() { _analytics = data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _trainModel() async {
    setState(() => _loading = true);
    try {
      await ApiService.trainModel();
      await _fetchData();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Train failed: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _DashboardTab(
        analytics: _analytics,
        loading: _loading,
        selectedArea: _selectedArea,
        onAreaChanged: (area) {
          setState(() => _selectedArea = area);
          _saveArea(area);
        },
        onRefresh: _fetchData,
        onTrain: _trainModel,
      ),
      const MapScreen(),
      const PredictScreen(),
      const AlertScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1A1D2E),
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.psychology), label: 'Predict'),
          NavigationDestination(icon: Icon(Icons.notifications_active), label: 'Alerts'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final Map<String, dynamic> analytics;
  final bool loading;
  final String selectedArea;
  final ValueChanged<String> onAreaChanged;
  final VoidCallback onRefresh;
  final VoidCallback onTrain;

  const _DashboardTab({
    required this.analytics,
    required this.loading,
    required this.selectedArea,
    required this.onAreaChanged,
    required this.onRefresh,
    required this.onTrain,
  });

  @override
  Widget build(BuildContext context) {
    final areaData = analytics['crime_by_area'] as Map? ?? {};
    final crimeTypes = analytics['crime_by_type'] as Map? ?? {};
    final riskDist = analytics['risk_distribution'] as Map? ?? {};
    final areaCount = areaData[selectedArea] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D2E),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CrimeWatch Mysuru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Real-time Crime Intelligence', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: onRefresh),
          IconButton(icon: const Icon(Icons.model_training), onPressed: onTrain, tooltip: 'Train Model'),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : analytics.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.model_training, size: 64, color: Color(0xFF6366F1)),
                        const SizedBox(height: 16),
                        const Text('No data yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Tap Train Model to generate data and train the ML models.',
                            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: onTrain,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Train Model'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
              onRefresh: () async => onRefresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Area selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1D2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6366F1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedArea,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1A1D2E),
                          icon: const Icon(Icons.location_on, color: Color(0xFF6366F1)),
                          items: kAreas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                          onChanged: (v) { if (v != null) onAreaChanged(v); },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // KPI cards
                    Row(children: [
                      _KpiCard(label: 'Total Records', value: '${analytics['total_records'] ?? 0}', color: const Color(0xFF6366F1), icon: Icons.list_alt),
                      const SizedBox(width: 12),
                      _KpiCard(label: 'Your Area', value: '$areaCount crimes', color: const Color(0xFFEF4444), icon: Icons.location_city),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      _KpiCard(label: 'Top Crime', value: '${analytics['top_crime'] ?? 'N/A'}', color: const Color(0xFFF59E0B), icon: Icons.warning),
                      const SizedBox(width: 12),
                      _KpiCard(label: 'Top Area', value: '${analytics['top_area'] ?? 'N/A'}', color: const Color(0xFF10B981), icon: Icons.place),
                    ]),
                    const SizedBox(height: 20),

                    // Crime by type
                    if (crimeTypes.isNotEmpty) ...[
                      const Text('Crime Type Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ...crimeTypes.entries.map((e) => _BarRow(
                        label: e.key,
                        value: e.value as int,
                        max: (crimeTypes.values.reduce((a, b) => (a as int) > (b as int) ? a : b)) as int,
                        color: const Color(0xFF6366F1),
                      )),
                      const SizedBox(height: 20),
                    ],

                    // Risk distribution
                    if (riskDist.isNotEmpty) ...[
                      const Text('Risk Level Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(children: [
                        _RiskChip(label: 'High', count: riskDist['High'] ?? 0, color: const Color(0xFFEF4444)),
                        const SizedBox(width: 8),
                        _RiskChip(label: 'Medium', count: riskDist['Medium'] ?? 0, color: const Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        _RiskChip(label: 'Low', count: riskDist['Low'] ?? 0, color: const Color(0xFF10B981)),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _KpiCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final int value, max;
  final Color color;
  const _BarRow({required this.label, required this.value, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? value / max : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: const Color(0xFF2A2D3E),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$value', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
    );
  }
}

class _RiskChip extends StatelessWidget {
  final String label;
  final dynamic count;
  final Color color;
  const _RiskChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(children: [
          Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ]),
      ),
    );
  }
}
