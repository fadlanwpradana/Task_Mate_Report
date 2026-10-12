import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Mate'**
  String get appTitle;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

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

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Your Tasks. Your Community.\nYour Future.'**
  String get splashTagline;

  /// No description provided for @splashDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep your studies organized and make progress together.'**
  String get splashDescription;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get alreadyHaveAccount;

  /// No description provided for @onboardTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay on top of every task'**
  String get onboardTasksTitle;

  /// No description provided for @onboardTasksBody.
  ///
  /// In en, this message translates to:
  /// **'Smart priority picks what to do next, with reminders before each deadline.'**
  String get onboardTasksBody;

  /// No description provided for @onboardCommunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn together'**
  String get onboardCommunityTitle;

  /// No description provided for @onboardCommunityBody.
  ///
  /// In en, this message translates to:
  /// **'Ask questions, share notes, and join study communities.'**
  String get onboardCommunityBody;

  /// No description provided for @onboardChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with classmates'**
  String get onboardChatTitle;

  /// No description provided for @onboardChatBody.
  ///
  /// In en, this message translates to:
  /// **'Message friends or groups by email, private by design.'**
  String get onboardChatBody;

  /// No description provided for @onboardSampleTask.
  ///
  /// In en, this message translates to:
  /// **'Finish ERD report'**
  String get onboardSampleTask;

  /// No description provided for @onboardSampleTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'05h 30m left'**
  String get onboardSampleTimeLeft;

  /// No description provided for @onboardSamplePost.
  ///
  /// In en, this message translates to:
  /// **'How do I use Firebase Auth in Flutter?'**
  String get onboardSamplePost;

  /// No description provided for @onboardSampleChat1.
  ///
  /// In en, this message translates to:
  /// **'Did you finish the ERD?'**
  String get onboardSampleChat1;

  /// No description provided for @onboardSampleChat2.
  ///
  /// In en, this message translates to:
  /// **'Almost! Sending it tonight'**
  String get onboardSampleChat2;

  /// No description provided for @onboardSampleChat3.
  ///
  /// In en, this message translates to:
  /// **'Thanks, see you in class!'**
  String get onboardSampleChat3;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep your studies on track.'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccount;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @passwordResetUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Password reset is unavailable until online authentication is configured.'**
  String get passwordResetUnavailable;

  /// No description provided for @enterEmailToReset.
  ///
  /// In en, this message translates to:
  /// **'Enter your email above to reset your password.'**
  String get enterEmailToReset;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent.'**
  String get passwordResetSent;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccountTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A little more organized, one task at a time.'**
  String get registerSubtitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @passwordHelper.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get passwordHelper;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get haveAccount;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{label} is required.'**
  String fieldRequired(String label);

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get passwordTooShort;

  /// No description provided for @authUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get authUserDisabled;

  /// No description provided for @authWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'The email or password is incorrect.'**
  String get authWrongCredentials;

  /// No description provided for @authEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this email.'**
  String get authEmailInUse;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password.'**
  String get authWeakPassword;

  /// No description provided for @authTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get authTooManyRequests;

  /// No description provided for @authNetwork.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get authNetwork;

  /// No description provided for @authNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Email and password sign-in is not enabled for this Firebase project.'**
  String get authNotEnabled;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get authFailed;

  /// No description provided for @authAccountExists.
  ///
  /// In en, this message translates to:
  /// **'This email already uses another sign-in method. Sign in that way first.'**
  String get authAccountExists;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get googleSignInFailed;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get navCreate;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'{feature} will be added in a later phase.'**
  String comingSoon(String feature);

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get newTask;

  /// No description provided for @newPost.
  ///
  /// In en, this message translates to:
  /// **'Community post'**
  String get newPost;

  /// No description provided for @newCommunity.
  ///
  /// In en, this message translates to:
  /// **'New community'**
  String get newCommunity;

  /// No description provided for @helloName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name} 👋'**
  String helloName(String name);

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello 👋'**
  String get hello;

  /// No description provided for @defaultStudentName.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get defaultStudentName;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let’s make today a little more productive.'**
  String get homeSubtitle;

  /// No description provided for @taskProgress.
  ///
  /// In en, this message translates to:
  /// **'Task progress'**
  String get taskProgress;

  /// No description provided for @tasksCompleted.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} tasks completed'**
  String tasksCompleted(int done, int total);

  /// No description provided for @noTasksProgress.
  ///
  /// In en, this message translates to:
  /// **'Your progress will appear when you add tasks.'**
  String get noTasksProgress;

  /// No description provided for @priorityTask.
  ///
  /// In en, this message translates to:
  /// **'Priority Task'**
  String get priorityTask;

  /// No description provided for @allTasksCompleted.
  ///
  /// In en, this message translates to:
  /// **'All tasks completed! 🎉'**
  String get allTasksCompleted;

  /// No description provided for @todaysTasks.
  ///
  /// In en, this message translates to:
  /// **'Today’s tasks'**
  String get todaysTasks;

  /// No description provided for @noActiveTasksToday.
  ///
  /// In en, this message translates to:
  /// **'No active tasks due today.'**
  String get noActiveTasksToday;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get addTask;

  /// No description provided for @myTasksSummary.
  ///
  /// In en, this message translates to:
  /// **'{active, plural, =1{1 task} other{{active} tasks}} · {week} due this week'**
  String myTasksSummary(int active, int week);

  /// No description provided for @searchTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Search tasks...'**
  String get searchTasksHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterToday;

  /// No description provided for @filterUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get filterUpcoming;

  /// No description provided for @filterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filterCompleted;

  /// No description provided for @sortTasks.
  ///
  /// In en, this message translates to:
  /// **'Sort tasks'**
  String get sortTasks;

  /// No description provided for @sortTasksBy.
  ///
  /// In en, this message translates to:
  /// **'Sort tasks by'**
  String get sortTasksBy;

  /// No description provided for @sortPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority (recommended)'**
  String get sortPriority;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get sortDeadline;

  /// No description provided for @sortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get sortTitle;

  /// No description provided for @noTasksInView.
  ///
  /// In en, this message translates to:
  /// **'No tasks in this view'**
  String get noTasksInView;

  /// No description provided for @noCompletedTasks.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks yet'**
  String get noCompletedTasks;

  /// No description provided for @checkOffHint.
  ///
  /// In en, this message translates to:
  /// **'Check off a task when you finish it.'**
  String get checkOffHint;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get noResults;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityPill.
  ///
  /// In en, this message translates to:
  /// **'{level} PRIORITY'**
  String priorityPill(String level);

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day left} other{{count} days left}}'**
  String daysLeft(int count);

  /// No description provided for @hoursMinutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m left'**
  String hoursMinutesLeft(String hours, String minutes);

  /// No description provided for @daysOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day overdue} other{{count} days overdue}}'**
  String daysOverdue(int count);

  /// No description provided for @hoursOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour overdue} other{{count} hours overdue}}'**
  String hoursOverdue(int count);

  /// No description provided for @minutesOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute overdue} other{{count} minutes overdue}}'**
  String minutesOverdue(int count);

  /// No description provided for @overdueBadge.
  ///
  /// In en, this message translates to:
  /// **'OVERDUE'**
  String get overdueBadge;

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// No description provided for @progressPercent.
  ///
  /// In en, this message translates to:
  /// **'Progress {percent}%'**
  String progressPercent(int percent);

  /// No description provided for @turnReminderOn.
  ///
  /// In en, this message translates to:
  /// **'Turn reminder on'**
  String get turnReminderOn;

  /// No description provided for @turnReminderOff.
  ///
  /// In en, this message translates to:
  /// **'Turn reminder off'**
  String get turnReminderOff;

  /// No description provided for @addTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTaskTitle;

  /// No description provided for @addTaskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn a big assignment into small steps'**
  String get addTaskSubtitle;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @taskTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Finish lab report'**
  String get taskTitleHint;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @taskDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add helpful notes, links or requirements...'**
  String get taskDescriptionHint;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @categoryAcademic.
  ///
  /// In en, this message translates to:
  /// **'Academic'**
  String get categoryAcademic;

  /// No description provided for @categoryProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get categoryProject;

  /// No description provided for @categoryMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get categoryMeeting;

  /// No description provided for @categoryPresentation.
  ///
  /// In en, this message translates to:
  /// **'Presentation'**
  String get categoryPresentation;

  /// No description provided for @categoryPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get categoryPersonal;

  /// No description provided for @categoryQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get categoryQuiz;

  /// No description provided for @categoryExamination.
  ///
  /// In en, this message translates to:
  /// **'Examination'**
  String get categoryExamination;

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// No description provided for @selectDeadlineDate.
  ///
  /// In en, this message translates to:
  /// **'Select deadline date'**
  String get selectDeadlineDate;

  /// No description provided for @selectDeadlineTime.
  ///
  /// In en, this message translates to:
  /// **'Select deadline time'**
  String get selectDeadlineTime;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @reminderSchedule.
  ///
  /// In en, this message translates to:
  /// **'1 day & 1 hour before'**
  String get reminderSchedule;

  /// No description provided for @subtasks.
  ///
  /// In en, this message translates to:
  /// **'Subtasks'**
  String get subtasks;

  /// No description provided for @addSubtask.
  ///
  /// In en, this message translates to:
  /// **'Add subtask'**
  String get addSubtask;

  /// No description provided for @subtaskLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtask'**
  String get subtaskLabel;

  /// No description provided for @enterSubtaskHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a subtask'**
  String get enterSubtaskHint;

  /// No description provided for @defaultSubtask.
  ///
  /// In en, this message translates to:
  /// **'Draft introduction'**
  String get defaultSubtask;

  /// No description provided for @enterSubtaskError.
  ///
  /// In en, this message translates to:
  /// **'Enter a subtask.'**
  String get enterSubtaskError;

  /// No description provided for @removeSubtask.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String removeSubtask(String name);

  /// No description provided for @createTask.
  ///
  /// In en, this message translates to:
  /// **'Create Task'**
  String get createTask;

  /// No description provided for @creatingTask.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creatingTask;

  /// No description provided for @enterTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a task title.'**
  String get enterTaskTitle;

  /// No description provided for @chooseFutureDeadline.
  ///
  /// In en, this message translates to:
  /// **'Choose a future deadline.'**
  String get chooseFutureDeadline;

  /// No description provided for @taskDetails.
  ///
  /// In en, this message translates to:
  /// **'Task Details'**
  String get taskDetails;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @subtasksCount.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String subtasksCount(int done, int total);

  /// No description provided for @noSubtasksYet.
  ///
  /// In en, this message translates to:
  /// **'No subtasks yet. Add one to break this task into steps.'**
  String get noSubtasksYet;

  /// No description provided for @reminderSet.
  ///
  /// In en, this message translates to:
  /// **'Reminder set'**
  String get reminderSet;

  /// No description provided for @reminderOff.
  ///
  /// In en, this message translates to:
  /// **'Reminder off'**
  String get reminderOff;

  /// No description provided for @tapToEnable.
  ///
  /// In en, this message translates to:
  /// **'Tap to enable'**
  String get tapToEnable;

  /// No description provided for @nextReminder.
  ///
  /// In en, this message translates to:
  /// **'Next: {time}'**
  String nextReminder(String time);

  /// No description provided for @noUpcomingReminder.
  ///
  /// In en, this message translates to:
  /// **'No upcoming reminders'**
  String get noUpcomingReminder;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Complete'**
  String get markComplete;

  /// No description provided for @markActive.
  ///
  /// In en, this message translates to:
  /// **'Mark as active'**
  String get markActive;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get deleteTask;

  /// No description provided for @deleteTaskQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete task?'**
  String get deleteTaskQuestion;

  /// No description provided for @deleteTaskMessage.
  ///
  /// In en, this message translates to:
  /// **'This task will be removed from your task list.'**
  String get deleteTaskMessage;

  /// No description provided for @taskName.
  ///
  /// In en, this message translates to:
  /// **'Task name'**
  String get taskName;

  /// No description provided for @enterTaskName.
  ///
  /// In en, this message translates to:
  /// **'Enter a task name.'**
  String get enterTaskName;

  /// No description provided for @reminderChannelName.
  ///
  /// In en, this message translates to:
  /// **'Task reminders'**
  String get reminderChannelName;

  /// No description provided for @reminderChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminders before your task deadlines'**
  String get reminderChannelDescription;

  /// No description provided for @reminderDayBody.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow at {time}. Don’t forget!'**
  String reminderDayBody(String time);

  /// No description provided for @reminderHourBody.
  ///
  /// In en, this message translates to:
  /// **'Due in 1 hour, at {time}.'**
  String reminderHourBody(String time);

  /// No description provided for @tasksForDate.
  ///
  /// In en, this message translates to:
  /// **'Tasks on {date}'**
  String tasksForDate(String date);

  /// No description provided for @noTasksOnDay.
  ///
  /// In en, this message translates to:
  /// **'No tasks on this day.'**
  String get noTasksOnDay;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @forYou.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get forYou;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @trending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// No description provided for @searchCommunityHint.
  ///
  /// In en, this message translates to:
  /// **'Search posts, communities, or topics...'**
  String get searchCommunityHint;

  /// No description provided for @filterPosts.
  ///
  /// In en, this message translates to:
  /// **'Filter posts'**
  String get filterPosts;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get allTypes;

  /// No description provided for @postTypeDiscussion.
  ///
  /// In en, this message translates to:
  /// **'Discussion'**
  String get postTypeDiscussion;

  /// No description provided for @postTypeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get postTypeQuestion;

  /// No description provided for @postTypeAssignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get postTypeAssignment;

  /// No description provided for @noPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noPostsTitle;

  /// No description provided for @noPostsDescription.
  ///
  /// In en, this message translates to:
  /// **'Be the first to start a discussion.'**
  String get noPostsDescription;

  /// No description provided for @noFollowingPosts.
  ///
  /// In en, this message translates to:
  /// **'Join communities to see their posts here.'**
  String get noFollowingPosts;

  /// No description provided for @communities.
  ///
  /// In en, this message translates to:
  /// **'Communities'**
  String get communities;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @bookmark.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get bookmark;

  /// No description provided for @removeBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get removeBookmark;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} d ago'**
  String daysAgo(int count);

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create post'**
  String get createPost;

  /// No description provided for @postTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get postTitleLabel;

  /// No description provided for @postTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a title...'**
  String get postTitleHint;

  /// No description provided for @postDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Write the details of your question or discussion...'**
  String get postDescriptionHint;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get addTag;

  /// No description provided for @tagHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Flutter'**
  String get tagHint;

  /// No description provided for @communityOptional.
  ///
  /// In en, this message translates to:
  /// **'Community (optional)'**
  String get communityOptional;

  /// No description provided for @noCommunity.
  ///
  /// In en, this message translates to:
  /// **'No community'**
  String get noCommunity;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get publish;

  /// No description provided for @postPublished.
  ///
  /// In en, this message translates to:
  /// **'Post published'**
  String get postPublished;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @noComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Start the conversation!'**
  String get noComments;

  /// No description provided for @writeComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get writeComment;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @searchCommunitiesHint.
  ///
  /// In en, this message translates to:
  /// **'Search communities...'**
  String get searchCommunitiesHint;

  /// No description provided for @filterPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get filterPopular;

  /// No description provided for @filterJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get filterJoined;

  /// No description provided for @categoryCourse.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get categoryCourse;

  /// No description provided for @categoryMajor.
  ///
  /// In en, this message translates to:
  /// **'Major'**
  String get categoryMajor;

  /// No description provided for @categoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get categoryGeneral;

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String membersCount(int count);

  /// No description provided for @postsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 post} other{{count} posts}}'**
  String postsCount(int count);

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @noCommunities.
  ///
  /// In en, this message translates to:
  /// **'No communities found.'**
  String get noCommunities;

  /// No description provided for @communityNoPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts in this community yet.'**
  String get communityNoPosts;

  /// No description provided for @createCommunity.
  ///
  /// In en, this message translates to:
  /// **'Create community'**
  String get createCommunity;

  /// No description provided for @communityColor.
  ///
  /// In en, this message translates to:
  /// **'Community color'**
  String get communityColor;

  /// No description provided for @communityNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Community name'**
  String get communityNameLabel;

  /// No description provided for @communityNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a community name...'**
  String get communityNameHint;

  /// No description provided for @communityDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Tell people what this community is about...'**
  String get communityDescriptionHint;

  /// No description provided for @topicLabel.
  ///
  /// In en, this message translates to:
  /// **'Course / Topic'**
  String get topicLabel;

  /// No description provided for @topicHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Database Systems'**
  String get topicHint;

  /// No description provided for @visibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get visibilityPublic;

  /// No description provided for @visibilityPublicDescription.
  ///
  /// In en, this message translates to:
  /// **'Anyone can see this community'**
  String get visibilityPublicDescription;

  /// No description provided for @visibilityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get visibilityPrivate;

  /// No description provided for @visibilityPrivateDescription.
  ///
  /// In en, this message translates to:
  /// **'Only members can see its posts'**
  String get visibilityPrivateDescription;

  /// No description provided for @communityCreated.
  ///
  /// In en, this message translates to:
  /// **'Community created'**
  String get communityCreated;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search posts and communities...'**
  String get searchHint;

  /// No description provided for @searchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type to search posts and communities.'**
  String get searchPrompt;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your Task Mate space'**
  String get profileSubtitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @studyProgram.
  ///
  /// In en, this message translates to:
  /// **'Study program'**
  String get studyProgram;

  /// No description provided for @studyProgramHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. BSc Psychology · Year 2'**
  String get studyProgramHint;

  /// No description provided for @nameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty.'**
  String get nameEmpty;

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} DAY STREAK'**
  String dayStreak(int count);

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationSettings;

  /// No description provided for @taskRemindersSetting.
  ///
  /// In en, this message translates to:
  /// **'Task reminders'**
  String get taskRemindersSetting;

  /// No description provided for @taskRemindersDescription.
  ///
  /// In en, this message translates to:
  /// **'1 day & 1 hour before deadlines'**
  String get taskRemindersDescription;

  /// No description provided for @weeklyEncouragement.
  ///
  /// In en, this message translates to:
  /// **'Weekly encouragement'**
  String get weeklyEncouragement;

  /// No description provided for @weeklyEncouragementDescription.
  ///
  /// In en, this message translates to:
  /// **'A Sunday progress recap'**
  String get weeklyEncouragementDescription;

  /// No description provided for @groupUpdates.
  ///
  /// In en, this message translates to:
  /// **'Group task updates'**
  String get groupUpdates;

  /// No description provided for @groupUpdatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Changes from classmates'**
  String get groupUpdatesDescription;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get appSettings;

  /// No description provided for @studyWeekStarts.
  ///
  /// In en, this message translates to:
  /// **'Study week starts'**
  String get studyWeekStarts;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// No description provided for @appearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// No description provided for @appearanceSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get appearanceSystem;

  /// No description provided for @helpFeedback.
  ///
  /// In en, this message translates to:
  /// **'Help & feedback'**
  String get helpFeedback;

  /// No description provided for @helpFeedbackMessage.
  ///
  /// In en, this message translates to:
  /// **'Need a hand with Task Mate? Share feedback or report an issue to your app administrator.'**
  String get helpFeedbackMessage;

  /// No description provided for @logOutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutQuestion;

  /// No description provided for @logOutMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to use Task Mate.'**
  String get logOutMessage;

  /// No description provided for @remindersOffInProfile.
  ///
  /// In en, this message translates to:
  /// **'Task reminders are turned off in Profile'**
  String get remindersOffInProfile;

  /// No description provided for @weeklyRecapTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly recap'**
  String get weeklyRecapTitle;

  /// No description provided for @weeklyRecapBody.
  ///
  /// In en, this message translates to:
  /// **'Take a minute to review this week’s progress in Task Mate 💪'**
  String get weeklyRecapBody;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get newChat;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get newGroup;

  /// No description provided for @searchChatsHint.
  ///
  /// In en, this message translates to:
  /// **'Search chats...'**
  String get searchChatsHint;

  /// No description provided for @noChats.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get noChats;

  /// No description provided for @noChatsDescription.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation with a classmate.'**
  String get noChatsDescription;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @youPrefix.
  ///
  /// In en, this message translates to:
  /// **'You: {text}'**
  String youPrefix(String text);

  /// No description provided for @senderPrefix.
  ///
  /// In en, this message translates to:
  /// **'{name}: {text}'**
  String senderPrefix(String name, String text);

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get messageHint;

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'typing...'**
  String get typing;

  /// No description provided for @userTyping.
  ///
  /// In en, this message translates to:
  /// **'{name} is typing...'**
  String userTyping(String name);

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @messageRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get messageRead;

  /// No description provided for @messageSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get messageSent;

  /// No description provided for @sayHello.
  ///
  /// In en, this message translates to:
  /// **'Say hello to {name} 👋'**
  String sayHello(String name);

  /// No description provided for @groupCreatedNote.
  ///
  /// In en, this message translates to:
  /// **'You created this group'**
  String get groupCreatedNote;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupName;

  /// No description provided for @groupNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Database Study Group'**
  String get groupNameHint;

  /// No description provided for @chooseMembers.
  ///
  /// In en, this message translates to:
  /// **'Choose members'**
  String get chooseMembers;

  /// No description provided for @membersSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String membersSelected(int count);

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroup;

  /// No description provided for @pickAtLeastTwo.
  ///
  /// In en, this message translates to:
  /// **'Choose at least 2 members.'**
  String get pickAtLeastTwo;

  /// No description provided for @groupMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get groupMembers;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get sendMessage;

  /// No description provided for @chatDemoNotice.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: replies are simulated until chat is connected to a server.'**
  String get chatDemoNotice;

  /// No description provided for @recipientEmail.
  ///
  /// In en, this message translates to:
  /// **'Recipient\'s email'**
  String get recipientEmail;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'name@campus.ac.id'**
  String get emailHint;

  /// No description provided for @firstMessage.
  ///
  /// In en, this message translates to:
  /// **'First message'**
  String get firstMessage;

  /// No description provided for @firstMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Say hi and introduce yourself...'**
  String get firstMessageHint;

  /// No description provided for @firstMessageOptional.
  ///
  /// In en, this message translates to:
  /// **'First message (optional)'**
  String get firstMessageOptional;

  /// No description provided for @startChatPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'For privacy, people can only be found by their exact email address.'**
  String get startChatPrivacyNote;

  /// No description provided for @emailNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email isn\'t registered on Task Mate.'**
  String get emailNotRegistered;

  /// No description provided for @cannotChatWithSelf.
  ///
  /// In en, this message translates to:
  /// **'You can\'t start a chat with yourself.'**
  String get cannotChatWithSelf;

  /// No description provided for @memberEmail.
  ///
  /// In en, this message translates to:
  /// **'Member\'s email'**
  String get memberEmail;

  /// No description provided for @memberAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Already added.'**
  String get memberAlreadyAdded;

  /// No description provided for @demoEmailsHint.
  ///
  /// In en, this message translates to:
  /// **'Demo accounts: {emails}'**
  String demoEmailsHint(String emails);

  /// No description provided for @chatServerError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server. Check your connection and try again.'**
  String get chatServerError;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get languageIndonesian;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @defaultProfileName.
  ///
  /// In en, this message translates to:
  /// **'Task Mate student'**
  String get defaultProfileName;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
