import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  String _alertArea = 'Mysuru City';
  String _severity = 'High';
  final _msgController = TextEditingController();
  bool _sending = false;
  Set<String> _subscribedAreas = {};

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _subscribedAreas = Set.from(prefs.getStringList('subscribed_areas') ?? ['Mysuru City']));
  }

  Future<void> _toggleSubscription(String area) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_subscribedAreas.contains(area)) {
        _subscribedAreas.remove(area);
        NotificationService.unsubscribeFromArea(area);
      } else {
        _subscribedAreas.add(area);
        NotificationService.subscribeToArea(area);
      }
    });
    await prefs.setStringList('subscribed_areas', _subscribedAreas.toList());
  }

  Future<void> _sendAlert() async {
    if (_msgController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an alert message')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await ApiService.sendAlert(
        area: _alertArea,
        message: _msgController.text.trim(),
        severity: _severity,
      );
      // Also show local notification immediately
      await NotificationService.showLocalAlert(
        title: '🚨 $_severity Alert — $_alertArea',
        body: _msgController.text.trim(),
      );
      if (mounted) {
        _msgController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Alert sent successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
    setState(() => _sending = false);
  }

  Color _severityColor(String s) {
    switch (s) {
      case 'High':   return const Color(0xFFEF4444);
      case 'Medium': return const Color(0xFFF59E0B);
      default:       return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D2E),
        title: const Text('Alerts & Notifications'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Send Alert Card
          _sectionCard(
            title: '🚨 Send Emergency Alert',
            children: [
              DropdownButtonFormField<String>(
                value: _alertArea,
                dropdownColor: const Color(0xFF1A1D2E),
                decoration: _inputDeco('Select Area'),
                items: kAreas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (v) { if (v != null) setState(() => _alertArea = v); },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _severity,
                dropdownColor: const Color(0xFF1A1D2E),
                decoration: _inputDeco('Severity'),
                items: ['High', 'Medium', 'Low'].map((s) => DropdownMenuItem(
                  value: s,
                  child: Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: _severityColor(s), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(s),
                  ]),
                )).toList(),
                onChanged: (v) { if (v != null) setState(() => _severity = v); },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _msgController,
                maxLines: 3,
                decoration: _inputDeco('Alert message (e.g. Robbery reported near market)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _sending ? null : _sendAlert,
                  icon: _sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  label: Text(_sending ? 'Sending...' : 'Send Alert'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Notification subscriptions
          _sectionCard(
            title: '🔔 Area Notification Subscriptions',
            children: [
              const Text('Get push notifications for crimes in these areas:', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kAreas.map((area) {
                  final subscribed = _subscribedAreas.contains(area);
                  return FilterChip(
                    label: Text(area, style: TextStyle(fontSize: 12, color: subscribed ? Colors.white : Colors.grey)),
                    selected: subscribed,
                    selectedColor: const Color(0xFF6366F1).withOpacity(0.3),
                    backgroundColor: const Color(0xFF2A2D3E),
                    checkmarkColor: const Color(0xFF6366F1),
                    side: BorderSide(color: subscribed ? const Color(0xFF6366F1) : Colors.grey.shade700),
                    onSelected: (_) => _toggleSubscription(area),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Info card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
            ),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, color: Color(0xFF6366F1), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You will receive push notifications for crime alerts in your subscribed areas even when the app is closed.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1D2E),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade800),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 14),
      ...children,
    ]),
  );

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade700),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}
