import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartlife_app/presentation/screens/smarthome/widgets/smarthome_background.dart';
import 'package:smartlife_app/presentation/screens/smarthome/widgets/home_header.dart';
import 'package:smartlife_app/presentation/screens/smarthome/widgets/scene_grid.dart';
import 'package:smartlife_app/presentation/screens/smarthome/widgets/energy_analytics_card.dart';
import 'package:smartlife_app/presentation/screens/smarthome/widgets/device_controls.dart';

class SmartHomeScreen extends ConsumerStatefulWidget {
  const SmartHomeScreen({super.key});

  @override
  ConsumerState<SmartHomeScreen> createState() => _SmartHomeScreenState();
}

class _SmartHomeScreenState extends ConsumerState<SmartHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final homeState = ref.watch(smartHomeProvider);
    final homeNotifier = ref.read(smartHomeProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {}, // Potential for further menu expansion
            icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          SmartHomeBackground(isDark: isDark),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const HomeHeader()
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.1),
                  const SizedBox(height: 32),

                  const SceneGrid()
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 600.ms),
                  const SizedBox(height: 32),

                  const EnergyAnalyticsCard()
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 600.ms)
                      .slideY(begin: 0.1),
                  const SizedBox(height: 32),

                  // Device Grid Section Header
                  const _SectionHeader(title: 'DEVICE CONTROLS'),
                  const SizedBox(height: 16),

                  // Bento Grid for controls
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LightControlCard(
                          isOn: homeState.isMainLightOn,
                          brightness: homeState.lightBrightness,
                          onToggle: homeNotifier.toggleMainLight,
                          onBrightnessChanged: homeNotifier.setLightBrightness,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SecurityControlCard(
                          isLocked: homeState.isDoorLocked,
                          onTap: () {
                            HapticFeedback.vibrate();
                            homeNotifier.toggleDoorLock();
                          },
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideY(begin: 0.1),

                  const SizedBox(height: 16),

                  ClimateControlCard(
                    isOn: homeState.isAcOn,
                    temp: homeState.acTemp,
                    onToggle: homeNotifier.toggleAc,
                    onTempUp: () => homeNotifier.updateAcTemp(homeState.acTemp + 1),
                    onTempDown: () => homeNotifier.updateAcTemp(homeState.acTemp - 1),
                  ).animate().fadeIn(delay: 700.ms, duration: 600.ms).slideY(begin: 0.1),

                  const SizedBox(height: 16),

                  CctvControlCard(
                    isActive: homeState.isCctvActive,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      homeNotifier.toggleCctv();
                    },
                  ).animate().fadeIn(delay: 800.ms, duration: 600.ms).slideY(begin: 0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: Colors.white.withValues(alpha: 0.4),
      ),
    );
  }
}
