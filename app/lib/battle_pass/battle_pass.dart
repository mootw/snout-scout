import 'dart:math';
import 'package:app/battle_pass/edit_scout_profile.dart';
import 'package:app/battle_pass/unlocks.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/screens/scout_authenticator_dialog.dart';
import 'package:app/widgets/scout_name_display.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/action.dart';
import 'package:snout_db/actions/extras/battle_pass_upgrade.dart';
import 'package:snout_db/app_extras/bencoin.dart';
import 'package:snout_db/message.dart';

class BattlePassPage extends StatefulWidget {
  const BattlePassPage({super.key});

  @override
  State<BattlePassPage> createState() => _BattlePassPageState();
}

class _BattlePassPageState extends State<BattlePassPage> {
  @override
  Widget build(BuildContext context) {
    final identity = context.watch<IdentityProvider>().identity;
    final db = context.watch<DataProvider>().database;
    final scouts = db.allowedKeys;

    int currentLevel = db.scoutBattlePassLevels[identity] ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text('Snout Scout Battle Pass')),
      body: identity == null
          ? Wrap(
              alignment: WrapAlignment.start,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final scout in scouts.entries)
                  ChoiceChip(
                    label: ScoutName(db: db, scoutPubkey: scout.key),
                    selected: identity == scout.key,
                    onSelected: (value) {
                      if (value) {
                        context.read<IdentityProvider>().setIdentity(scout.key);
                      }
                    },
                  ),
              ],
            )
          : ListView(
              children: [
                Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final scout in scouts.entries)
                      ChoiceChip(
                        label: ScoutName(db: db, scoutPubkey: scout.key),
                        selected: identity == scout.key,
                        onSelected: (value) {
                          if (value) {
                            context.read<IdentityProvider>().setIdentity(
                              scout.key,
                            );
                          }
                        },
                      ),
                  ],
                ),

                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('battle_pass.png', width: 140, height: 140),
                    SizedBox(width: 32),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ScoutName(db: db, scoutPubkey: identity),
                        Text(
                          '$currentLevel',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        Text('Bencoin: ${spendableBencoin(db, identity)}'),
                      ],
                    ),
                  ],
                ),

                ListTile(
                  title: Text('Edit Profile'),
                  subtitle: Text('Change your scout profile settings'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditScoutProfile(scoutPubkey: identity),
                    ),
                  ),
                ),
                SizedBox(height: 32),

                for (final level in battlePassRewards.entries) ...[
                  Divider(height: 32),
                  Center(
                    child: Text(
                      'Level ${level.key}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 32,
                    runSpacing: 16,
                    children: [
                      for (final unlock in level.value)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(unlock.name),
                              unlock.buildPreview(context),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),

                  if (level.key <= currentLevel)
                    Center(
                      child: Text(
                        '✅ Unlocked',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  if (level.key > currentLevel)
                    Center(
                      child: FilledButton.tonal(
                        onPressed: currentLevel + 1 < level.key || spendableBencoin(db, identity) < battlePassCost(level.key)
                            ? null
                            : () async {
                                final AuthorizedScoutData? auth =
                                    await showDialog(
                                      context: context,
                                      builder: (context) =>
                                          ScoutAuthorizationDialog(
                                            allowBackButton: true,
                                            scoutToAuthorize: identity,
                                          ),
                                    );

                                if (auth == null) {
                                  return;
                                }

                                List<int> lastHash = await db.actions.last.hash;

                                SignedChainMessage signed =
                                    await ChainActionData(
                                      time: DateTime.now(),
                                      previousHash: lastHash,
                                      action: ActionBattlePassLevelUp(
                                        level.key,
                                      ),
                                    ).encodeAndSign(auth.secretKey);

                                if (!context.mounted) {
                                  return;
                                }

                                await context
                                    .read<DataProvider>()
                                    .newTransaction(signed);

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        LevelUpScreen(level: level.key),
                                  ),
                                );
                              },
                        child: Text(
                          'Unlock for ${battlePassCost(level.key)} Bencoin${currentLevel + 1 < level.key ? ' (Needs Level ${level.key - 1})' : ''}',
                        ),
                      ),
                    ),
                ],
                Divider(height: 32),
                Center(
                  child: Text(
                    'Complete!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                SizedBox(height: 32),
              ],
            ),
    );
  }
}

/// Warning this was vibe coded but it looks cool
class LevelUpScreen extends StatefulWidget {
  const LevelUpScreen({super.key, required this.level});

  final int level;

  @override
  State<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends State<LevelUpScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: ConfettiAnimation()),
          Center(
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _controller,
                curve: Curves.elasticOut,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LEVEL ${widget.level}!',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black26,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Okay!'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfettiAnimation extends StatefulWidget {
  const ConfettiAnimation({super.key});

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    )..repeat();
    for (int i = 0; i < 100; i++) {
      _particles.add(_Particle(_random));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(painter: _ConfettiPainter(_particles));
      },
    );
  }
}

class _Particle {
  late double x;
  late double y;
  late double speed;
  late double theta;
  late double radius;
  late Color color;

  _Particle(Random random) {
    reset(random, true);
  }

  void reset(Random random, [bool startRandomY = false]) {
    x = random.nextDouble();
    y = startRandomY ? random.nextDouble() : -0.1;
    speed = random.nextDouble() * 0.01 + 0.005;
    theta = random.nextDouble() * 2 * pi;
    radius = random.nextDouble() * 5 + 2;
    color = Colors.primaries[random.nextInt(Colors.primaries.length)];
  }

  void update() {
    y += speed;
    x += sin(theta) * 0.001;
    theta += 0.1;
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var particle in particles) {
      particle.update();
      if (particle.y > 1.0) {
        particle.reset(Random());
      }
      paint.color = particle.color;
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
