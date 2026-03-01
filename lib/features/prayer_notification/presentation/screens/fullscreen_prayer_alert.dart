import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_tokens.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../../shared/widgets/glass/gradient_mesh_background.dart';

class FullscreenPrayerAlert extends StatefulWidget {
  final String prayerName;
  final DateTime scheduledTime;
  final int reminderCount;
  final int maxReminders;
  final VoidCallback onPrayerCompleted;
  final VoidCallback onRemindLater;

  const FullscreenPrayerAlert({
    super.key,
    required this.prayerName,
    required this.scheduledTime,
    required this.reminderCount,
    required this.maxReminders,
    required this.onPrayerCompleted,
    required this.onRemindLater,
  });

  @override
  State<FullscreenPrayerAlert> createState() => _FullscreenPrayerAlertState();
}

class _FullscreenPrayerAlertState extends State<FullscreenPrayerAlert>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final timeFormat = DateFormat('HH:mm');
    final isUrgent = widget.reminderCount > 2;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GradientMeshBackground(useUrgentColors: isUrgent),

          // Cercles decoratifs en arriere-plan
          ..._buildDecorativeCircles(screenSize, isUrgent),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenSize.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spacingLG,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: AppTokens.spacingLG),

                            // Indicateurs d'urgence
                            if (isUrgent)
                              _buildUrgencyBadge(),

                            const SizedBox(height: AppTokens.spacingLG),

                            // Icone mosquee avec halo pulse
                            ScaleTransition(
                              scale: _pulseAnimation,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      (isUrgent ? AppColors.alert : AppColors.primary)
                                          .withValues(alpha: 0.3),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.5, 1.0],
                                  ),
                                ),
                                child: Center(
                                  child: GlassCard(
                                    borderRadius: 36,
                                    padding: const EdgeInsets.all(AppTokens.spacingMD),
                                    tintColor: (isUrgent ? AppColors.alert : AppColors.primary)
                                        .withValues(alpha: 0.2),
                                    borderColor: Colors.white.withValues(alpha: 0.35),
                                    child: Icon(
                                      Icons.mosque,
                                      size: 34,
                                      color: Colors.white.withValues(alpha: 0.95),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: AppTokens.spacingLG),

                            // Sous-titre
                            Text(
                              'Heure de la priere',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.65),
                                letterSpacing: 2,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 6),

                            // Nom de la priere
                            Text(
                              widget.prayerName,
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: AppTokens.spacingMD),

                            // Heure dans une pill glass
                            GlassCard(
                              borderRadius: 24,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              tintColor: Colors.white.withValues(alpha: 0.1),
                              borderColor: Colors.white.withValues(alpha: 0.25),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    timeFormat.format(widget.scheduledTime),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppTokens.spacingLG),

                            // Compteur de rappels
                            if (widget.reminderCount > 0)
                              _buildReminderCounter(),

                            const SizedBox(height: AppTokens.spacingMD),

                            // Message d'encouragement
                            GlassCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.spacingMD,
                                vertical: AppTokens.spacingSM,
                              ),
                              tintColor: Colors.white.withValues(alpha: 0.05),
                              borderColor: Colors.white.withValues(alpha: 0.15),
                              child: Row(
                                children: [
                                  Icon(
                                    isUrgent ? Icons.priority_high_rounded : Icons.auto_awesome,
                                    color: isUrgent
                                        ? AppColors.alertLight
                                        : AppColors.accentLight,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppTokens.spacingSM),
                                  Expanded(
                                    child: Text(
                                      isUrgent
                                          ? 'Cette priere est importante ! Ne la manquez pas.'
                                          : 'Prenez un moment pour vous connecter avec Allah.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.8),
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppTokens.spacingLG),

                            // Bouton principal
                            GlassButton(
                              label: 'Priere accomplie',
                              onPressed: widget.onPrayerCompleted,
                              variant: GlassButtonVariant.primary,
                              icon: Icons.check_circle_outline,
                              width: double.infinity,
                              height: 52,
                            ),

                            const SizedBox(height: AppTokens.spacingSM),

                            // Bouton rappel
                            if (widget.reminderCount < widget.maxReminders)
                              GlassButton(
                                label: 'Rappeler dans 5 min',
                                onPressed: widget.onRemindLater,
                                variant: GlassButtonVariant.secondary,
                                icon: Icons.alarm,
                                width: double.infinity,
                                height: 48,
                              ),

                            const SizedBox(height: AppTokens.spacingXL),

                            // Indication swipe
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white.withValues(alpha: 0.4),
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Glissez pour ignorer',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTokens.spacingLG),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyBadge() {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tintColor: AppColors.alert.withValues(alpha: 0.2),
      borderColor: AppColors.alertLight.withValues(alpha: 0.4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.alertLight, size: 20),
          const SizedBox(width: 8),
          Text(
            'Rappel urgent',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.alertLight.withValues(alpha: 0.95),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCounter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.maxReminders,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < widget.reminderCount
                ? AppColors.accentLight
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDecorativeCircles(Size screenSize, bool isUrgent) {
    final color = isUrgent ? AppColors.alert : AppColors.primary;
    return [
      Positioned(
        top: -40,
        right: -40,
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.08),
          ),
        ),
      ),
      Positioned(
        bottom: screenSize.height * 0.2,
        left: -60,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.06),
          ),
        ),
      ),
    ];
  }
}
