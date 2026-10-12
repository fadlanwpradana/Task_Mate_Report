// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Task Mate';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get seeAll => 'See all';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get splashTagline => 'Your Tasks. Your Community.\nYour Future.';

  @override
  String get splashDescription =>
      'Keep your studies organized and make progress together.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get alreadyHaveAccount => 'I already have an account';

  @override
  String get onboardTasksTitle => 'Stay on top of every task';

  @override
  String get onboardTasksBody =>
      'Smart priority picks what to do next, with reminders before each deadline.';

  @override
  String get onboardCommunityTitle => 'Learn together';

  @override
  String get onboardCommunityBody =>
      'Ask questions, share notes, and join study communities.';

  @override
  String get onboardChatTitle => 'Chat with classmates';

  @override
  String get onboardChatBody =>
      'Message friends or groups by email, private by design.';

  @override
  String get onboardSampleTask => 'Finish ERD report';

  @override
  String get onboardSampleTimeLeft => '05h 30m left';

  @override
  String get onboardSamplePost => 'How do I use Firebase Auth in Flutter?';

  @override
  String get onboardSampleChat1 => 'Did you finish the ERD?';

  @override
  String get onboardSampleChat2 => 'Almost! Sending it tonight';

  @override
  String get onboardSampleChat3 => 'Thanks, see you in class!';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to keep your studies on track.';

  @override
  String get emailLabel => 'Email address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get login => 'Login';

  @override
  String get noAccount => 'Don\'t have an account? ';

  @override
  String get register => 'Register';

  @override
  String get passwordResetUnavailable =>
      'Password reset is unavailable until online authentication is configured.';

  @override
  String get enterEmailToReset =>
      'Enter your email above to reset your password.';

  @override
  String get passwordResetSent => 'Password reset email sent.';

  @override
  String get createAccountTitle => 'Create your account';

  @override
  String get registerSubtitle => 'A little more organized, one task at a time.';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get passwordHelper => 'Use at least 8 characters.';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get createAccount => 'Create account';

  @override
  String get haveAccount => 'Already have an account? Login';

  @override
  String fieldRequired(String label) {
    return '$label is required.';
  }

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String get passwordTooShort => 'Use at least 8 characters.';

  @override
  String get authUserDisabled => 'This account has been disabled.';

  @override
  String get authWrongCredentials => 'The email or password is incorrect.';

  @override
  String get authEmailInUse => 'An account already exists for this email.';

  @override
  String get authWeakPassword => 'Choose a stronger password.';

  @override
  String get authTooManyRequests =>
      'Too many attempts. Please try again later.';

  @override
  String get authNetwork => 'Check your internet connection and try again.';

  @override
  String get authNotEnabled =>
      'Email and password sign-in is not enabled for this Firebase project.';

  @override
  String get authFailed => 'Authentication failed. Please try again.';

  @override
  String get authAccountExists =>
      'This email already uses another sign-in method. Sign in that way first.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get orDivider => 'or';

  @override
  String get googleSignInFailed => 'Google sign-in failed. Please try again.';

  @override
  String get navHome => 'Home';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navCreate => 'Create';

  @override
  String get navCommunity => 'Community';

  @override
  String get navProfile => 'Profile';

  @override
  String get chat => 'Chat';

  @override
  String comingSoon(String feature) {
    return '$feature will be added in a later phase.';
  }

  @override
  String get newTask => 'New task';

  @override
  String get newPost => 'Community post';

  @override
  String get newCommunity => 'New community';

  @override
  String helloName(String name) {
    return 'Hello, $name 👋';
  }

  @override
  String get hello => 'Hello 👋';

  @override
  String get defaultStudentName => 'Student';

  @override
  String get homeSubtitle => 'Let’s make today a little more productive.';

  @override
  String get taskProgress => 'Task progress';

  @override
  String tasksCompleted(int done, int total) {
    return '$done of $total tasks completed';
  }

  @override
  String get noTasksProgress => 'Your progress will appear when you add tasks.';

  @override
  String get priorityTask => 'Priority Task';

  @override
  String get allTasksCompleted => 'All tasks completed! 🎉';

  @override
  String get todaysTasks => 'Today’s tasks';

  @override
  String get noActiveTasksToday => 'No active tasks due today.';

  @override
  String get addTask => 'Add task';

  @override
  String myTasksSummary(int active, int week) {
    String _temp0 = intl.Intl.pluralLogic(
      active,
      locale: localeName,
      other: '$active tasks',
      one: '1 task',
    );
    return '$_temp0 · $week due this week';
  }

  @override
  String get searchTasksHint => 'Search tasks...';

  @override
  String get filterAll => 'All';

  @override
  String get filterToday => 'Today';

  @override
  String get filterUpcoming => 'Upcoming';

  @override
  String get filterCompleted => 'Completed';

  @override
  String get sortTasks => 'Sort tasks';

  @override
  String get sortTasksBy => 'Sort tasks by';

  @override
  String get sortPriority => 'Priority (recommended)';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortDeadline => 'Deadline';

  @override
  String get sortTitle => 'Title';

  @override
  String get noTasksInView => 'No tasks in this view';

  @override
  String get noCompletedTasks => 'No completed tasks yet';

  @override
  String get checkOffHint => 'Check off a task when you finish it.';

  @override
  String get noResults => 'No results found.';

  @override
  String get calendar => 'Calendar';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityLow => 'Low';

  @override
  String priorityPill(String level) {
    return '$level PRIORITY';
  }

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String hoursMinutesLeft(String hours, String minutes) {
    return '${hours}h ${minutes}m left';
  }

  @override
  String daysOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String hoursOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours overdue',
      one: '1 hour overdue',
    );
    return '$_temp0';
  }

  @override
  String minutesOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes overdue',
      one: '1 minute overdue',
    );
    return '$_temp0';
  }

  @override
  String get overdueBadge => 'OVERDUE';

  @override
  String get completedLabel => 'Completed';

  @override
  String progressPercent(int percent) {
    return 'Progress $percent%';
  }

  @override
  String get turnReminderOn => 'Turn reminder on';

  @override
  String get turnReminderOff => 'Turn reminder off';

  @override
  String get addTaskTitle => 'Add Task';

  @override
  String get addTaskSubtitle => 'Turn a big assignment into small steps';

  @override
  String get titleLabel => 'Title';

  @override
  String get taskTitleHint => 'e.g. Finish lab report';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get taskDescriptionHint =>
      'Add helpful notes, links or requirements...';

  @override
  String get categoryLabel => 'Category';

  @override
  String get categoryAcademic => 'Academic';

  @override
  String get categoryProject => 'Project';

  @override
  String get categoryMeeting => 'Meeting';

  @override
  String get categoryPresentation => 'Presentation';

  @override
  String get categoryPersonal => 'Personal';

  @override
  String get categoryQuiz => 'Quiz';

  @override
  String get categoryExamination => 'Examination';

  @override
  String get deadline => 'Deadline';

  @override
  String get selectDeadlineDate => 'Select deadline date';

  @override
  String get selectDeadlineTime => 'Select deadline time';

  @override
  String get priority => 'Priority';

  @override
  String get reminder => 'Reminder';

  @override
  String get reminderSchedule => '1 day & 1 hour before';

  @override
  String get subtasks => 'Subtasks';

  @override
  String get addSubtask => 'Add subtask';

  @override
  String get subtaskLabel => 'Subtask';

  @override
  String get enterSubtaskHint => 'Enter a subtask';

  @override
  String get defaultSubtask => 'Draft introduction';

  @override
  String get enterSubtaskError => 'Enter a subtask.';

  @override
  String removeSubtask(String name) {
    return 'Remove $name';
  }

  @override
  String get createTask => 'Create Task';

  @override
  String get creatingTask => 'Creating...';

  @override
  String get enterTaskTitle => 'Enter a task title.';

  @override
  String get chooseFutureDeadline => 'Choose a future deadline.';

  @override
  String get taskDetails => 'Task Details';

  @override
  String get moreOptions => 'More options';

  @override
  String get progress => 'Progress';

  @override
  String subtasksCount(int done, int total) {
    return '$done of $total';
  }

  @override
  String get noSubtasksYet =>
      'No subtasks yet. Add one to break this task into steps.';

  @override
  String get reminderSet => 'Reminder set';

  @override
  String get reminderOff => 'Reminder off';

  @override
  String get tapToEnable => 'Tap to enable';

  @override
  String nextReminder(String time) {
    return 'Next: $time';
  }

  @override
  String get noUpcomingReminder => 'No upcoming reminders';

  @override
  String get markComplete => 'Mark Complete';

  @override
  String get markActive => 'Mark as active';

  @override
  String get editTask => 'Edit task';

  @override
  String get deleteTask => 'Delete task';

  @override
  String get deleteTaskQuestion => 'Delete task?';

  @override
  String get deleteTaskMessage =>
      'This task will be removed from your task list.';

  @override
  String get taskName => 'Task name';

  @override
  String get enterTaskName => 'Enter a task name.';

  @override
  String get reminderChannelName => 'Task reminders';

  @override
  String get reminderChannelDescription =>
      'Reminders before your task deadlines';

  @override
  String reminderDayBody(String time) {
    return 'Due tomorrow at $time. Don’t forget!';
  }

  @override
  String reminderHourBody(String time) {
    return 'Due in 1 hour, at $time.';
  }

  @override
  String tasksForDate(String date) {
    return 'Tasks on $date';
  }

  @override
  String get noTasksOnDay => 'No tasks on this day.';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get forYou => 'For You';

  @override
  String get following => 'Following';

  @override
  String get trending => 'Trending';

  @override
  String get searchCommunityHint => 'Search posts, communities, or topics...';

  @override
  String get filterPosts => 'Filter posts';

  @override
  String get allTypes => 'All types';

  @override
  String get postTypeDiscussion => 'Discussion';

  @override
  String get postTypeQuestion => 'Question';

  @override
  String get postTypeAssignment => 'Assignment';

  @override
  String get noPostsTitle => 'No posts yet';

  @override
  String get noPostsDescription => 'Be the first to start a discussion.';

  @override
  String get noFollowingPosts => 'Join communities to see their posts here.';

  @override
  String get communities => 'Communities';

  @override
  String get like => 'Like';

  @override
  String get bookmark => 'Save';

  @override
  String get removeBookmark => 'Remove from saved';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String daysAgo(int count) {
    return '$count d ago';
  }

  @override
  String get createPost => 'Create post';

  @override
  String get postTitleLabel => 'Title';

  @override
  String get postTitleHint => 'Enter a title...';

  @override
  String get postDescriptionHint =>
      'Write the details of your question or discussion...';

  @override
  String get tags => 'Tags';

  @override
  String get addTag => 'Add tag';

  @override
  String get tagHint => 'e.g. Flutter';

  @override
  String get communityOptional => 'Community (optional)';

  @override
  String get noCommunity => 'No community';

  @override
  String get publish => 'Post';

  @override
  String get postPublished => 'Post published';

  @override
  String get post => 'Post';

  @override
  String get comments => 'Comments';

  @override
  String get noComments => 'No comments yet. Start the conversation!';

  @override
  String get writeComment => 'Write a comment...';

  @override
  String get send => 'Send';

  @override
  String get reply => 'Reply';

  @override
  String get searchCommunitiesHint => 'Search communities...';

  @override
  String get filterPopular => 'Popular';

  @override
  String get filterJoined => 'Joined';

  @override
  String get categoryCourse => 'Course';

  @override
  String get categoryMajor => 'Major';

  @override
  String get categoryGeneral => 'General';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String postsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posts',
      one: '1 post',
    );
    return '$_temp0';
  }

  @override
  String get join => 'Join';

  @override
  String get joined => 'Joined';

  @override
  String get noCommunities => 'No communities found.';

  @override
  String get communityNoPosts => 'No posts in this community yet.';

  @override
  String get createCommunity => 'Create community';

  @override
  String get communityColor => 'Community color';

  @override
  String get communityNameLabel => 'Community name';

  @override
  String get communityNameHint => 'Enter a community name...';

  @override
  String get communityDescriptionHint =>
      'Tell people what this community is about...';

  @override
  String get topicLabel => 'Course / Topic';

  @override
  String get topicHint => 'e.g. Database Systems';

  @override
  String get visibilityPublic => 'Public';

  @override
  String get visibilityPublicDescription => 'Anyone can see this community';

  @override
  String get visibilityPrivate => 'Private';

  @override
  String get visibilityPrivateDescription => 'Only members can see its posts';

  @override
  String get communityCreated => 'Community created';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search posts and communities...';

  @override
  String get searchPrompt => 'Type to search posts and communities.';

  @override
  String get posts => 'Posts';

  @override
  String get profileSubtitle => 'Your Task Mate space';

  @override
  String get settings => 'Settings';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get nameLabel => 'Name';

  @override
  String get studyProgram => 'Study program';

  @override
  String get studyProgramHint => 'e.g. BSc Psychology · Year 2';

  @override
  String get nameEmpty => 'Name cannot be empty.';

  @override
  String dayStreak(int count) {
    return '$count DAY STREAK';
  }

  @override
  String get notificationSettings => 'Notification settings';

  @override
  String get taskRemindersSetting => 'Task reminders';

  @override
  String get taskRemindersDescription => '1 day & 1 hour before deadlines';

  @override
  String get weeklyEncouragement => 'Weekly encouragement';

  @override
  String get weeklyEncouragementDescription => 'A Sunday progress recap';

  @override
  String get groupUpdates => 'Group task updates';

  @override
  String get groupUpdatesDescription => 'Changes from classmates';

  @override
  String get appSettings => 'App settings';

  @override
  String get studyWeekStarts => 'Study week starts';

  @override
  String get monday => 'Monday';

  @override
  String get sunday => 'Sunday';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get appearanceSystem => 'System default';

  @override
  String get helpFeedback => 'Help & feedback';

  @override
  String get helpFeedbackMessage =>
      'Need a hand with Task Mate? Share feedback or report an issue to your app administrator.';

  @override
  String get logOutQuestion => 'Log out?';

  @override
  String get logOutMessage => 'You\'ll need to sign in again to use Task Mate.';

  @override
  String get remindersOffInProfile =>
      'Task reminders are turned off in Profile';

  @override
  String get weeklyRecapTitle => 'Weekly recap';

  @override
  String get weeklyRecapBody =>
      'Take a minute to review this week’s progress in Task Mate 💪';

  @override
  String get chats => 'Chats';

  @override
  String get newChat => 'New chat';

  @override
  String get newGroup => 'New group';

  @override
  String get searchChatsHint => 'Search chats...';

  @override
  String get noChats => 'No chats yet';

  @override
  String get noChatsDescription => 'Start a conversation with a classmate.';

  @override
  String get you => 'You';

  @override
  String youPrefix(String text) {
    return 'You: $text';
  }

  @override
  String senderPrefix(String name, String text) {
    return '$name: $text';
  }

  @override
  String get messageHint => 'Type a message...';

  @override
  String get typing => 'typing...';

  @override
  String userTyping(String name) {
    return '$name is typing...';
  }

  @override
  String get yesterday => 'Yesterday';

  @override
  String get messageRead => 'Read';

  @override
  String get messageSent => 'Sent';

  @override
  String sayHello(String name) {
    return 'Say hello to $name 👋';
  }

  @override
  String get groupCreatedNote => 'You created this group';

  @override
  String get groupName => 'Group name';

  @override
  String get groupNameHint => 'e.g. Database Study Group';

  @override
  String get chooseMembers => 'Choose members';

  @override
  String membersSelected(int count) {
    return '$count selected';
  }

  @override
  String get createGroup => 'Create group';

  @override
  String get pickAtLeastTwo => 'Choose at least 2 members.';

  @override
  String get groupMembers => 'Members';

  @override
  String get sendMessage => 'Message';

  @override
  String get chatDemoNotice =>
      'Demo mode: replies are simulated until chat is connected to a server.';

  @override
  String get recipientEmail => 'Recipient\'s email';

  @override
  String get emailHint => 'name@campus.ac.id';

  @override
  String get firstMessage => 'First message';

  @override
  String get firstMessageHint => 'Say hi and introduce yourself...';

  @override
  String get firstMessageOptional => 'First message (optional)';

  @override
  String get startChatPrivacyNote =>
      'For privacy, people can only be found by their exact email address.';

  @override
  String get emailNotRegistered => 'This email isn\'t registered on Task Mate.';

  @override
  String get cannotChatWithSelf => 'You can\'t start a chat with yourself.';

  @override
  String get memberEmail => 'Member\'s email';

  @override
  String get memberAlreadyAdded => 'Already added.';

  @override
  String demoEmailsHint(String emails) {
    return 'Demo accounts: $emails';
  }

  @override
  String get chatServerError =>
      'Couldn\'t reach the server. Check your connection and try again.';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get logOut => 'Log out';

  @override
  String get defaultProfileName => 'Task Mate student';
}
