import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';
import 'app_localizations_om.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en'),
    Locale('om')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart School Assistant'**
  String get appTitle;

  /// No description provided for @selectAClass.
  ///
  /// In en, this message translates to:
  /// **'Select a Class'**
  String get selectAClass;

  /// No description provided for @noClassesFound.
  ///
  /// In en, this message translates to:
  /// **'No classes found. Tap + to add one.'**
  String get noClassesFound;

  /// No description provided for @addNewClassSection.
  ///
  /// In en, this message translates to:
  /// **'Add New Class Section'**
  String get addNewClassSection;

  /// No description provided for @className.
  ///
  /// In en, this message translates to:
  /// **'Class Name (e.g., Grade 7A)'**
  String get className;

  /// No description provided for @pleaseEnterClassName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a class name.'**
  String get pleaseEnterClassName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @oromo.
  ///
  /// In en, this message translates to:
  /// **'Afaan Oromoo'**
  String get oromo;

  /// No description provided for @teacherAssistant.
  ///
  /// In en, this message translates to:
  /// **'Teacher Assistant'**
  String get teacherAssistant;

  /// No description provided for @timetable.
  ///
  /// In en, this message translates to:
  /// **'Timetable'**
  String get timetable;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @addNewStudent.
  ///
  /// In en, this message translates to:
  /// **'Add New Student'**
  String get addNewStudent;

  /// No description provided for @studentFullName.
  ///
  /// In en, this message translates to:
  /// **'Student\'s Full Name'**
  String get studentFullName;

  /// No description provided for @pleaseEnterStudentName.
  ///
  /// In en, this message translates to:
  /// **'Please enter the student\'s name.'**
  String get pleaseEnterStudentName;

  /// No description provided for @takeAttendance.
  ///
  /// In en, this message translates to:
  /// **'Take Attendance'**
  String get takeAttendance;

  /// No description provided for @enterScores.
  ///
  /// In en, this message translates to:
  /// **'Enter Scores'**
  String get enterScores;

  /// No description provided for @noStudentsFound.
  ///
  /// In en, this message translates to:
  /// **'No students found in this class.'**
  String get noStudentsFound;

  /// No description provided for @weeklyTimetable.
  ///
  /// In en, this message translates to:
  /// **'Weekly Timetable'**
  String get weeklyTimetable;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @generateTimetable.
  ///
  /// In en, this message translates to:
  /// **'Generate Timetable'**
  String get generateTimetable;

  /// No description provided for @generatingTimetable.
  ///
  /// In en, this message translates to:
  /// **'Generating new timetable...'**
  String get generatingTimetable;

  /// No description provided for @timetableGenerated.
  ///
  /// In en, this message translates to:
  /// **'New timetable generated!'**
  String get timetableGenerated;

  /// No description provided for @noPeriodsDefined.
  ///
  /// In en, this message translates to:
  /// **'No periods defined. Please add periods in settings.'**
  String get noPeriodsDefined;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @breakPeriod.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get breakPeriod;

  /// No description provided for @generateReports.
  ///
  /// In en, this message translates to:
  /// **'Generate Reports'**
  String get generateReports;

  /// No description provided for @reportGenerationComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Report Generation Module - Coming Soon'**
  String get reportGenerationComingSoon;

  /// No description provided for @takeAttendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Take Attendance'**
  String get takeAttendanceTitle;

  /// No description provided for @saveAttendance.
  ///
  /// In en, this message translates to:
  /// **'Save Attendance'**
  String get saveAttendance;

  /// No description provided for @attendanceSaved.
  ///
  /// In en, this message translates to:
  /// **'Attendance saved successfully!'**
  String get attendanceSaved;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'P'**
  String get present;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'A'**
  String get absent;

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get late;

  /// No description provided for @enterStudentScores.
  ///
  /// In en, this message translates to:
  /// **'Enter Student Scores'**
  String get enterStudentScores;

  /// No description provided for @selectStudent.
  ///
  /// In en, this message translates to:
  /// **'Select a Student'**
  String get selectStudent;

  /// No description provided for @selectSubject.
  ///
  /// In en, this message translates to:
  /// **'Select a Subject'**
  String get selectSubject;

  /// No description provided for @selectAssessmentType.
  ///
  /// In en, this message translates to:
  /// **'Select Assessment Type'**
  String get selectAssessmentType;

  /// No description provided for @scoreMarks.
  ///
  /// In en, this message translates to:
  /// **'Score / Marks'**
  String get scoreMarks;

  /// No description provided for @pleaseEnterScore.
  ///
  /// In en, this message translates to:
  /// **'Please enter a score.'**
  String get pleaseEnterScore;

  /// No description provided for @pleaseEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number.'**
  String get pleaseEnterValidNumber;

  /// No description provided for @scoreSaved.
  ///
  /// In en, this message translates to:
  /// **'Score saved successfully!'**
  String get scoreSaved;

  /// No description provided for @generateReportsCards.
  ///
  /// In en, this message translates to:
  /// **'Generate Reports & Cards'**
  String get generateReportsCards;

  /// No description provided for @studentIdCards.
  ///
  /// In en, this message translates to:
  /// **'Student ID Cards'**
  String get studentIdCards;

  /// No description provided for @generatePrintableIdCards.
  ///
  /// In en, this message translates to:
  /// **'Generate printable ID cards for a class.'**
  String get generatePrintableIdCards;

  /// No description provided for @studentReportCards.
  ///
  /// In en, this message translates to:
  /// **'Student Report Cards'**
  String get studentReportCards;

  /// No description provided for @generateEndOfTermReports.
  ///
  /// In en, this message translates to:
  /// **'Generate end-of-term report cards for a class.'**
  String get generateEndOfTermReports;

  /// No description provided for @studentReportCard.
  ///
  /// In en, this message translates to:
  /// **'Student Report Card'**
  String get studentReportCard;

  /// No description provided for @studentName.
  ///
  /// In en, this message translates to:
  /// **'Student Name'**
  String get studentName;

  /// No description provided for @studentId.
  ///
  /// In en, this message translates to:
  /// **'Student ID'**
  String get studentId;

  /// No description provided for @classRank.
  ///
  /// In en, this message translates to:
  /// **'Class Rank'**
  String get classRank;

  /// No description provided for @academicPerformance.
  ///
  /// In en, this message translates to:
  /// **'Academic Performance'**
  String get academicPerformance;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @averageMark.
  ///
  /// In en, this message translates to:
  /// **'Average Mark'**
  String get averageMark;

  /// No description provided for @yourSchoolName.
  ///
  /// In en, this message translates to:
  /// **'Your School Name'**
  String get yourSchoolName;

  /// No description provided for @classLabel.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classLabel;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @homework.
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get homework;

  /// No description provided for @quiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quiz;

  /// No description provided for @midTerm.
  ///
  /// In en, this message translates to:
  /// **'Mid-term'**
  String get midTerm;

  /// No description provided for @finalExam.
  ///
  /// In en, this message translates to:
  /// **'Final Exam'**
  String get finalExam;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields.'**
  String get pleaseFillAllFields;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @noSubjectsFound.
  ///
  /// In en, this message translates to:
  /// **'No subjects found. Please add subjects first.'**
  String get noSubjectsFound;

  /// No description provided for @timetableSettings.
  ///
  /// In en, this message translates to:
  /// **'Timetable Settings'**
  String get timetableSettings;

  /// No description provided for @manageTeachers.
  ///
  /// In en, this message translates to:
  /// **'Manage Teachers'**
  String get manageTeachers;

  /// No description provided for @manageTeachersDesc.
  ///
  /// In en, this message translates to:
  /// **'Add or remove teachers for the schedule'**
  String get manageTeachersDesc;

  /// No description provided for @manageSubjects.
  ///
  /// In en, this message translates to:
  /// **'Manage Subjects'**
  String get manageSubjects;

  /// No description provided for @manageSubjectsDesc.
  ///
  /// In en, this message translates to:
  /// **'Add subjects and assign teachers'**
  String get manageSubjectsDesc;

  /// No description provided for @managePeriods.
  ///
  /// In en, this message translates to:
  /// **'Manage Periods'**
  String get managePeriods;

  /// No description provided for @managePeriodsDesc.
  ///
  /// In en, this message translates to:
  /// **'Define class periods and break times'**
  String get managePeriodsDesc;

  /// No description provided for @addNewTeacher.
  ///
  /// In en, this message translates to:
  /// **'Add New Teacher'**
  String get addNewTeacher;

  /// No description provided for @teachersFullName.
  ///
  /// In en, this message translates to:
  /// **'Teacher\'s Full Name'**
  String get teachersFullName;

  /// No description provided for @pleaseEnterTeacherName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a teacher\'s name.'**
  String get pleaseEnterTeacherName;

  /// No description provided for @noTeachersFound.
  ///
  /// In en, this message translates to:
  /// **'No teachers found. Tap + to add one.'**
  String get noTeachersFound;

  /// No description provided for @addTeacher.
  ///
  /// In en, this message translates to:
  /// **'Add Teacher'**
  String get addTeacher;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @enableDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Enable dark theme'**
  String get enableDarkTheme;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @amharic.
  ///
  /// In en, this message translates to:
  /// **'አማርኛ (Amharic)'**
  String get amharic;

  /// No description provided for @userGuide.
  ///
  /// In en, this message translates to:
  /// **'User Guide'**
  String get userGuide;

  /// No description provided for @howToUseApp.
  ///
  /// In en, this message translates to:
  /// **'How to use the app'**
  String get howToUseApp;

  /// No description provided for @appInformation.
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get appInformation;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @schoolName.
  ///
  /// In en, this message translates to:
  /// **'School Name'**
  String get schoolName;

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get notConfigured;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['am', 'en', 'om'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am': return AppLocalizationsAm();
    case 'en': return AppLocalizationsEn();
    case 'om': return AppLocalizationsOm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
