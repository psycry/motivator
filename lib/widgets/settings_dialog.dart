import 'package:flutter/material.dart';
import '../models/user_preferences.dart';

class SettingsDialog extends StatefulWidget {
  final UserPreferences initialPreferences;
  final Function(UserPreferences) onSave;

  const SettingsDialog({
    super.key,
    required this.initialPreferences,
    required this.onSave,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late bool _notificationsEnabled;
  late int _notificationMinutesBefore;
  late TextEditingController _geminiApiKeyController;
  bool _showApiKey = false;

  // Predefined options for notification timing
  final List<int> _minuteOptions = [1, 5, 10, 15, 30, 60];

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = widget.initialPreferences.notificationsEnabled;
    _notificationMinutesBefore = widget.initialPreferences.notificationMinutesBefore;
    _geminiApiKeyController = TextEditingController(
      text: widget.initialPreferences.geminiApiKey ?? '',
    );
  }

  @override
  void dispose() {
    _geminiApiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings, color: Colors.blue),
          SizedBox(width: 8),
          Text('Settings'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Notifications Section
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Enable/Disable Notifications
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive reminders before tasks start'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              activeTrackColor: Colors.blue.shade200,
              activeThumbColor: Colors.blue,
            ),
            
            const SizedBox(height: 16),
            
            // Notification Timing
            if (_notificationsEnabled) ...[
              const Text(
                'Notify me before task starts:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              
              // Quick select buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _minuteOptions.map((minutes) {
                  final isSelected = _notificationMinutesBefore == minutes;
                  return ChoiceChip(
                    label: Text(_formatMinutes(minutes)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _notificationMinutesBefore = minutes;
                        });
                      }
                    },
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Custom slider for fine-tuning
              Row(
                children: [
                  const Text('Custom: '),
                  Expanded(
                    child: Slider(
                      value: _notificationMinutesBefore.toDouble(),
                      min: 1,
                      max: 60,
                      divisions: 59,
                      label: _formatMinutes(_notificationMinutesBefore),
                      onChanged: (value) {
                        setState(() {
                          _notificationMinutesBefore = value.round();
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      _formatMinutes(_notificationMinutesBefore),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Info message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _notificationsEnabled
                          ? 'You\'ll receive notifications $_notificationMinutesBefore minute${_notificationMinutesBefore != 1 ? 's' : ''} before each task starts.'
                          : 'Notifications are disabled. Enable them to receive task reminders.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // Gemini AI Section
            const Text(
              'Gemini AI Chat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _geminiApiKeyController,
              obscureText: !_showApiKey,
              decoration: InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'Enter your Gemini API key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _showApiKey = !_showApiKey;
                    });
                  },
                ),
                helperText: 'Required for AI chat feature',
                helperMaxLines: 2,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // API Key info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.key, color: Colors.purple.shade700, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Get your free API key',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Visit: makersuite.google.com/app/apikey',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your API key is stored securely with your account.',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.purple.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            final newPreferences = UserPreferences(
              notificationsEnabled: _notificationsEnabled,
              notificationMinutesBefore: _notificationMinutesBefore,
              geminiApiKey: _geminiApiKeyController.text.trim().isEmpty 
                  ? null 
                  : _geminiApiKeyController.text.trim(),
            );
            widget.onSave(newPreferences);
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.save),
          label: const Text('Save'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes min${minutes != 1 ? 's' : ''}';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours hour${hours != 1 ? 's' : ''}';
      } else {
        return '$hours hr${hours != 1 ? 's' : ''} $remainingMinutes min';
      }
    }
  }
}
