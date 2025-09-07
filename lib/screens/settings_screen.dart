import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_school_assistant/main.dart';
import 'package:smart_school_assistant/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  String _selectedLanguage = 'en';
  String _schoolName = 'Smart School Assistant';
  String _schoolAddress = '';
  String _schoolPhone = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _selectedLanguage = prefs.getString('languageCode') ?? 'en';
      _schoolName = prefs.getString('schoolName') ?? 'Smart School Assistant';
      _schoolAddress = prefs.getString('schoolAddress') ?? '';
      _schoolPhone = prefs.getString('schoolPhone') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
    await prefs.setString('languageCode', _selectedLanguage);
    await prefs.setString('schoolName', _schoolName);
    await prefs.setString('schoolAddress', _schoolAddress);
    await prefs.setString('schoolPhone', _schoolPhone);
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    _saveSettings();

    // Update app theme
    final appState = appKey.currentState;
    if (appState != null) {
      appState.setDarkMode(value);
    }
  }

  void _changeLanguage(String languageCode) {
    setState(() {
      _selectedLanguage = languageCode;
    });
    _saveSettings();

    // Update app locale
    final locale = Locale(languageCode);
    appKey.currentState?.setLocale(locale);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Language changed to ${languageCode.toUpperCase()}')),
    );
  }

  Future<void> _showSchoolNameDialog() async {
    final TextEditingController nameController = TextEditingController(text: _schoolName);
    final TextEditingController addressController = TextEditingController(text: _schoolAddress);
    final TextEditingController phoneController = TextEditingController(text: _schoolPhone);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Configure School Information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'School Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'School Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'School Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                setState(() {
                  _schoolName = nameController.text;
                  _schoolAddress = addressController.text;
                  _schoolPhone = phoneController.text;
                });
                _saveSettings();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('School information updated')),
                );
              },
            ),
          ],
        );
      },
    );
  }


  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Smart School Assistant',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.school, size: 48),
      applicationLegalese: '© 2024 Smart School Assistant\nAll rights reserved.',
      children: [
        const SizedBox(height: 16),
        const Text(
          'Smart School Assistant is a comprehensive school management application designed to help teachers and administrators manage students, classes, attendance, and generate reports efficiently.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Features include:\n'
          '• Student Management\n'
          '• Attendance Tracking\n'
          '• Grade Management\n'
          '• Report Generation\n'
          '• Analytics Dashboard\n'
          '• Photo Management\n'
          '• Multi-language Support',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showUserGuide() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('User Guide'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGuideSection('Getting Started', [
                  '1. Configure your school information in Settings',
                  '2. Add classes and manage your class structure',
                  '3. Add teachers and assign them to subjects',
                  '4. Add students to your classes',
                ]),
                const SizedBox(height: 16),
                _buildGuideSection('Daily Operations', [
                  '• Take attendance for each class',
                  '• Enter student scores and grades',
                  '• Generate reports and ID cards',
                  '• View analytics and performance insights',
                ]),
                const SizedBox(height: 16),
                _buildGuideSection('Advanced Features', [
                  '• Use the Analytics Dashboard for insights',
                  '• Generate professional PDF reports',
                  '• Manage inventory and data records',
                  '• Backup and restore your data',
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuideSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text('• $item'),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Dark Mode Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.appearance,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.darkMode),
                    subtitle: Text(AppLocalizations.of(context)!.enableDarkTheme),
                    value: _isDarkMode,
                    onChanged: _toggleDarkMode,
                    secondary: Icon(
                      _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Language Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.language,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(AppLocalizations.of(context)!.english),
                    trailing: _selectedLanguage == 'en'
                        ? const Icon(Icons.check, color: Colors.indigo)
                        : null,
                    onTap: () => _changeLanguage('en'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(AppLocalizations.of(context)!.amharic),
                    trailing: _selectedLanguage == 'am'
                        ? const Icon(Icons.check, color: Colors.indigo)
                        : null,
                    onTap: () => _changeLanguage('am'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(AppLocalizations.of(context)!.oromo),
                    trailing: _selectedLanguage == 'om'
                        ? const Icon(Icons.check, color: Colors.indigo)
                        : null,
                    onTap: () => _changeLanguage('om'),
                  ),
                  // Temporarily disabled Oromo
                  // const Divider(),
                  // ListTile(
                  //   leading: const Icon(Icons.language),
                  //   title: const Text('Afaan Oromoo'),
                  //   trailing: _selectedLanguage == 'om'
                  //       ? const Icon(Icons.check, color: Colors.indigo)
                  //       : null,
                  //   onTap: () => _changeLanguage('om'),
                  // ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Guide Section
          Card(
            child: ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('User Guide'),
              subtitle: const Text('Learn how to use the app effectively'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showUserGuide,
            ),
          ),

          const SizedBox(height: 16),

          // About Section
          Card(
            child: ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              subtitle: const Text('App information and version'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showAboutDialog,
            ),
          ),

          const SizedBox(height: 16),

          // App Info Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.appInformation,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: Text(AppLocalizations.of(context)!.version),
                    subtitle: const Text('1.0.0'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.school),
                    title: const Text('School Name'),
                    subtitle: Text(_schoolName.isEmpty ? 'Not configured' : _schoolName),
                    trailing: const Icon(Icons.edit),
                    onTap: _showSchoolNameDialog,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('School Address'),
                    subtitle: Text(_schoolAddress.isEmpty ? 'Not configured' : _schoolAddress),
                    trailing: const Icon(Icons.edit),
                    onTap: _showSchoolNameDialog,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('School Phone'),
                    subtitle: Text(_schoolPhone.isEmpty ? 'Not configured' : _schoolPhone),
                    trailing: const Icon(Icons.edit),
                    onTap: _showSchoolNameDialog,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}