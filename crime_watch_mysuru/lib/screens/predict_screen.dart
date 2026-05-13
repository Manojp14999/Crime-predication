import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  String _area = 'Mysuru City';
  String _weather = 'Clear';
  int _isFestival = 0;
  DateTime _dateTime = DateTime.now();
  Map<String, dynamic>? _result;
  bool _loading = false;
  String? _error;

  Future<void> _predict() async {
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final result = await ApiService.predict(
        area: _area,
        hour: _dateTime.hour,
        day: DateFormat('EEEE').format(_dateTime),
        month: DateFormat('MMMM').format(_dateTime),
        weather: _weather,
        populationDensity: 5000,
        isWeekend: _dateTime.weekday >= 6 ? 1 : 0,
        isFestival: _isFestival,
      );
      setState(() { _result = result; _loading = false; });
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() { _error = msg; _loading = false; });
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dateTime));
    if (time == null) return;
    setState(() => _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Color _riskColor(String? risk) {
    switch (risk) {
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
        title: const Text('Crime Risk Predictor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _card(children: [
            const Text('Select Area', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _area,
              dropdownColor: const Color(0xFF1A1D2E),
              decoration: _inputDecoration('Area'),
              items: kAreas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
              onChanged: (v) { if (v != null) setState(() => _area = v); },
            ),
            const SizedBox(height: 12),
            const Text('Date & Time', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade700),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today, size: 18, color: Color(0xFF6366F1)),
                  const SizedBox(width: 10),
                  Text(DateFormat('EEE, dd MMM yyyy  HH:mm').format(_dateTime)),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _weather,
              dropdownColor: const Color(0xFF1A1D2E),
              decoration: _inputDecoration('Weather'),
              items: ['Clear', 'Cloudy', 'Rainy', 'Foggy', 'Stormy']
                  .map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
              onChanged: (v) { if (v != null) setState(() => _weather = v); },
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Text('Festival Day?'),
              const Spacer(),
              Switch(
                value: _isFestival == 1,
                activeColor: const Color(0xFF6366F1),
                onChanged: (v) => setState(() => _isFestival = v ? 1 : 0),
              ),
            ]),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _loading ? null : _predict,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.psychology),
              label: Text(_loading ? 'Predicting...' : 'Predict Crime Risk'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
              ),
              child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444))),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            _card(children: [
              const Text('Prediction Result', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _resultTile('Crime Type', _result!['crime_type'], const Color(0xFF6366F1))),
                const SizedBox(width: 12),
                Expanded(child: _resultTile('Risk Level', _result!['risk_level'], _riskColor(_result!['risk_level']))),
              ]),
              const SizedBox(height: 12),
              _confidenceBar('Crime Confidence', (_result!['crime_confidence'] as num).toDouble(), const Color(0xFF6366F1)),
              const SizedBox(height: 8),
              _confidenceBar('Risk Confidence', (_result!['risk_confidence'] as num).toDouble(), _riskColor(_result!['risk_level'])),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1D2E),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade800),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _resultTile(String label, String value, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Column(children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    ]),
  );

  Widget _confidenceBar(String label, double value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text('${value.toStringAsFixed(1)}%', style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: value / 100,
          backgroundColor: const Color(0xFF2A2D3E),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 8,
        ),
      ),
    ],
  );

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade700),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}
