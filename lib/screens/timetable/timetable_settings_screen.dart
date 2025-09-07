// =============================================================
// FILE: lib/screens/timetable/timetable_settings_screen.dart (UPDATED)
// =============================================================
import 'package:flutter/material.dart';
import 'package:smart_school_assistant/l10n/app_localizations.dart';
import 'manage_teachers_screen.dart';
import 'manage_timetable_subjects_screen.dart';
import 'manage_periods_screen.dart'; // <-- NEW IMPORT

class TimetableSettingsScreen extends StatelessWidget {
  const TimetableSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.timetableSettings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(AppLocalizations.of(context)!.manageTeachers),
            subtitle: Text(AppLocalizations.of(context)!.manageTeachersDesc),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageTeachersScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.book_outlined),
            title: Text(AppLocalizations.of(context)!.manageSubjects),
            subtitle: Text(AppLocalizations.of(context)!.manageSubjectsDesc),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageTimetableSubjectsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(AppLocalizations.of(context)!.managePeriods),
            subtitle: Text(AppLocalizations.of(context)!.managePeriodsDesc),
            onTap: () {
              // --- NAVIGATION IS NOW ACTIVE ---
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManagePeriodsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

