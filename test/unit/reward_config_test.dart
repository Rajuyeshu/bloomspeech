import 'package:flutter_test/flutter_test.dart';
import 'package:bloomspeech/config/constants/app_constants.dart';
import 'package:bloomspeech/models/session.dart';

/// The clinician's choice travels to the child's device as a plain string and
/// is matched back to an enum by name. A name that does not match falls
/// through to a default silently — which is how "Rangoli" was selected and the
/// bubble game appeared, and how a physical reward still showed a mini-game.
void main() {
  /// Mirrors the resolution the reward screen performs.
  MiniGameType resolveGame(String? name) =>
      MiniGameType.values.firstWhere((g) => g.name == name,
          orElse: () => MiniGameType.bubbleBurst);

  RewardType resolveReward(String? name) =>
      RewardType.values.firstWhere((r) => r.name == name,
          orElse: () => RewardType.inAppMiniGame);

  group('enum names are the wire format', () {
    test('every mini-game round-trips through its name', () {
      for (final game in MiniGameType.values) {
        expect(resolveGame(game.name), game,
            reason: '${game.name} did not resolve back to itself');
      }
    });

    test('every reward type round-trips through its name', () {
      for (final reward in RewardType.values) {
        expect(resolveReward(reward.name), reward);
      }
    });

    test('every play theme round-trips through its name', () {
      for (final theme in PlayTheme.values) {
        expect(
          PlayTheme.values.firstWhere((t) => t.name == theme.name),
          theme,
        );
      }
    });

    test('the rangoli game is not confused with the rangoli theme', () {
      // These are two different enums with similar names; the game is
      // `rangoliPainter` and the board theme is `rangoliBuilder`. Storing one
      // where the other is expected resolves to the default and shows bubbles.
      expect(resolveGame('rangoliPainter'), MiniGameType.rangoliPainter);
      expect(resolveGame('rangoliBuilder'), MiniGameType.bubbleBurst,
          reason: 'a theme name is not a valid game name');
      expect(MiniGameType.values.map((g) => g.name),
          isNot(contains('rangoliBuilder')));
    });

    test('display names are not used as the wire format', () {
      // A display name would silently resolve to the default.
      expect(resolveGame('Rangoli Painter'), MiniGameType.bubbleBurst);
      expect(resolveGame(MiniGameType.rangoliPainter.name),
          MiniGameType.rangoliPainter);
    });
  });

  group('the mini-game is offered only when it was chosen', () {
    /// Mirrors `_showMiniGame` on the reward screen.
    bool showsMiniGame({String? rewardType, String? miniGame}) =>
        resolveReward(rewardType) == RewardType.inAppMiniGame &&
        miniGame != null &&
        miniGame.isNotEmpty;

    test('a physical reward never shows a mini-game', () {
      expect(
        showsMiniGame(
            rewardType: RewardType.physicalReward.name,
            miniGame: MiniGameType.rangoliPainter.name),
        isFalse,
      );
    });

    test('an animation reward never shows a mini-game', () {
      expect(
        showsMiniGame(
            rewardType: RewardType.inAppAnimation.name,
            miniGame: MiniGameType.bubbleBurst.name),
        isFalse,
      );
    });

    test('a mini-game reward shows the chosen game', () {
      expect(
        showsMiniGame(
            rewardType: RewardType.inAppMiniGame.name,
            miniGame: MiniGameType.plantWatering.name),
        isTrue,
      );
    });

    test('a mini-game reward with no game selected shows nothing', () {
      expect(showsMiniGame(rewardType: RewardType.inAppMiniGame.name), isFalse);
      expect(
        showsMiniGame(rewardType: RewardType.inAppMiniGame.name, miniGame: ''),
        isFalse,
      );
    });

    test('an unreadable reward type defaults to the mini-game', () {
      // Deliberate: before the migration ran, the column did not exist.
      expect(
        showsMiniGame(
            rewardType: null, miniGame: MiniGameType.bubbleBurst.name),
        isTrue,
      );
    });
  });

  test('the clinician choice survives the trip to the child device', () {
    final chosen = SessionConfig(
      childId: 'c1',
      childName: 'Aarav',
      rewardType: RewardType.physicalReward.name,
      miniGame: MiniGameType.rangoliPainter.name,
      physicalReward: 'sticker',
    );

    final onChildDevice = ActiveSession.fromMap({
      'token_goal': 10,
      'therapy_level': 'word',
      'play_theme': 'diyaFestival',
      'mini_game': chosen.miniGame,
      'reward_type': chosen.rewardType,
      'physical_reward': chosen.physicalReward,
    });

    expect(resolveReward(onChildDevice.rewardType), RewardType.physicalReward);
    expect(resolveGame(onChildDevice.miniGame), MiniGameType.rangoliPainter);
    expect(onChildDevice.physicalReward, 'sticker');
  });

  group('the mini-game line-up', () {
    test('plant watering is no longer offered', () {
      expect(MiniGameType.selectable.map((g) => g.name),
          isNot(contains('plantWatering')));
      expect(MiniGameType.plantWatering.legacy, isTrue);
    });

    test('balloon popping is offered in its place', () {
      expect(MiniGameType.selectable, contains(MiniGameType.balloonPop));
      expect(MiniGameType.balloonPop.legacy, isFalse);
    });

    test('a session saved against plant watering still parses', () {
      // It maps to the game that replaced it rather than failing to open.
      final g = MiniGameType.values.firstWhere(
          (x) => x.name == 'plantWatering',
          orElse: () => MiniGameType.bubbleBurst);
      expect(g, MiniGameType.plantWatering);
    });

    test('every offered game has a distinct name and glyph', () {
      final names = MiniGameType.selectable.map((g) => g.name).toList();
      final glyphs = MiniGameType.selectable.map((g) => g.emoji).toList();
      expect(names.toSet().length, names.length);
      expect(glyphs.toSet().length, glyphs.length);
    });
  });

  test('enum names are unique across each enum', () {
    for (final names in [
      MiniGameType.values.map((e) => e.name),
      RewardType.values.map((e) => e.name),
      PlayTheme.values.map((e) => e.name),
      TherapyLevel.values.map((e) => e.name),
    ]) {
      expect(names.toSet().length, names.length);
    }
  });
}
