import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/sizer/app_sizer.dart';
import '../../core/utils/validators.dart';
import '../../controllers/theme_controller.dart';
import '../../enums/app.enum.dart';
import '../widgets/auth/auth_card.dart';
import '../widgets/auth/social_login_buttons.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  // Use ValueNotifier instead of Rx for local state (no GetX overhead)
  final _currentView = ValueNotifier<AuthView>(AuthView.login);
  final _isLoading = ValueNotifier<bool>(false);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Form keys for validation
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _forgotFormKey = GlobalKey<FormState>();

  // Welcome text streaming
  String _welcomeText = '';
  String _welcomeShown = '';
  Timer? _welcomeTimer;

  // Animation controller for card transitions
  late final AnimationController _animController;

  // Track if we're in forgot password loading state
  bool _isForgotPasswordLoading = false;

  @override
  void initState() {
    super.initState();
    _startWelcomeAnimation();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animController.value = 1.0;
  }

  @override
  void dispose() {
    _welcomeTimer?.cancel();
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _currentView.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  void _startWelcomeAnimation() {
    _welcomeText = AppStrings.authWelcome;
    _welcomeShown = '';
    _welcomeTimer?.cancel();
    _welcomeTimer = Timer.periodic(const Duration(milliseconds: 20), (t) {
      if (!mounted) return;
      if (_welcomeShown.length >= _welcomeText.length) {
        t.cancel();
        return;
      }
      setState(() {
        _welcomeShown = _welcomeText.substring(0, _welcomeShown.length + 1);
      });
    });
  }

  Future<void> _switchView(AuthView view) async {
    if (_currentView.value == view) return;

    await _animController.reverse();

    _currentView.value = view;
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();

    await _animController.forward();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    _isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 800));
    Get.offAllNamed(AppRoutes.home);
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    _isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 800));
    Get.offAllNamed(AppRoutes.home);
  }

  Future<void> _handleForgotPassword() async {
    if (!_forgotFormKey.currentState!.validate()) return;

    setState(() => _isForgotPasswordLoading = true);
    _isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 800));

    _currentView.value = AuthView.login;
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();

    await _animController.forward();

    _isLoading.value = false;
    setState(() => _isForgotPasswordLoading = false);

    Get.snackbar(
      AppStrings.authPasswordResetSent,
      AppStrings.authPasswordResetSentDesc,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeCtrl = Get.find<ThemeController>();

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 4.cw(context).clamp(16, 32),
                vertical: 4.ch(context).clamp(24, 48),
              ),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(theme),
                    SizedBox(height: 3.ch(context).clamp(20, 36)),
                    ValueListenableBuilder<bool>(
                      valueListenable: _isLoading,
                      builder: (context, isLoading, _) {
                        if (isLoading) {
                          return const CircularProgressIndicator();
                        }

                        return ValueListenableBuilder<AuthView>(
                          valueListenable: _currentView,
                          builder: (context, view, _) {
                            return _buildCurrentView(theme, view);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: IconButton(
              tooltip: AppTooltips.theme,
              onPressed: themeCtrl.toggleTheme,
              icon: Obx(
                () => Icon(
                  themeCtrl.isDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    // Hide welcome text during forgot password loading
    final showWelcome = !_isForgotPasswordLoading;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.appTitle,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 4.ch(context).clamp(28, 42),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 1.ch(context).clamp(8, 14)),
        SizedBox(
          height: 2.8.ch(context).clamp(20, 32),
          child:
              showWelcome
                  ? Text(
                    _welcomeShown.isEmpty ? ' ' : _welcomeShown,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.7,
                      ),
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildCurrentView(ThemeData theme, AuthView view) {
    switch (view) {
      case AuthView.login:
        return _buildLoginCard(theme);
      case AuthView.register:
        return _buildRegisterCard(theme);
      case AuthView.forgotPassword:
        return _buildForgotPasswordCard(theme);
    }
  }

  Widget _buildLoginCard(ThemeData theme) {
    return AuthCard(
      key: const ValueKey('login'),
      title: AppStrings.authLoginTitle,
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              textInputAction: TextInputAction.next,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: AppStrings.authEmail,
                prefixIcon: const Icon(Icons.email_outlined),
                filled: false,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            SizedBox(height: 1.6.ch(context).clamp(12, 20)),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: AppStrings.authPassword,
                prefixIcon: const Icon(Icons.lock_outlined),
                filled: false,
              ),
              obscureText: true,
              validator: Validators.loginPassword,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onFieldSubmitted: (_) => _handleLogin(),
            ),
            SizedBox(height: 2.4.ch(context).clamp(16, 28)),
            FilledButton(
              onPressed: _handleLogin,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 1.2.ch(context).clamp(10, 16),
                ),
                child: Text(AppStrings.authLogin),
              ),
            ),
            SizedBox(height: 1.6.ch(context).clamp(12, 20)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _switchView(AuthView.forgotPassword),
                  child: Text(AppStrings.authForgotPassword),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildSocialSection(theme),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.authNoAccount,
                  style: theme.textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: () => _switchView(AuthView.register),
                  child: Text(AppStrings.authRegister),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterCard(ThemeData theme) {
    return AuthCard(
      key: const ValueKey('register'),
      title: AppStrings.authRegisterTitle,
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: AppStrings.authEmail,
                prefixIcon: const Icon(Icons.email_outlined),
                filled: false,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            SizedBox(height: 1.6.ch(context).clamp(12, 20)),
            TextFormField(
              controller: _passwordController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: AppStrings.authPassword,
                prefixIcon: const Icon(Icons.lock_outlined),
                filled: false,
              ),
              obscureText: true,
              validator: Validators.registerPassword,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            SizedBox(height: 1.6.ch(context).clamp(12, 20)),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: AppStrings.authConfirmPassword,
                prefixIcon: const Icon(Icons.lock_outlined),
                filled: false,
              ),
              obscureText: true,
              validator:
                  (value) => Validators.confirmPasswordWith(
                    value,
                    _passwordController.text,
                  ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onFieldSubmitted: (_) => _handleRegister(),
            ),
            SizedBox(height: 2.4.ch(context).clamp(16, 28)),
            FilledButton(
              onPressed: _handleRegister,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 1.2.ch(context).clamp(10, 16),
                ),
                child: Text(AppStrings.authRegister),
              ),
            ),
            SizedBox(height: 1.6.ch(context).clamp(12, 20)),
            const Divider(height: 32),
            _buildSocialSection(theme),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.authHaveAccount,
                  style: theme.textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: () => _switchView(AuthView.login),
                  child: Text(AppStrings.authLogin),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForgotPasswordCard(ThemeData theme) {
    return AuthCard(
      key: const ValueKey('forgot'),
      title: AppStrings.authForgotPasswordTitle,
      child: Form(
        key: _forgotFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.authForgotPasswordDesc,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.0.ch(context).clamp(14, 24)),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: AppStrings.authEmail,
                prefixIcon: const Icon(Icons.email_outlined),
                filled: false,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onFieldSubmitted: (_) => _handleForgotPassword(),
            ),
            SizedBox(height: 2.4.ch(context).clamp(16, 28)),
            FilledButton(
              onPressed: _handleForgotPassword,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 1.2.ch(context).clamp(10, 16),
                ),
                child: Text(AppStrings.authSendResetLink),
              ),
            ),
            SizedBox(height: 1.6.ch(context).clamp(12, 20)),
            TextButton(
              onPressed: () => _switchView(AuthView.login),
              child: Text(AppStrings.authBackToLogin),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialSection(ThemeData theme) {
    return Column(
      children: [
        Text(
          AppStrings.authOrContinueWith,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          ),
        ),
        SizedBox(height: 1.2.ch(context).clamp(10, 16)),
        const SocialLoginButtons(),
      ],
    );
  }
}
