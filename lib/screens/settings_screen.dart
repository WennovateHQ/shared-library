import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/profile_service.dart';
import '../utils/logging_service.dart';
import '../widgets/loading_overlay.dart';

class SettingsScreen extends StatefulWidget {
  final String appType; // 'farmer', 'consumer', or 'driver'
  final Color? primaryColor;

  const SettingsScreen({
    super.key,
    required this.appType,
    this.primaryColor,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ProfileService _profileService = ProfileService();
  final LoggingService _logger = LoggingService('SettingsScreen');
  
  bool _isLoading = false;
  
  // Notification settings
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  
  // App settings
  String _temperatureUnit = 'Celsius';
  String _distanceUnit = 'Kilometers';
  bool _darkMode = false;
  bool _saveDataMode = false;
  
  // App-specific settings
  Map<String, dynamic> _appSpecificSettings = {};
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _logger.debug('Loading user settings');
      
      // Load notification preferences
      Map<String, bool> notificationPrefs;
      try {
        notificationPrefs = await _profileService.getNotificationPreferences();
      } catch (e) {
        _logger.error('Error loading notification preferences: $e');
        notificationPrefs = {
          'email': true,
          'push': true,
          'sms': false,
        };
      }
      
      // Load general settings
      Map<String, dynamic> settings;
      try {
        settings = await _profileService.getSettings();
      } catch (e) {
        _logger.error('Error loading settings: $e');
        settings = {
          'temperatureUnit': 'Celsius',
          'distanceUnit': 'Kilometers',
          'darkMode': false,
          'saveDataMode': false,
        };
      }
      
      // Load app-specific settings based on app type
      Map<String, dynamic> appSpecificSettings = {};
      
      if (widget.appType == 'farmer') {
        appSpecificSettings = {
          'automaticInventoryAlerts': settings['automaticInventoryAlerts'] ?? true,
          'defaultProductVisibility': settings['defaultProductVisibility'] ?? 'public',
          'autoAcceptOrders': settings['autoAcceptOrders'] ?? false,
        };
      } else if (widget.appType == 'consumer') {
        appSpecificSettings = {
          'saveRecentSearches': settings['saveRecentSearches'] ?? true,
          'preferOrganicProducts': settings['preferOrganicProducts'] ?? false,
          'showNutritionInfo': settings['showNutritionInfo'] ?? true,
        };
      } else if (widget.appType == 'driver') {
        appSpecificSettings = {
          'automaticDeliveryUpdates': settings['automaticDeliveryUpdates'] ?? true,
          'navigationType': settings['navigationType'] ?? 'in-app',
          'audioAlerts': settings['audioAlerts'] ?? true,
        };
      }
      
      // Get theme preference from device settings
      final prefs = await SharedPreferences.getInstance();
      final darkMode = prefs.getBool('darkMode') ?? false;
      
      if (mounted) {
        setState(() {
          _emailNotifications = notificationPrefs['email'] ?? true;
          _pushNotifications = notificationPrefs['push'] ?? true;
          _smsNotifications = notificationPrefs['sms'] ?? false;
          
          _temperatureUnit = settings['temperatureUnit'] ?? 'Celsius';
          _distanceUnit = settings['distanceUnit'] ?? 'Kilometers';
          _darkMode = darkMode;
          _saveDataMode = settings['saveDataMode'] ?? false;
          
          _appSpecificSettings = appSpecificSettings;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.error('Error loading settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load settings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _logger.debug('Saving user settings');
      
      // Save notification preferences
      final notificationPrefs = {
        'email': _emailNotifications,
        'push': _pushNotifications,
        'sms': _smsNotifications,
      };
      
      await _profileService.updateNotificationPreferences(notificationPrefs);
      
      // Save general settings
      final settings = {
        'temperatureUnit': _temperatureUnit,
        'distanceUnit': _distanceUnit,
        'saveDataMode': _saveDataMode,
        ..._appSpecificSettings,
      };
      
      await _profileService.updateSettings(settings);
      
      // Save theme preference locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkMode', _darkMode);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.error('Error saving settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? Theme.of(context).primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Section
              _buildSectionHeader('Notifications'),
              
              SwitchListTile(
                title: const Text('Email Notifications'),
                subtitle: const Text('Receive updates and alerts via email'),
                value: _emailNotifications,
                onChanged: (value) {
                  setState(() {
                    _emailNotifications = value;
                  });
                },
              ),
              
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive real-time alerts on your device'),
                value: _pushNotifications,
                onChanged: (value) {
                  setState(() {
                    _pushNotifications = value;
                  });
                },
              ),
              
              SwitchListTile(
                title: const Text('SMS Notifications'),
                subtitle: const Text('Receive text messages for important updates'),
                value: _smsNotifications,
                onChanged: (value) {
                  setState(() {
                    _smsNotifications = value;
                  });
                },
              ),
              
              // App Settings Section
              _buildSectionHeader('App Settings'),
              
              ListTile(
                title: const Text('Temperature Unit'),
                subtitle: Text(_temperatureUnit),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('Temperature Unit'),
                      children: [
                        RadioListTile<String>(
                          title: const Text('Celsius (°C)'),
                          value: 'Celsius',
                          groupValue: _temperatureUnit,
                          onChanged: (value) {
                            setState(() {
                              _temperatureUnit = value!;
                              Navigator.pop(context);
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Fahrenheit (°F)'),
                          value: 'Fahrenheit',
                          groupValue: _temperatureUnit,
                          onChanged: (value) {
                            setState(() {
                              _temperatureUnit = value!;
                              Navigator.pop(context);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              ListTile(
                title: const Text('Distance Unit'),
                subtitle: Text(_distanceUnit),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('Distance Unit'),
                      children: [
                        RadioListTile<String>(
                          title: const Text('Kilometers (km)'),
                          value: 'Kilometers',
                          groupValue: _distanceUnit,
                          onChanged: (value) {
                            setState(() {
                              _distanceUnit = value!;
                              Navigator.pop(context);
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Miles (mi)'),
                          value: 'Miles',
                          groupValue: _distanceUnit,
                          onChanged: (value) {
                            setState(() {
                              _distanceUnit = value!;
                              Navigator.pop(context);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme throughout the app'),
                value: _darkMode,
                onChanged: (value) {
                  setState(() {
                    _darkMode = value;
                  });
                },
              ),
              
              SwitchListTile(
                title: const Text('Data Saver Mode'),
                subtitle: const Text('Reduce data usage by loading lower quality images'),
                value: _saveDataMode,
                onChanged: (value) {
                  setState(() {
                    _saveDataMode = value;
                  });
                },
              ),
              
              // App-specific settings
              if (widget.appType == 'farmer') ...[
                _buildSectionHeader('Farmer Settings'),
                
                SwitchListTile(
                  title: const Text('Automatic Inventory Alerts'),
                  subtitle: const Text('Get notified when inventory is low'),
                  value: _appSpecificSettings['automaticInventoryAlerts'] ?? true,
                  onChanged: (value) {
                    setState(() {
                      _appSpecificSettings['automaticInventoryAlerts'] = value;
                    });
                  },
                ),
                
                ListTile(
                  title: const Text('Default Product Visibility'),
                  subtitle: Text(_appSpecificSettings['defaultProductVisibility'] ?? 'public'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Default Product Visibility'),
                        children: [
                          RadioListTile<String>(
                            title: const Text('Public'),
                            value: 'public',
                            groupValue: _appSpecificSettings['defaultProductVisibility'],
                            onChanged: (value) {
                              setState(() {
                                _appSpecificSettings['defaultProductVisibility'] = value;
                                Navigator.pop(context);
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Private'),
                            value: 'private',
                            groupValue: _appSpecificSettings['defaultProductVisibility'],
                            onChanged: (value) {
                              setState(() {
                                _appSpecificSettings['defaultProductVisibility'] = value;
                                Navigator.pop(context);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                SwitchListTile(
                  title: const Text('Auto-Accept Orders'),
                  subtitle: const Text('Automatically accept incoming orders'),
                  value: _appSpecificSettings['autoAcceptOrders'] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _appSpecificSettings['autoAcceptOrders'] = value;
                    });
                  },
                ),
              ] else if (widget.appType == 'consumer') ...[
                _buildSectionHeader('Consumer Settings'),
                
                SwitchListTile(
                  title: const Text('Save Recent Searches'),
                  subtitle: const Text('Keep track of your recent product searches'),
                  value: _appSpecificSettings['saveRecentSearches'] ?? true,
                  onChanged: (value) {
                    setState(() {
                      _appSpecificSettings['saveRecentSearches'] = value;
                    });
                  },
                ),
                
                SwitchListTile(
                  title: const Text('Prefer Organic Products'),
                  subtitle: const Text('Prioritize organic products in search results'),
                  value: _appSpecificSettings['preferOrganicProducts'] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _appSpecificSettings['preferOrganicProducts'] = value;
                    });
                  },
                ),
                
                SwitchListTile(
                  title: const Text('Show Nutrition Information'),
                  subtitle: const Text('Display detailed nutrition facts for products'),
                  value: _appSpecificSettings['showNutritionInfo'] ?? true,
                  onChanged: (value) {
                    setState(() {
                      _appSpecificSettings['showNutritionInfo'] = value;
                    });
                  },
                ),
              ] else if (widget.appType == 'driver') ...[
                _buildSectionHeader('Driver Settings'),
                
                SwitchListTile(
                  title: const Text('Automatic Delivery Updates'),
                  subtitle: const Text('Send automatic updates at delivery checkpoints'),
                  value: _appSpecificSettings['automaticDeliveryUpdates'] ?? true,
                  onChanged: (value) {
                    setState(() {
                      _appSpecificSettings['automaticDeliveryUpdates'] = value;
                    });
                  },
                ),
                
                ListTile(
                  title: const Text('Navigation Type'),
                  subtitle: Text(_appSpecificSettings['navigationType'] ?? 'in-app'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Navigation Type'),
                        children: [
                          RadioListTile<String>(
                            title: const Text('In-app Navigation'),
                            value: 'in-app',
                            groupValue: _appSpecificSettings['navigationType'],
                            onChanged: (value) {
                              setState(() {
                                _appSpecificSettings['navigationType'] = value;
                                Navigator.pop(context);
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Google Maps'),
                            value: 'google-maps',
                            groupValue: _appSpecificSettings['navigationType'],
                            onChanged: (value) {
                              setState(() {
                                _appSpecificSettings['navigationType'] = value;
                                Navigator.pop(context);
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Waze'),
                            value: 'waze',
                            groupValue: _appSpecificSettings['navigationType'],
                            onChanged: (value) {
                              setState(() {
                                _appSpecificSettings['navigationType'] = value;
                                Navigator.pop(context);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                SwitchListTile(
                  title: const Text('Audio Alerts'),
                  subtitle: const Text('Play sound when new delivery is available'),
                  value: _appSpecificSettings['audioAlerts'] ?? true,
                  onChanged: (value) {
                    setState(() {
                      _appSpecificSettings['audioAlerts'] = value;
                    });
                  },
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Save button
              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Reset button
              OutlinedButton(
                onPressed: _loadSettings,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Reset to Saved Settings'),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
