import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:usbs/config/routes/route_names.dart';
import 'package:usbs/config/theme/app_colors.dart';
import 'package:usbs/config/theme/app_text_styles.dart';
import 'package:usbs/core/localization/app_language.dart';
import 'package:usbs/core/widgets/logout_confirn_dialog.dart';
import 'package:usbs/core/widgets/translated_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<int> _carouselIndex = ValueNotifier<int>(0);

  String? _role;
  String _userDisplayName = 'Guest User';
  bool _isContactDialogOpen = false;

  final List<String> _images = const [
    'https://images.pexels.com/photos/6646918/pexels-photo-6646918.jpeg?auto=compress&cs=tinysrgb&w=1600',
    'https://images.pexels.com/photos/8613089/pexels-photo-8613089.jpeg?auto=compress&cs=tinysrgb&w=1600',
    'https://images.pexels.com/photos/5668473/pexels-photo-5668473.jpeg?auto=compress&cs=tinysrgb&w=1600',
    'https://images.pexels.com/photos/7578809/pexels-photo-7578809.jpeg?auto=compress&cs=tinysrgb&w=1600',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final img in _images) {
      precacheImage(
        NetworkImage(img),
        context,
        onError: (error, stackTrace) {},
      );
    }
    _loadRole();
  }

  @override
  void dispose() {
    _carouselIndex.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _role = null;
        _userDisplayName = 'Guest User';
      });
      return;
    }
    DocumentSnapshot<Map<String, dynamic>> doc;
    try {
      doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        if (!mounted) return;
        setState(() {
          _role = 'client';
          _userDisplayName =
              user.displayName ??
              (user.email?.split('@').first) ??
              'User';
        });
        return;
      }
      rethrow;
    }
    if (!mounted) return;
    setState(() {
      _role = doc.data()?['role']?.toString();
      _userDisplayName =
          (doc.data()?['name'] as String?)?.trim().isNotEmpty == true
          ? (doc.data()?['name'] as String).trim()
          : (user.displayName ?? (user.email?.split('@').first) ?? 'User');
    });
  }

  String t(String key) => AppI18n.tr(context, key);

  String _welcomeText() {
    final template = t('welcome_user');
    return template.replaceAll('{name}', _userDisplayName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.pageGradientSoft(context),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            _welcomeSection(),
            const SizedBox(height: 18),
            _carouselSection(),
            const SizedBox(height: 18),
            _servicesSection(),
            const SizedBox(height: 18),
            _workspaceSection(),
          ],
        ),
      ),
    );
  }

  Widget _welcomeSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: AppColors.isDark(context)
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E2C40), Color(0xFF26354A)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEAF3FF), Color(0xFFF7FAFF)],
                ),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _welcomeText(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.isDark(context)
                    ? Colors.white
                    : AppColors.secondary,
              ),
            ),
            const SizedBox(height: 4),
            TranslatedText(
              t('support_question'),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.isDark(context)
                    ? const Color(0xFFD6E3F8)
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carouselSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220A233D),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Column(
          children: [
            CarouselSlider.builder(
              itemCount: _images.length,
              options: CarouselOptions(
                height: 236,
                viewportFraction: 1,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration: const Duration(milliseconds: 1600),
                autoPlayCurve: Curves.easeInOutCubic,
                pauseAutoPlayOnTouch: false,
                pauseAutoPlayOnManualNavigate: false,
                onPageChanged: (index, _) {
                  _carouselIndex.value = index;
                },
              ),
              itemBuilder: (context, index, _) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      _images[index],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: Theme.of(context).colorScheme.surface,
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Theme.of(context).colorScheme.surface,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textMuted,
                          size: 32,
                        ),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x33000000), Color(0xAA102136)],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            t('ngo_name'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${t('ngo_tagline')}\n${t('supporting_communities')}',
                            style: const TextStyle(
                              color: Color(0xFFE8EEF8),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ValueListenableBuilder<int>(
                valueListenable: _carouselIndex,
                builder: (context, activeIndex, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _images.asMap().entries.map((entry) {
                    final isActive = activeIndex == entry.key;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOut,
                      width: isActive ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isActive
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.25),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _servicesSection() {
    final actions = <_ServiceAction>[
      _ServiceAction(
        title: t('legal_services'),
        subtitle: t('Submit legal support queries'),
        icon: Icons.gavel_outlined,
        route: RouteNames.legalInfo,
      ),
      _ServiceAction(
        title: t('medical_services'),
        subtitle: t('Ask medical guidance questions'),
        icon: Icons.local_hospital_outlined,
        route: RouteNames.medicalInfo,
      ),
      _ServiceAction(
        title: t('education_services'),
        subtitle: t('Get academic and admission help'),
        icon: Icons.school_outlined,
        route: RouteNames.educationInfo,
      ),
    ];

    return _actionGridSection(
      title: t('support_services'),
      actions: actions,
    );
  }

  Widget _workspaceSection() {
    final actions = <_ServiceAction>[
      _ServiceAction(
        title: t('my_queries'),
        subtitle: t('Track your submitted queries'),
        icon: Icons.history,
        route: RouteNames.myQueries,
      ),
      if (_role == 'admin' || _role == 'superadmin')
        _ServiceAction(
          title: t('answer_queries'),
          subtitle: t('Respond to assigned cases'),
          icon: Icons.support_agent_outlined,
          route: RouteNames.adminQueries,
        ),
      if (_role == 'superadmin')
        _ServiceAction(
          title: t('superadmin_dashboard'),
          subtitle: t('Track platform operations'),
          icon: Icons.query_stats_outlined,
          route: RouteNames.superadminDashboard,
        ),
    ];

    return _actionGridSection(
      title: t('workspace'),
      actions: actions,
    );
  }

  Widget _actionGridSection({
    required String title,
    required List<_ServiceAction> actions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.title),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 680;
            final itemWidth = isWide
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: actions.map((action) {
                return SizedBox(
                  width: itemWidth,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pushNamed(context, action.route),
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: AppColors.elevatedSurface(context),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x130A233D),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.softTeal,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(action.icon, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    action.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    action.subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0B4A45), Color(0xFF0D5F58)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                ),
        ),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu_rounded),
        ),
      ),
      title: Text(
        t('app_name'),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
      ),
      actions: [
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: userUnreadNotifications(),
          builder: (context, snapshot) {
            final count = snapshot.data?.docs.length ?? 0;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () =>
                      Navigator.pushNamed(context, RouteNames.notifications),
                ),
                if (count > 0)
                  Positioned(
                    right: 9,
                    top: 9,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: AppColors.accent,
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const LanguageMenuButton(),
      ],
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 54, 18, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.secondary, AppColors.primary],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.elevatedSurface(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset('assets/logo.png'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('ngo_name'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _welcomeText(),
                        style: const TextStyle(
                          color: Color(0xFFE3ECFA),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? t('Guest User'),
                        style: const TextStyle(
                          color: Color(0xFFD6E3F8),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              children: [
                _drawerTile(
                  icon: Icons.person_outline,
                  title: t('profile'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.profile);
                  },
                ),
                _drawerTile(
                  icon: Icons.info_outline,
                  title: t('about'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.about);
                  },
                ),
                _drawerTile(
                  icon: Icons.photo_library_outlined,
                  title: t('photo_gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.photoGallery);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('system')
                      .doc('publicContact')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final contact = snapshot.data?.data() ?? <String, dynamic>{};
                    final email =
                        (contact['email'] ?? 'support@usbsngo.org').toString();
                    final phone =
                        (contact['phone'] ?? '+91 98765 43210').toString();
                    final note = (contact['note'] ??
                            'This is a demo support line for app assistance.')
                        .toString();

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.elevatedSurface(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: TranslatedText(
                                  'Contact Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (_role == 'superadmin')
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: _isContactDialogOpen
                                      ? null
                                      : () => _openEditContactScreenFromDrawer(
                                            email: email,
                                            phone: phone,
                                            note: note,
                                          ),
                                ),
                            ],
                          ),
                          Text('${t('email_label')}: $email'),
                          Text('${t('phone_label')}: $phone'),
                          const SizedBox(height: 6),
                          Text(
                            '${t('note_label')}: $note',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _drawerTile(
                  icon: Icons.logout,
                  title: t('logout'),
                  tileColor: const Color(0xFFFFEBEE),
                  iconColor: const Color(0xFFC62828),
                  textColor: const Color(0xFFC62828),
                  onTap: () {
                    Navigator.pop(context);
                    LogoutConfirmDialog.show(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditContactScreenFromDrawer({
    required String email,
    required String phone,
    required String note,
  }) async {
    if (_isContactDialogOpen) return;
    setState(() => _isContactDialogOpen = true);

    try {
      // Close drawer first and wait for transition before route push.
      if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
        _scaffoldKey.currentState?.closeDrawer();
        await Future<void>.delayed(const Duration(milliseconds: 280));
      }
      if (!mounted) return;

      final didSave = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => _ContactDetailsEditScreen(
            initialEmail: email,
            initialPhone: phone,
            initialNote: note,
          ),
        ),
      );

      if (!mounted) return;
      if (didSave == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppI18n.tx(context, 'Contact details updated'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isContactDialogOpen = false);
      } else {
        _isContactDialogOpen = false;
      }
    }
  }

  Widget _drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? tileColor,
    Color? iconColor,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: TextStyle(color: textColor)),
        tileColor: tileColor ?? AppColors.elevatedSurface(context),
        onTap: onTap,
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> userUnreadNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots();
  }
}

class _ServiceAction {
  const _ServiceAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}

class _ContactDetailsEditScreen extends StatefulWidget {
  const _ContactDetailsEditScreen({
    required this.initialEmail,
    required this.initialPhone,
    required this.initialNote,
  });

  final String initialEmail;
  final String initialPhone;
  final String initialNote;

  @override
  State<_ContactDetailsEditScreen> createState() =>
      _ContactDetailsEditScreenState();
}

class _ContactDetailsEditScreenState extends State<_ContactDetailsEditScreen> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _noteCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
    _phoneCtrl = TextEditingController(text: widget.initialPhone);
    _noteCtrl = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('system').doc('publicContact').set({
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'note': _noteCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = (String s) => AppI18n.tx(context, s);
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: Theme.of(context).brightness == Brightness.dark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0B4A45), Color(0xFF0D5F58)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                  ),
          ),
        ),
        title: Text(t('edit_contact_details')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: InputDecoration(labelText: t('email_label')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneCtrl,
              decoration: InputDecoration(labelText: t('phone_label')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteCtrl,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(labelText: t('note_label')),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                    child: Text(t('Cancel')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t('Save')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
