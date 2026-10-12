import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/services/user_directory.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_repository.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../community/services/firestore_community_repository.dart';
import '../../tasks/services/task_store.dart';
import '../../chat/services/firestore_chat_repository.dart';
import '../../chat/services/local_chat_repository.dart';
import '../../community/screens/communities_screen.dart';
import '../../community/screens/community_feed_screen.dart';
import '../../community/screens/create_community_screen.dart';
import '../../community/screens/create_post_screen.dart';
import '../../community/screens/search_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../tasks/screens/add_task_screen.dart';
import '../../tasks/screens/tasks_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    this.user,
    this.isLocalSession = false,
    this.localName,
    this.localEmail,
    super.key,
  }) : assert(isLocalSession || user != null);

  final User? user;
  final bool isLocalSession;
  final String? localName;
  final String? localEmail;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static const _homeIndex = 0;
  static const _tasksIndex = 1;
  static const _createIndex = 2;
  static const _communityIndex = 3;

  int _selectedIndex = _homeIndex;
  bool _isSigningOut = false;
  final _tasksKey = GlobalKey<TasksScreenState>();

  static const _profileIndex = 4;

  /// Name from the sign-in session.
  String? get _accountName =>
      (widget.user?.displayName ?? widget.localName)?.trim();

  /// The name edited in Profile, falling back to the account name.
  String? get _displayName {
    final edited = AppScope.of(context).profile.name?.trim();
    return edited != null && edited.isNotEmpty ? edited : _accountName;
  }

  AppServices? _services;
  String? _connectedUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services != null) return;
    _services = AppScope.of(context);
    _connectAccount();
  }

  @override
  void didUpdateWidget(MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The account (e.g. its display name) changed.
    if (oldWidget.user != widget.user) _connectAccount();
  }

  @override
  void dispose() {
    // Leaving the shell means the user signed out: stop listening to their
    // data and drop it (after this frame, as the tree is being torn down).
    final services = _services!;
    if (_connectedUid != null) {
      Future.microtask(() {
        final chat = services.chat;
        final community = services.community;
        if (chat is FirestoreChatRepository) chat.signOut();
        if (community is FirestoreCommunityRepository) community.signOut();
        services.tasks.switchStore(EmptyTaskStore());
      });
    }
    super.dispose();
  }

  /// Points chat, community, and tasks at the signed-in account.
  void _connectAccount() {
    final services = _services!;
    final chat = services.chat;
    final community = services.community;
    final user = widget.user;
    if (user == null || !services.online) {
      if (chat is LocalChatRepository) chat.myEmail = widget.localEmail ?? '';
      return;
    }
    if (chat is FirestoreChatRepository) {
      chat.signIn(
        uid: user.uid,
        name: UserDirectory.nameFor(user),
        email: user.email ?? '',
      );
    }
    if (_connectedUid == user.uid) return;
    _connectedUid = user.uid;
    if (community is FirestoreCommunityRepository) community.signIn(user.uid);
    services.tasks.switchStore(FirestoreTaskStore(user.uid));
  }

  /// Saves a name edited in Profile to the account, so chats show it too.
  Future<void> _updateAccountName(String name) async {
    if (widget.user == null) return;
    try {
      await AuthRepository().updateName(name);
    } catch (error) {
      debugPrint('Could not update the account name: $error');
    }
  }

  Future<void> _signOut() async {
    // Profile name edits belong to this account, not the next one.
    await AppScope.of(context).profile.clearName();
    if (!mounted) return;
    if (widget.isLocalSession) {
      // The demo session replaced the Login page; start over from Login.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(offlineMode: true),
        ),
        (_) => false,
      );
      return;
    }
    setState(() => _isSigningOut = true);
    try {
      await AuthRepository().signOut();
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AuthRepository.messageFor(error, AppLocalizations.of(context)),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  /// Like V3: after creating a task, show it at the top of the task list.
  Future<void> _openAddTask() async {
    final result = await Navigator.of(context).push<AddTaskResult>(
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    );
    if (result == null || !mounted) return;
    if (result.created) {
      setState(() => _selectedIndex = _tasksIndex);
      _tasksKey.currentState?.showNewest();
    } else if (result.tabIndex != null) {
      // A bottom-bar tab was tapped on the Add Task screen.
      setState(() => _selectedIndex = result.tabIndex!);
    }
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _openCreateActions() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        void open(Widget screen) {
          Navigator.of(sheetContext).pop();
          _push(screen);
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    l10n.navCreate,
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 8),
                _CreateAction(
                  icon: Icons.add_task_rounded,
                  title: l10n.newTask,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openAddTask();
                  },
                ),
                _CreateAction(
                  icon: Icons.edit_note_rounded,
                  title: l10n.newPost,
                  onTap: () => open(const CreatePostScreen()),
                ),
                _CreateAction(
                  icon: Icons.group_add_outlined,
                  title: l10n.newCommunity,
                  onTap: () => open(const CreateCommunityScreen()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _actions(AppLocalizations l10n) {
    return switch (_selectedIndex) {
      _homeIndex => [
        ListenableBuilder(
          listenable: AppScope.of(context).chat,
          builder: (context, _) {
            final unread = AppScope.of(context).chat.totalUnread;
            return IconButton(
              tooltip: l10n.chats,
              onPressed: () => _push(const ChatListScreen()),
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                backgroundColor: AppColors.skyBlue,
                child: const Icon(Icons.chat_bubble_outline_rounded),
              ),
            );
          },
        ),
      ],
      _tasksIndex => [
        IconButton(
          tooltip: l10n.calendar,
          onPressed: () => _push(const CalendarScreen()),
          icon: const Icon(Icons.calendar_month_rounded),
        ),
      ],
      _communityIndex => [
        IconButton(
          tooltip: l10n.search,
          onPressed: () => _push(const SearchScreen()),
          icon: const Icon(Icons.search_rounded),
        ),
        IconButton(
          tooltip: l10n.communities,
          onPressed: () => _push(const CommunitiesScreen()),
          icon: const Icon(Icons.groups_outlined),
        ),
      ],
      _profileIndex => [
        IconButton(
          tooltip: l10n.settings,
          onPressed: () => ProfileScreen.chooseStudyWeek(context),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      _ => const [],
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppScope.of(context).profile,
      builder: (context, _) => _buildShell(context),
    );
  }

  Widget _buildShell(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = _displayName;
    // Author name for new community posts and comments.
    AppScope.of(context).currentUserName = name == null || name.isEmpty
        ? l10n.defaultStudentName
        : name;
    final firstName = name?.split(' ').first;
    final titles = [
      l10n.navHome,
      l10n.navTasks,
      l10n.navCreate,
      l10n.navCommunity,
      l10n.navProfile,
    ];
    final pages = [
      HomeScreen(
        firstName: firstName == null || firstName.isEmpty
            ? (widget.isLocalSession ? l10n.defaultStudentName : null)
            : firstName,
        onSeeAllToday: () {
          setState(() => _selectedIndex = _tasksIndex);
          _tasksKey.currentState?.showToday();
        },
        onAddTask: _openAddTask,
      ),
      TasksScreen(key: _tasksKey),
      const SizedBox.shrink(),
      const CommunityFeedScreen(),
      ProfileScreen(
        accountName: _accountName,
        email: widget.user?.email ?? widget.localEmail ?? '',
        photoUrl: widget.user?.photoURL,
        isSigningOut: _isSigningOut,
        onSignOut: _signOut,
        onNameChanged: _updateAccountName,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        // The shell replaces the login route, so there is nothing to go
        // back to; hide the automatic back arrow.
        automaticallyImplyLeading: false,
        title: Text(titles[_selectedIndex]),
        actions: _actions(l10n),
      ),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          if (index == _createIndex) {
            _openCreateActions();
          } else {
            setState(() => _selectedIndex = index);
          }
        },
      ),
    );
  }
}

class _CreateAction extends StatelessWidget {
  const _CreateAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: CircleAvatar(
        backgroundColor: AppColors.skyBlue.withValues(alpha: 0.16),
        child: Icon(icon, color: AppColors.navy),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
