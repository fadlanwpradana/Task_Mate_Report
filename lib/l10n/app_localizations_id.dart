// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Task Mate';

  @override
  String get back => 'Kembali';

  @override
  String get close => 'Tutup';

  @override
  String get cancel => 'Batal';

  @override
  String get save => 'Simpan';

  @override
  String get add => 'Tambah';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Hapus';

  @override
  String get seeAll => 'Lihat semua';

  @override
  String get today => 'Hari ini';

  @override
  String get tomorrow => 'Besok';

  @override
  String get splashTagline => 'Tugasmu. Komunitasmu.\nMasa Depanmu.';

  @override
  String get splashDescription =>
      'Kelola tugas, temukan teman belajar, dan berkembang bersama dalam satu aplikasi.';

  @override
  String get getStarted => 'Mulai';

  @override
  String get next => 'Lanjut';

  @override
  String get skip => 'Lewati';

  @override
  String get alreadyHaveAccount => 'Saya sudah punya akun';

  @override
  String get onboardTasksTitle => 'Kuasai setiap tugas';

  @override
  String get onboardTasksBody =>
      'Prioritas pintar memilih tugas yang perlu dikerjakan dulu, dengan pengingat sebelum deadline.';

  @override
  String get onboardCommunityTitle => 'Belajar bersama';

  @override
  String get onboardCommunityBody =>
      'Bertanya, berbagi catatan, dan gabung komunitas belajar.';

  @override
  String get onboardChatTitle => 'Chat dengan teman sekelas';

  @override
  String get onboardChatBody =>
      'Kirim pesan ke teman atau grup lewat email, privasi tetap terjaga.';

  @override
  String get onboardSampleTask => 'Selesaikan laporan ERD';

  @override
  String get onboardSampleTimeLeft => '05j 30m lagi';

  @override
  String get onboardSamplePost =>
      'Bagaimana cara pakai Firebase Auth di Flutter?';

  @override
  String get onboardSampleChat1 => 'ERD-nya sudah selesai?';

  @override
  String get onboardSampleChat2 => 'Hampir! Kukirim nanti malam';

  @override
  String get onboardSampleChat3 => 'Makasih, sampai ketemu di kelas!';

  @override
  String get welcomeBack => 'Selamat datang kembali';

  @override
  String get loginSubtitle => 'Masuk untuk melanjutkan belajarmu.';

  @override
  String get emailLabel => 'Alamat email';

  @override
  String get passwordLabel => 'Kata sandi';

  @override
  String get showPassword => 'Tampilkan kata sandi';

  @override
  String get hidePassword => 'Sembunyikan kata sandi';

  @override
  String get forgotPassword => 'Lupa kata sandi?';

  @override
  String get login => 'Masuk';

  @override
  String get noAccount => 'Belum punya akun? ';

  @override
  String get register => 'Daftar';

  @override
  String get passwordResetUnavailable =>
      'Reset kata sandi belum tersedia sampai autentikasi online dikonfigurasi.';

  @override
  String get enterEmailToReset =>
      'Masukkan email di atas untuk mereset kata sandi.';

  @override
  String get passwordResetSent => 'Email reset kata sandi telah dikirim.';

  @override
  String get createAccountTitle => 'Buat akun baru';

  @override
  String get registerSubtitle =>
      'Sedikit lebih teratur, satu tugas setiap kali.';

  @override
  String get fullNameLabel => 'Nama lengkap';

  @override
  String get passwordHelper => 'Gunakan minimal 8 karakter.';

  @override
  String get confirmPasswordLabel => 'Konfirmasi kata sandi';

  @override
  String get passwordsDoNotMatch => 'Kata sandi tidak cocok.';

  @override
  String get createAccount => 'Daftar';

  @override
  String get haveAccount => 'Sudah punya akun? Masuk';

  @override
  String fieldRequired(String label) {
    return '$label wajib diisi.';
  }

  @override
  String get invalidEmail => 'Masukkan alamat email yang valid.';

  @override
  String get passwordTooShort => 'Gunakan minimal 8 karakter.';

  @override
  String get authUserDisabled => 'Akun ini telah dinonaktifkan.';

  @override
  String get authWrongCredentials => 'Email atau kata sandi salah.';

  @override
  String get authEmailInUse => 'Email ini sudah terdaftar.';

  @override
  String get authWeakPassword => 'Pilih kata sandi yang lebih kuat.';

  @override
  String get authTooManyRequests =>
      'Terlalu banyak percobaan. Coba lagi nanti.';

  @override
  String get authNetwork => 'Periksa koneksi internet lalu coba lagi.';

  @override
  String get authNotEnabled =>
      'Login email dan kata sandi belum diaktifkan di proyek Firebase ini.';

  @override
  String get authFailed => 'Autentikasi gagal. Silakan coba lagi.';

  @override
  String get authAccountExists =>
      'Email ini sudah memakai metode login lain. Masuk dengan cara itu dulu.';

  @override
  String get continueWithGoogle => 'Lanjutkan dengan Google';

  @override
  String get orDivider => 'atau';

  @override
  String get googleSignInFailed => 'Login Google gagal. Silakan coba lagi.';

  @override
  String get navHome => 'Beranda';

  @override
  String get navTasks => 'Tugas';

  @override
  String get navCreate => 'Buat';

  @override
  String get navCommunity => 'Komunitas';

  @override
  String get navProfile => 'Profil';

  @override
  String get chat => 'Chat';

  @override
  String comingSoon(String feature) {
    return '$feature akan ditambahkan pada tahap berikutnya.';
  }

  @override
  String get newTask => 'Tugas baru';

  @override
  String get newPost => 'Postingan komunitas';

  @override
  String get newCommunity => 'Komunitas baru';

  @override
  String helloName(String name) {
    return 'Halo, $name 👋';
  }

  @override
  String get hello => 'Halo 👋';

  @override
  String get defaultStudentName => 'Mahasiswa';

  @override
  String get homeSubtitle => 'Semangat terus untuk hari ini!';

  @override
  String get taskProgress => 'Progres tugas';

  @override
  String tasksCompleted(int done, int total) {
    return '$done dari $total tugas selesai';
  }

  @override
  String get noTasksProgress =>
      'Progresmu akan muncul setelah kamu menambahkan tugas.';

  @override
  String get priorityTask => 'Tugas Prioritas';

  @override
  String get allTasksCompleted => 'Semua tugas selesai! 🎉';

  @override
  String get todaysTasks => 'Tugas hari ini';

  @override
  String get noActiveTasksToday => 'Tidak ada tugas aktif untuk hari ini.';

  @override
  String get addTask => 'Tambah tugas';

  @override
  String myTasksSummary(int active, int week) {
    return '$active tugas · $week jatuh tempo minggu ini';
  }

  @override
  String get searchTasksHint => 'Cari tugas...';

  @override
  String get filterAll => 'Semua';

  @override
  String get filterToday => 'Hari ini';

  @override
  String get filterUpcoming => 'Mendatang';

  @override
  String get filterCompleted => 'Selesai';

  @override
  String get sortTasks => 'Urutkan tugas';

  @override
  String get sortTasksBy => 'Urutkan tugas berdasarkan';

  @override
  String get sortPriority => 'Prioritas (disarankan)';

  @override
  String get sortNewest => 'Terbaru';

  @override
  String get sortDeadline => 'Deadline';

  @override
  String get sortTitle => 'Judul';

  @override
  String get noTasksInView => 'Tidak ada tugas di tampilan ini';

  @override
  String get noCompletedTasks => 'Belum ada tugas yang selesai';

  @override
  String get checkOffHint => 'Centang tugas saat kamu menyelesaikannya.';

  @override
  String get noResults => 'Tidak ada hasil.';

  @override
  String get calendar => 'Kalender';

  @override
  String get priorityHigh => 'Tinggi';

  @override
  String get priorityMedium => 'Sedang';

  @override
  String get priorityLow => 'Rendah';

  @override
  String priorityPill(String level) {
    return 'PRIORITAS $level';
  }

  @override
  String daysLeft(int count) {
    return '$count hari lagi';
  }

  @override
  String hoursMinutesLeft(String hours, String minutes) {
    return '${hours}j ${minutes}m lagi';
  }

  @override
  String daysOverdue(int count) {
    return 'Terlambat $count hari';
  }

  @override
  String hoursOverdue(int count) {
    return 'Terlambat $count jam';
  }

  @override
  String minutesOverdue(int count) {
    return 'Terlambat $count menit';
  }

  @override
  String get overdueBadge => 'TERLAMBAT';

  @override
  String get completedLabel => 'Selesai';

  @override
  String progressPercent(int percent) {
    return 'Progres $percent%';
  }

  @override
  String get turnReminderOn => 'Nyalakan pengingat';

  @override
  String get turnReminderOff => 'Matikan pengingat';

  @override
  String get addTaskTitle => 'Tambah Tugas';

  @override
  String get addTaskSubtitle =>
      'Pecah tugas besar menjadi langkah-langkah kecil';

  @override
  String get titleLabel => 'Judul';

  @override
  String get taskTitleHint => 'mis. Selesaikan laporan praktikum';

  @override
  String get descriptionLabel => 'Deskripsi';

  @override
  String get taskDescriptionHint =>
      'Tambahkan catatan, link, atau ketentuan...';

  @override
  String get categoryLabel => 'Kategori';

  @override
  String get categoryAcademic => 'Akademik';

  @override
  String get categoryProject => 'Proyek';

  @override
  String get categoryMeeting => 'Rapat';

  @override
  String get categoryPresentation => 'Presentasi';

  @override
  String get categoryPersonal => 'Pribadi';

  @override
  String get categoryQuiz => 'Kuis';

  @override
  String get categoryExamination => 'Ujian';

  @override
  String get deadline => 'Deadline';

  @override
  String get selectDeadlineDate => 'Pilih tanggal deadline';

  @override
  String get selectDeadlineTime => 'Pilih jam deadline';

  @override
  String get priority => 'Prioritas';

  @override
  String get reminder => 'Pengingat';

  @override
  String get reminderSchedule => '1 hari & 1 jam sebelum';

  @override
  String get subtasks => 'Subtugas';

  @override
  String get addSubtask => 'Tambah subtugas';

  @override
  String get subtaskLabel => 'Subtugas';

  @override
  String get enterSubtaskHint => 'Masukkan subtugas';

  @override
  String get defaultSubtask => 'Buat draf pendahuluan';

  @override
  String get enterSubtaskError => 'Masukkan subtugas.';

  @override
  String removeSubtask(String name) {
    return 'Hapus $name';
  }

  @override
  String get createTask => 'Buat Tugas';

  @override
  String get creatingTask => 'Membuat...';

  @override
  String get enterTaskTitle => 'Masukkan judul tugas.';

  @override
  String get chooseFutureDeadline => 'Pilih deadline di masa depan.';

  @override
  String get taskDetails => 'Detail Tugas';

  @override
  String get moreOptions => 'Opsi lainnya';

  @override
  String get progress => 'Progres';

  @override
  String subtasksCount(int done, int total) {
    return '$done dari $total';
  }

  @override
  String get noSubtasksYet =>
      'Belum ada subtugas. Tambahkan untuk memecah tugas ini menjadi langkah-langkah.';

  @override
  String get reminderSet => 'Pengingat aktif';

  @override
  String get reminderOff => 'Pengingat mati';

  @override
  String get tapToEnable => 'Ketuk untuk mengaktifkan';

  @override
  String nextReminder(String time) {
    return 'Berikutnya: $time';
  }

  @override
  String get noUpcomingReminder => 'Tidak ada pengingat berikutnya';

  @override
  String get markComplete => 'Tandai Selesai';

  @override
  String get markActive => 'Tandai aktif';

  @override
  String get editTask => 'Edit tugas';

  @override
  String get deleteTask => 'Hapus tugas';

  @override
  String get deleteTaskQuestion => 'Hapus tugas?';

  @override
  String get deleteTaskMessage => 'Tugas ini akan dihapus dari daftar tugasmu.';

  @override
  String get taskName => 'Nama tugas';

  @override
  String get enterTaskName => 'Masukkan nama tugas.';

  @override
  String get reminderChannelName => 'Pengingat tugas';

  @override
  String get reminderChannelDescription => 'Pengingat sebelum deadline tugasmu';

  @override
  String reminderDayBody(String time) {
    return 'Deadline besok pukul $time. Jangan lupa!';
  }

  @override
  String reminderHourBody(String time) {
    return 'Deadline 1 jam lagi, pukul $time.';
  }

  @override
  String tasksForDate(String date) {
    return 'Tugas $date';
  }

  @override
  String get noTasksOnDay => 'Tidak ada tugas di hari ini.';

  @override
  String get previousMonth => 'Bulan sebelumnya';

  @override
  String get nextMonth => 'Bulan berikutnya';

  @override
  String get forYou => 'Untuk Kamu';

  @override
  String get following => 'Mengikuti';

  @override
  String get trending => 'Trending';

  @override
  String get searchCommunityHint => 'Cari postingan, komunitas, atau topik...';

  @override
  String get filterPosts => 'Filter postingan';

  @override
  String get allTypes => 'Semua jenis';

  @override
  String get postTypeDiscussion => 'Diskusi';

  @override
  String get postTypeQuestion => 'Pertanyaan';

  @override
  String get postTypeAssignment => 'Tugas Kuliah';

  @override
  String get noPostsTitle => 'Belum ada postingan';

  @override
  String get noPostsDescription => 'Jadilah yang pertama memulai diskusi.';

  @override
  String get noFollowingPosts =>
      'Gabung komunitas untuk melihat postingannya di sini.';

  @override
  String get communities => 'Komunitas';

  @override
  String get like => 'Suka';

  @override
  String get bookmark => 'Simpan';

  @override
  String get removeBookmark => 'Hapus dari simpanan';

  @override
  String get justNow => 'baru saja';

  @override
  String minutesAgo(int count) {
    return '$count menit lalu';
  }

  @override
  String hoursAgo(int count) {
    return '$count jam lalu';
  }

  @override
  String daysAgo(int count) {
    return '$count hari lalu';
  }

  @override
  String get createPost => 'Buat postingan';

  @override
  String get postTitleLabel => 'Judul';

  @override
  String get postTitleHint => 'Masukkan judul...';

  @override
  String get postDescriptionHint => 'Tulis detail pertanyaan atau diskusi...';

  @override
  String get tags => 'Tag';

  @override
  String get addTag => 'Tambah tag';

  @override
  String get tagHint => 'mis. Flutter';

  @override
  String get communityOptional => 'Komunitas (opsional)';

  @override
  String get noCommunity => 'Tanpa komunitas';

  @override
  String get publish => 'Posting';

  @override
  String get postPublished => 'Postingan dibagikan';

  @override
  String get post => 'Postingan';

  @override
  String get comments => 'Komentar';

  @override
  String get noComments => 'Belum ada komentar. Mulai percakapan!';

  @override
  String get writeComment => 'Tulis komentar...';

  @override
  String get send => 'Kirim';

  @override
  String get reply => 'Balas';

  @override
  String get searchCommunitiesHint => 'Cari komunitas...';

  @override
  String get filterPopular => 'Populer';

  @override
  String get filterJoined => 'Diikuti';

  @override
  String get categoryCourse => 'Mata Kuliah';

  @override
  String get categoryMajor => 'Jurusan';

  @override
  String get categoryGeneral => 'Umum';

  @override
  String membersCount(int count) {
    return '$count anggota';
  }

  @override
  String postsCount(int count) {
    return '$count postingan';
  }

  @override
  String get join => 'Gabung';

  @override
  String get joined => 'Bergabung';

  @override
  String get noCommunities => 'Komunitas tidak ditemukan.';

  @override
  String get communityNoPosts => 'Belum ada postingan di komunitas ini.';

  @override
  String get createCommunity => 'Buat komunitas';

  @override
  String get communityColor => 'Warna komunitas';

  @override
  String get communityNameLabel => 'Nama komunitas';

  @override
  String get communityNameHint => 'Masukkan nama komunitas...';

  @override
  String get communityDescriptionHint => 'Jelaskan tentang komunitas ini...';

  @override
  String get topicLabel => 'Mata Kuliah / Topik';

  @override
  String get topicHint => 'mis. Sistem Basis Data';

  @override
  String get visibilityPublic => 'Publik';

  @override
  String get visibilityPublicDescription => 'Bisa dilihat semua orang';

  @override
  String get visibilityPrivate => 'Privat';

  @override
  String get visibilityPrivateDescription =>
      'Hanya anggota yang bisa melihat postingan';

  @override
  String get communityCreated => 'Komunitas dibuat';

  @override
  String get search => 'Cari';

  @override
  String get searchHint => 'Cari postingan dan komunitas...';

  @override
  String get searchPrompt => 'Ketik untuk mencari postingan dan komunitas.';

  @override
  String get posts => 'Postingan';

  @override
  String get profileSubtitle => 'Ruang Task Mate kamu';

  @override
  String get settings => 'Pengaturan';

  @override
  String get editProfile => 'Edit profil';

  @override
  String get nameLabel => 'Nama';

  @override
  String get studyProgram => 'Program studi';

  @override
  String get studyProgramHint => 'mis. S1 Psikologi · Tahun 2';

  @override
  String get nameEmpty => 'Nama tidak boleh kosong.';

  @override
  String dayStreak(int count) {
    return 'STREAK $count HARI';
  }

  @override
  String get notificationSettings => 'Pengaturan notifikasi';

  @override
  String get taskRemindersSetting => 'Pengingat tugas';

  @override
  String get taskRemindersDescription => '1 hari & 1 jam sebelum deadline';

  @override
  String get weeklyEncouragement => 'Semangat mingguan';

  @override
  String get weeklyEncouragementDescription =>
      'Rekap progres setiap hari Minggu';

  @override
  String get groupUpdates => 'Update tugas kelompok';

  @override
  String get groupUpdatesDescription => 'Perubahan dari teman sekelas';

  @override
  String get appSettings => 'Pengaturan aplikasi';

  @override
  String get studyWeekStarts => 'Minggu belajar dimulai';

  @override
  String get monday => 'Senin';

  @override
  String get sunday => 'Minggu';

  @override
  String get appearance => 'Tampilan';

  @override
  String get appearanceLight => 'Terang';

  @override
  String get appearanceDark => 'Gelap';

  @override
  String get appearanceSystem => 'Ikuti sistem';

  @override
  String get helpFeedback => 'Bantuan & masukan';

  @override
  String get helpFeedbackMessage =>
      'Butuh bantuan dengan Task Mate? Sampaikan masukan atau laporkan masalah ke admin aplikasimu.';

  @override
  String get logOutQuestion => 'Keluar?';

  @override
  String get logOutMessage => 'Kamu perlu masuk lagi untuk memakai Task Mate.';

  @override
  String get remindersOffInProfile => 'Pengingat tugas dimatikan di Profil';

  @override
  String get weeklyRecapTitle => 'Rekap mingguan';

  @override
  String get weeklyRecapBody =>
      'Luangkan waktu sebentar untuk melihat progres minggu ini di Task Mate 💪';

  @override
  String get chats => 'Pesan';

  @override
  String get newChat => 'Chat baru';

  @override
  String get newGroup => 'Grup baru';

  @override
  String get searchChatsHint => 'Cari chat...';

  @override
  String get noChats => 'Belum ada chat';

  @override
  String get noChatsDescription => 'Mulai percakapan dengan teman sekelas.';

  @override
  String get you => 'Kamu';

  @override
  String youPrefix(String text) {
    return 'Kamu: $text';
  }

  @override
  String senderPrefix(String name, String text) {
    return '$name: $text';
  }

  @override
  String get messageHint => 'Ketik pesan...';

  @override
  String get typing => 'sedang mengetik...';

  @override
  String userTyping(String name) {
    return '$name sedang mengetik...';
  }

  @override
  String get yesterday => 'Kemarin';

  @override
  String get messageRead => 'Dibaca';

  @override
  String get messageSent => 'Terkirim';

  @override
  String sayHello(String name) {
    return 'Sapa $name 👋';
  }

  @override
  String get groupCreatedNote => 'Kamu membuat grup ini';

  @override
  String get groupName => 'Nama grup';

  @override
  String get groupNameHint => 'mis. Grup Belajar Basis Data';

  @override
  String get chooseMembers => 'Pilih anggota';

  @override
  String membersSelected(int count) {
    return '$count dipilih';
  }

  @override
  String get createGroup => 'Buat grup';

  @override
  String get pickAtLeastTwo => 'Pilih minimal 2 anggota.';

  @override
  String get groupMembers => 'Anggota';

  @override
  String get sendMessage => 'Kirim pesan';

  @override
  String get chatDemoNotice =>
      'Mode demo: balasan masih simulasi sampai chat tersambung ke server.';

  @override
  String get recipientEmail => 'Email tujuan';

  @override
  String get emailHint => 'nama@kampus.ac.id';

  @override
  String get firstMessage => 'Pesan pertama';

  @override
  String get firstMessageHint => 'Sapa dan perkenalkan dirimu...';

  @override
  String get firstMessageOptional => 'Pesan pertama (opsional)';

  @override
  String get startChatPrivacyNote =>
      'Demi privasi, pengguna hanya bisa ditemukan dengan alamat email lengkap.';

  @override
  String get emailNotRegistered => 'Email ini belum terdaftar di Task Mate.';

  @override
  String get cannotChatWithSelf =>
      'Kamu tidak bisa memulai chat dengan dirimu sendiri.';

  @override
  String get memberEmail => 'Email anggota';

  @override
  String get memberAlreadyAdded => 'Sudah ditambahkan.';

  @override
  String demoEmailsHint(String emails) {
    return 'Akun demo: $emails';
  }

  @override
  String get chatServerError =>
      'Tidak bisa terhubung ke server. Periksa koneksimu lalu coba lagi.';

  @override
  String get language => 'Bahasa';

  @override
  String get chooseLanguage => 'Pilih bahasa';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get logOut => 'Keluar';

  @override
  String get defaultProfileName => 'Mahasiswa Task Mate';
}
