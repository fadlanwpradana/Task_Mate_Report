import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_mate_v4/app.dart';
import 'package:task_mate_v4/core/app_scope.dart';
import 'package:task_mate_v4/core/services/notification_service.dart';
import 'package:task_mate_v4/core/services/storage_service.dart';
import 'package:task_mate_v4/core/theme/app_theme.dart';
import 'package:task_mate_v4/features/profile/services/profile_settings.dart';
import 'package:task_mate_v4/models/task_model.dart';

class _RecordingReminders extends ReminderScheduler {
  final synced = <String>[];

  @override
  Future<void> syncTask(TaskModel task) async => synced.add(task.id);

  @override
  Future<void> cancelTask(String taskId) async {}
}

Future<AppServices> _signIn(
  WidgetTester tester, {
  AppServices? services,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  final appServices = services ?? AppServices.fromStorage(StorageService());
  // Not a first launch: go straight to Login.
  await appServices.onboarding.complete();
  await tester.pumpWidget(
    TaskMateApp(offlineMode: true, services: appServices),
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), 'raka@example.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'password123');
  await tester.tap(find.text('Login'));
  await tester.pumpAndSettle();
  return appServices;
}

void main() {
  testWidgets('Creates a task, checks a subtask, and marks it complete', (
    tester,
  ) async {
    final reminders = _RecordingReminders();
    final services = await _signIn(
      tester,
      services: AppServices.fromStorage(StorageService(), reminders: reminders),
    );
    final initialCount = services.tasks.tasks.length;

    await tester.tap(find.byTooltip('Create').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();
    expect(find.text('Add Task'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Study SQL joins');
    await tester.tap(find.text('Add subtask'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Watch lecture');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await _reveal(tester, find.text('Create Task'));
    await tester.tap(find.text('Create Task'));
    await tester.pumpAndSettle();

    // Like V3, creating a task lands on the task list, newest first.
    expect(services.tasks.tasks.length, initialCount + 1);
    final created = services.tasks.tasks.first;
    expect(created.title, 'Study SQL joins');
    expect(created.category, 'academic');
    expect(reminders.synced, contains(created.id));
    expect(find.text('Study SQL joins'), findsOneWidget);

    await tester.tap(find.text('Study SQL joins'));
    await tester.pumpAndSettle();
    expect(find.text('Task Details'), findsOneWidget);
    expect(find.text('0 of 2'), findsOneWidget);

    await tester.tap(find.text('Watch lecture'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 2'), findsOneWidget);
    // Checking every subtask does not complete the task.
    expect(services.tasks.byId(created.id)!.isCompleted, isFalse);

    await tester.tap(find.text('Mark Complete'));
    await tester.pumpAndSettle();
    expect(services.tasks.byId(created.id)!.isCompleted, isTrue);
    // Back on the list, now showing completed tasks.
    expect(find.text('Study SQL joins'), findsOneWidget);
  });

  testWidgets('Task screens fit a small phone in Indonesian', (tester) async {
    SharedPreferences.setMockInitialValues({'locale': 'id'});
    final prefs = await SharedPreferences.getInstance();
    final services = AppServices.fromStorage(StorageService(prefs));
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(TaskMateApp(offlineMode: true, services: services));
    await tester.pumpAndSettle();
    // First launch, in Indonesian, through the welcome carousel.
    expect(find.text('Kuasai setiap tugas'), findsOneWidget);
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    expect(find.text('Chat dengan teman sekelas'), findsOneWidget);
    await tester.tap(find.text('Saya sudah punya akun'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.co');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Tugas Prioritas'), findsOneWidget);

    await tester.tap(find.text('Tugas').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(services.tasks.tasks.first.title));
    await tester.pumpAndSettle();
    expect(find.text('Detail Tugas'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Buat').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tugas baru'));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Tugas'), findsOneWidget);
  });

  testWidgets('Profile: edit name, dark mode, and settings are saved', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final services = await _signIn(
      tester,
      services: AppServices.fromStorage(StorageService(prefs)),
    );

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Your Task Mate space'), findsOneWidget);

    // Edit profile updates the name everywhere.
    await tester.tap(find.byTooltip('Edit profile').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Raka Pratama');
    await tester.enterText(
      find.byType(TextField).at(1),
      'Informatics · Year 2',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Raka Pratama'), findsOneWidget);
    expect(find.text('Informatics · Year 2'), findsOneWidget);
    expect(services.currentUserName, 'Raka Pratama');

    // Appearance → Dark switches the whole app to dark colors.
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(AppColors.isDark, isTrue);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    final theme = Theme.of(tester.element(find.byWidget(scaffold)));
    expect(theme.brightness, Brightness.dark);

    // Study week start and notification switches persist.
    await tester.tap(find.text('Study week starts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sunday'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weekly encouragement'));
    await tester.pumpAndSettle();

    final restored = AppServices.fromStorage(StorageService(prefs)).profile;
    expect(restored.name, 'Raka Pratama');
    expect(restored.appearance, AppAppearance.dark);
    expect(restored.weekStartsMonday, isFalse);
    expect(restored.weeklyEncouragement, isFalse);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(find.text('Hello, Raka 👋'), findsOneWidget);
    AppColors.setDark(false);
  });

  test('Study streak counts consecutive days with completed tasks', () async {
    final tasks = AppServices.fromStorage(StorageService()).tasks;
    expect(tasks.currentStreak(), 0);
    final ids = tasks.tasks.map((t) => t.id).toList();
    final now = DateTime.now();
    const daysAgo = [0, 1, 2, 4];
    for (var i = 0; i < daysAgo.length; i++) {
      final task = tasks.byId(ids[i])!;
      await tasks.update(
        task.copyWith(
          isCompleted: true,
          completedAt: () => now.subtract(Duration(days: daysAgo[i])),
        ),
      );
    }
    // Today, yesterday, and the day before; the gap breaks the streak.
    expect(tasks.currentStreak(), 3);
  });

  testWidgets('Chat: open a chat, send, get a reply, and read receipts', (
    tester,
  ) async {
    final services = await _signIn(
      tester,
      services: AppServices.fromStorage(
        StorageService(),
        chatReplyDelay: const Duration(milliseconds: 300),
      ),
    );
    final chat = services.chat;
    expect(chat.totalUnread, 2);

    await tester.tap(find.byTooltip('Chats').first);
    await tester.pumpAndSettle();
    expect(find.text('Sari Dewi'), findsOneWidget);
    expect(find.text('Database Study Group'), findsOneWidget);

    await tester.tap(find.text('Sari Dewi'));
    await tester.pumpAndSettle();
    final conversation = chat.conversations.firstWhere(
      (c) => c.id == 'chat-sari',
    );
    expect(chat.unreadCount(conversation), 0);

    await tester.enterText(find.byType(TextField).last, 'Sure, sending now!');
    await tester.tap(find.byTooltip('Send').first);
    await tester.pump();
    expect(find.text('Sure, sending now!'), findsOneWidget);
    // One grey tick: sent, not read yet.
    expect(find.byIcon(Icons.done_rounded), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('typing...'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    final updated = chat.byId('chat-sari')!;
    expect(updated.messages.last.senderId, 'sari');
    expect(updated.messages[updated.messages.length - 2].isRead, isTrue);
    expect(chat.unreadCount(updated), 0);
  });

  testWidgets('Chat: create a group chat', (tester) async {
    final services = await _signIn(tester);

    await tester.tap(find.byTooltip('Chats').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('New chat').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('New group'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Mobile Squad');
    await _reveal(tester, find.text('Create group'));
    await tester.tap(find.text('Create group'));
    await tester.pumpAndSettle();
    expect(find.text('Choose at least 2 members.'), findsOneWidget);

    final emailField = find.widgetWithText(TextField, "Member's email");
    Future<void> addMember(String email) async {
      await tester.enterText(emailField, email);
      await tester.tap(find.byTooltip('Add').first);
      await tester.pumpAndSettle();
    }

    await addMember('nobody@campus.ac.id');
    expect(find.text("This email isn't registered on Task Mate."), findsOne);
    await addMember('sari@taskmate.demo');
    await addMember('BUDI@taskmate.demo ');
    expect(find.text('Sari Dewi'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
    await addMember('sari@taskmate.demo');
    expect(find.text('Already added.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Say hi and introduce yourself...'),
      'Welcome to the squad!',
    );
    await _reveal(tester, find.text('Create group'));
    await tester.tap(find.text('Create group'));
    await tester.pump();

    final group = services.chat.conversations.first;
    expect(group.isGroup, isTrue);
    expect(group.title, 'Mobile Squad');
    expect(group.memberIds, ['sari', 'budi']);
    expect(group.messages.first.text, 'Welcome to the squad!');
    expect(find.text('Mobile Squad'), findsOneWidget);
    // Let the simulated reply finish.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Chat: start a chat with an email and a first message', (
    tester,
  ) async {
    final services = await _signIn(tester);

    await tester.tap(find.byTooltip('Chats').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('New chat').first);
    await tester.pumpAndSettle();
    // Privacy: no list of people to browse.
    expect(find.text('Rina Oktavia'), findsNothing);

    final emailField = find.widgetWithText(TextFormField, 'name@campus.ac.id');
    final messageField = find.widgetWithText(
      TextFormField,
      'Say hi and introduce yourself...',
    );
    Future<void> send() async {
      await _reveal(tester, find.text('Send'));
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
    }

    await tester.enterText(emailField, 'unknown@campus.ac.id');
    await tester.enterText(messageField, 'Hi Rina!');
    await send();
    expect(find.text("This email isn't registered on Task Mate."), findsOne);

    await tester.enterText(emailField, 'raka@example.com');
    await send();
    expect(find.text("You can't start a chat with yourself."), findsOne);

    await tester.enterText(emailField, 'rina@taskmate.demo');
    await _reveal(tester, find.text('Send'));
    await tester.tap(find.text('Send'));
    await tester.pump();
    await tester.pump();

    final chat = services.chat;
    final conversation = chat.conversations.first;
    expect(conversation.isGroup, isFalse);
    expect(conversation.memberIds, ['rina']);
    expect(conversation.messages.single.text, 'Hi Rina!');
    expect(find.text('Rina Oktavia'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  test('Chat: reuses one-on-one chats and saves them', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final chat = AppServices.fromStorage(StorageService(prefs)).chat;
    final first = await chat.directChatWith('rina');
    final again = await chat.directChatWith('rina');
    expect(again, first);

    final restored = AppServices.fromStorage(StorageService(prefs)).chat;
    expect(restored.byId(first), isNotNull);
    chat.dispose();
    restored.dispose();
  });

  testWidgets("Home's Today's tasks 'See all' opens the Today filter", (
    tester,
  ) async {
    await _signIn(tester);
    await _reveal(tester, find.text('See all'));
    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    final todayChip = tester.widget<ChoiceChip>(
      find.ancestor(of: find.text('Today'), matching: find.byType(ChoiceChip)),
    );
    expect(todayChip.selected, isTrue);
    // Sample data: one task due today, the rest later.
    expect(find.text('Psychology research outlines'), findsOneWidget);
    expect(find.text('Calculus problem set 6'), findsNothing);
  });

  testWidgets('Add Task rejects an empty title', (tester) async {
    final services = await _signIn(tester);
    final initialCount = services.tasks.tasks.length;

    await tester.tap(find.byTooltip('Create').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();
    await _reveal(tester, find.text('Create Task'));
    await tester.tap(find.text('Create Task'));
    await tester.pumpAndSettle();

    expect(services.tasks.tasks.length, initialCount);
    await _reveal(tester, find.text('Enter a task title.'), up: true);
    expect(find.text('Enter a task title.'), findsOneWidget);
  });

  testWidgets('Publishes a post and comments on it', (tester) async {
    final services = await _signIn(tester);

    await tester.tap(find.byTooltip('Create').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Community post'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Best SQL book?');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Looking for recommendations.',
    );
    await _reveal(tester, find.text('Post'));
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    final post = services.community.posts.first;
    expect(post.title, 'Best SQL book?');
    expect(post.authorName, 'Student');

    await tester.tap(find.text('Community').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Best SQL book?'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).last,
      'Try "SQL Antipatterns".',
    );
    await tester.tap(find.byTooltip('Send').first);
    await tester.pumpAndSettle();

    expect(find.text('Try "SQL Antipatterns".'), findsOneWidget);
    expect(services.community.postById(post.id)!.comments, hasLength(1));
  });

  testWidgets('Switches the language to Indonesian from Profile', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final services = await _signIn(
      tester,
      services: AppServices.fromStorage(StorageService(prefs)),
    );

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await _reveal(tester, find.text('Language'));
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bahasa Indonesia'));
    await tester.pumpAndSettle();

    expect(find.text('Bahasa'), findsOneWidget);
    expect(find.text('Pengaturan aplikasi'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(services.locale.value.languageCode, 'id');
    expect(prefs.getString('locale'), 'id');
  });

  test('Tasks and posts are saved and restored from storage', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = AppServices.fromStorage(StorageService(prefs));
    final task = first.tasks.tasks.first;
    await first.tasks.setCompleted(task.id, !task.isCompleted);
    await first.community.toggleJoin('database');

    final restored = AppServices.fromStorage(StorageService(prefs));
    expect(restored.tasks.byId(task.id)!.isCompleted, !task.isCompleted);
    expect(restored.community.communityById('database')!.joined, isTrue);
  });
}

/// Scrolls the screen's main list until [finder] is fully on screen.
Future<void> _reveal(
  WidgetTester tester,
  Finder finder, {
  bool up = false,
}) async {
  await tester.scrollUntilVisible(
    finder,
    up ? -300 : 300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}
