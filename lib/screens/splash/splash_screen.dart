import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/app_database.dart';
import '../../core/database/seed_data.dart';
import '../../core/theme/app_tokens.dart';
import '../../modules/business_registry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../auth/login_screen.dart';
import '../sector_selection/sector_selection_screen.dart';
import '../main_layout_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late Animation<double> _pulse;
  late Animation<double> _fade;
  late Animation<double> _slide;
  String _statusText = 'Initializing OminiPOS...';
  bool _isInitializing = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // One-shot entrance controller for fade & slide
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Continuous breathing glow for the logo only
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Gentle breathing glow behind the logo (loops independently without affecting fade/slide)
    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // One-shot entrance for the content block (runs once and stays fully visible)
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _slide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();
    _pulseController.repeat(reverse: true);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (_isInitializing) return;
    _isInitializing = true;
    final stopwatch = Stopwatch()..start();

    try {
      BusinessModuleRegistry.init();

      setState(() => _statusText = 'Checking database schema...');
      final db = await AppDatabase.instance.database;

      setState(() => _statusText = 'Preloading seed data...');
      await SeedData.populateAllSeedData(db);

      setState(() => _statusText = 'Loading business profile...');
      if (!mounted) return;
      await context.read<BusinessProvider>().loadBusinesses();

      if (!mounted) return;
      final bizProv = context.read<BusinessProvider>();
      final currentBiz = bizProv.currentBusiness;

      if (currentBiz != null) {
        setState(() => _statusText = 'Checking operator session...');
        if (!mounted) return;
        await context.read<AuthProvider>().init(currentBiz.id);
      }

      // Smooth, natural splash duration (1800ms) without awkward multi-second delay or repeated entrance
      final elapsed = stopwatch.elapsedMilliseconds;
      const minDurationMs = 1800;
      if (elapsed < minDurationMs) {
        await Future.delayed(Duration(milliseconds: minDurationMs - elapsed));
      }

      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;

      final authProv = context.read<AuthProvider>();

      if (currentBiz == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SectorSelectionScreen()),
        );
      } else if (authProv.isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusText = 'Error initializing: $e');
      }
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // Brand gradient shared by both layout modes.
  static const List<Color> _brandColors = [
    Color(0xFF4F46E5),
    Color(0xFF0D9488),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E1B4B), const Color(0xFF0B1220)]
                : _brandColors,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              // Wide screens (landscape tablets, laptops, desktops) get a
              // split layout; phones get a single centered stage.
              if (width >= AppTokens.breakpointTablet) {
                return _wideLayout(width, height);
              }
              return _narrowLayout(width, height);
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // PHONE LAYOUT — single centered stage
  // ---------------------------------------------------------------
  Widget _narrowLayout(double width, double height) {
    return Stack(
      children: [
        _ambientCircles(width, height),
        Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: (width * 0.08).clamp(20.0, 48.0),
              vertical: 24.0,
            ),
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _logoBlock(width, height),
                  SizedBox(height: (height * 0.03).clamp(14.0, 26.0)),
                  _wordmarkBlock(width),
                  SizedBox(height: (height * 0.04).clamp(16.0, 36.0)),
                  _progressBlock(width),
                  SizedBox(height: (height * 0.035).clamp(14.0, 30.0)),
                  _sectorStrip(width),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // WIDE LAYOUT — brand stage + sector showcase panel
  // ---------------------------------------------------------------
  Widget _wideLayout(double width, double height) {
    return Row(
      children: [
        // Left: brand + progress
        Expanded(
          flex: 44,
          child: Stack(
            children: [
              _ambientCircles(width * 0.44, height),
              Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: (width * 0.36).clamp(280.0, 420.0),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: (width * 0.02).clamp(16.0, 32.0),
                      ),
                      child: FadeTransition(
                        opacity: _fade,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _logoBlock(width, height),
                            SizedBox(height: (height * 0.03).clamp(14.0, 28.0)),
                            _wordmarkBlock(width),
                            SizedBox(height: (height * 0.04).clamp(16.0, 36.0)),
                            _progressBlock(width * 0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Subtle vertical divider
        Container(
          width: 1,
          height: height * 0.5,
          color: Colors.white.withAlpha(40),
        ),
        // Right: sector showcase
        Expanded(
          flex: 56,
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: (width * 0.44).clamp(360.0, 520.0),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: (width * 0.02).clamp(16.0, 32.0),
                  ),
                  child: FadeTransition(
                    opacity: _fade,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ONE PLATFORM. EVERY SECTOR.',
                          style: TextStyle(
                            color: Colors.white.withAlpha(160),
                            fontSize: (width * 0.012).clamp(11.0, 14.0),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                          ),
                        ),
                        SizedBox(height: (height * 0.025).clamp(12.0, 24.0)),
                        _sectorGrid(width, height),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // Shared building blocks
  // ---------------------------------------------------------------
  Widget _logoBlock(double width, double height) {
    final minDim = math.min(width, height);
    final logoSize = (minDim * 0.20).clamp(64.0, 118.0);
    final iconSize = logoSize * 0.46;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulse.value * 0.035),
          child: child,
        );
      },
      child: Container(
        width: logoSize,
        height: logoSize,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(logoSize * 0.27),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(55),
              blurRadius: logoSize * 0.32,
              offset: Offset(0, logoSize * 0.08),
            ),
          ],
        ),
        child: Icon(
          Icons.point_of_sale_rounded,
          size: iconSize,
          color: _brandColors.first,
        ),
      ),
    );
  }

  Widget _wordmarkBlock(double width) {
    final minDim = width < 700 ? width : width * 0.44;
    return AnimatedBuilder(
      animation: _slide,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slide.value),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'OminiPOS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: (minDim * 0.062).clamp(24.0, 40.0),
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Multi-Sector Enterprise POS & ERP',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: (minDim * 0.026).clamp(12.0, 17.0),
              color: Colors.white.withAlpha(205),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBlock(double width) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width * 0.62,
          child: ClipRRect(
            borderRadius: AppTokens.borderPill,
            child: LinearProgressIndicator(
              minHeight: 5,
              backgroundColor: Colors.white.withAlpha(42),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        SizedBox(height: width * 0.028),
        Text(
          _statusText,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: (width * 0.026).clamp(10.5, 13.5),
            color: Colors.white.withAlpha(165),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Small row of sector icons — hints at what is coming next.
  Widget _sectorStrip(double width) {
    final iconSize = (width * 0.052).clamp(20.0, 30.0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: BusinessType.values.map((type) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.018),
          child: Tooltip(
            message: type.shortName,
            child: Icon(type.icon, size: iconSize, color: Colors.white.withAlpha(150)),
          ),
        );
      }).toList(),
    );
  }

  // Glass tile grid shown on wide screens.
  Widget _sectorGrid(double width, double height) {
    final iconSize = (width * 0.016).clamp(20.0, 28.0);
    final labelSize = (width * 0.010).clamp(10.0, 12.5);
    final spacing = (height * 0.016).clamp(8.0, 12.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 4 columns on spacious containers, 3 on standard tablet/desktop, 2 on very narrow.
        final crossCount = constraints.maxWidth >= 460
            ? 4
            : (constraints.maxWidth >= 310 ? 3 : 2);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: 1.35,
          children: BusinessType.values.map((type) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(16),
                borderRadius: AppTokens.borderLG,
                border: Border.all(color: Colors.white.withAlpha(28)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(type.icon, size: iconSize, color: Colors.white),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      type.shortName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withAlpha(215),
                        fontSize: labelSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Soft decorative circles positioned with percentages.
  Widget _ambientCircles(double width, double height) {
    return Stack(
      children: [
        Positioned(
          top: -height * 0.09,
          right: -width * 0.14,
          child: Container(
            width: width * 0.45,
            height: width * 0.45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(16),
            ),
          ),
        ),
        Positioned(
          bottom: -height * 0.11,
          left: -width * 0.18,
          child: Container(
            width: width * 0.55,
            height: width * 0.55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(9),
            ),
          ),
        ),
      ],
    );
  }
}
