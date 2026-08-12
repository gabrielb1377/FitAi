import 'package:flutter_test/flutter_test.dart';
import 'package:fitai/features/settings/settings.dart';

void main() {
  group('SettingsRepository', () {
    test('carrega defaults tipados para uma conta nova', () async {
      final repository = SettingsRepository(
        store: InMemorySettingsLocalStore(),
        userIdResolver: () async => 'gabriel',
      );

      final snapshot = await repository.load();

      expect(snapshot.userId, 'gabriel');
      expect(snapshot.settings.schemaVersion, AppSettings.currentSchemaVersion);
      expect(snapshot.settings.account.units.weight, WeightUnit.kilogram);
      expect(snapshot.settings.account.rest.defaultRestSeconds, 60);
    });

    test(
      'separa preferencias do aparelho das preferencias por conta',
      () async {
        final store = InMemorySettingsLocalStore();
        final first = SettingsRepository(
          store: store,
          userIdResolver: () async => 'gabriel',
        );
        final second = SettingsRepository(
          store: store,
          userIdResolver: () async => 'outra-conta',
        );
        final initial = await first.load();

        await first.update(
          initial,
          (value) => value.copyWith(
            device: value.device.copyWith(
              appearance: value.device.appearance.copyWith(
                reduceMotion: true,
                metadata: value.device.appearance.metadata.touch(),
              ),
            ),
            account: value.account.copyWith(
              units: value.account.units.copyWith(
                weight: WeightUnit.pound,
                metadata: value.account.units.metadata.touch(),
              ),
            ),
          ),
        );

        final other = await second.load();

        expect(other.settings.device.appearance.reduceMotion, isTrue);
        expect(other.settings.account.units.weight, WeightUnit.kilogram);
      },
    );

    test('migra valores desconhecidos para defaults seguros', () {
      final rest = RestSettings.fromJson({
        'defaultRestSeconds': -20,
        'quickAddSeconds': 999,
        'metadata': {'origin': 'unexpected'},
      });
      final units = UnitSettings.fromJson({'weight': 'stones'});

      expect(rest.defaultRestSeconds, 15);
      expect(rest.quickAddSeconds, 15);
      expect(rest.metadata.origin, SettingOrigin.account);
      expect(units.weight, WeightUnit.kilogram);
    });

    test('persiste preferencias entre instancias do repositorio', () async {
      final store = InMemorySettingsLocalStore();
      final first = SettingsRepository(
        store: store,
        userIdResolver: () async => 'gabriel',
      );
      final initial = await first.load();

      await first.update(
        initial,
        (value) => value.copyWith(
          device: value.device.copyWith(
            appearance: value.device.appearance.copyWith(
              theme: AppThemePreference.light,
              reduceMotion: true,
              highContrast: true,
            ),
            locale: value.device.locale.copyWith(
              locale: AppLocalePreference.portugueseBrazil,
            ),
          ),
          account: value.account.copyWith(
            units: value.account.units.copyWith(
              weight: WeightUnit.pound,
              height: HeightUnit.feetInches,
              distance: DistanceUnit.mile,
              pace: PaceUnit.minutesPerMile,
              timeFormat: TimeFormat.twelveHour,
              energy: EnergyUnit.kilojoule,
            ),
            workout: value.account.workout.copyWith(showSuggestedLoad: false),
            rest: value.account.rest.copyWith(
              defaultRestSeconds: 90,
              quickAddSeconds: 30,
              autoStartRest: false,
              autoAdvanceExercise: true,
              lastSecondsAlert: true,
              soundEnabled: true,
              vibrationEnabled: true,
            ),
            notifications: value.account.notifications.copyWith(
              workoutReminders: true,
              progressUpdates: true,
              goalUpdates: true,
              systemUpdates: false,
            ),
            privacy: value.account.privacy.copyWith(
              profileVisible: true,
              shareActivities: true,
              shareRouteMaps: true,
              healthDataConsent: true,
              aiPersonalizationConsent: true,
              analyticsConsent: true,
            ),
            security: value.account.security.copyWith(biometricRequested: true),
            sync: value.account.sync.copyWith(autoSync: false),
          ),
        ),
      );

      final reloaded = await SettingsRepository(
        store: store,
        userIdResolver: () async => 'gabriel',
      ).load();
      final device = reloaded.settings.device;
      final account = reloaded.settings.account;

      expect(device.appearance.theme, AppThemePreference.light);
      expect(device.appearance.reduceMotion, isTrue);
      expect(device.appearance.highContrast, isTrue);
      expect(device.locale.locale, AppLocalePreference.portugueseBrazil);
      expect(account.units.weight, WeightUnit.pound);
      expect(account.units.height, HeightUnit.feetInches);
      expect(account.units.distance, DistanceUnit.mile);
      expect(account.units.pace, PaceUnit.minutesPerMile);
      expect(account.units.timeFormat, TimeFormat.twelveHour);
      expect(account.units.energy, EnergyUnit.kilojoule);
      expect(account.workout.showSuggestedLoad, isFalse);
      expect(account.rest.defaultRestSeconds, 90);
      expect(account.rest.quickAddSeconds, 30);
      expect(account.rest.autoStartRest, isFalse);
      expect(account.rest.autoAdvanceExercise, isTrue);
      expect(account.rest.lastSecondsAlert, isTrue);
      expect(account.rest.soundEnabled, isTrue);
      expect(account.rest.vibrationEnabled, isTrue);
      expect(account.notifications.workoutReminders, isTrue);
      expect(account.notifications.progressUpdates, isTrue);
      expect(account.notifications.goalUpdates, isTrue);
      expect(account.notifications.systemUpdates, isFalse);
      expect(account.privacy.profileVisible, isTrue);
      expect(account.privacy.shareActivities, isTrue);
      expect(account.privacy.shareRouteMaps, isTrue);
      expect(account.privacy.healthDataConsent, isTrue);
      expect(account.privacy.aiPersonalizationConsent, isTrue);
      expect(account.privacy.analyticsConsent, isTrue);
      expect(account.security.biometricRequested, isTrue);
      expect(account.sync.autoSync, isFalse);
    });
  });

  group('UnitConversion', () {
    test(
      'converte apenas a apresentacao e permite retornar ao valor canonico',
      () {
        final pounds = UnitConversion.weightFromKilograms(55, WeightUnit.pound);
        final kilometers = UnitConversion.distanceToKilometers(
          5,
          DistanceUnit.mile,
        );

        expect(
          UnitConversion.weightToKilograms(pounds, WeightUnit.pound),
          closeTo(55, 0.001),
        );
        expect(kilometers, closeTo(8.04672, 0.0001));
        expect(
          UnitConversion.paceFromMinutesPerKm(5, PaceUnit.minutesPerMile),
          closeTo(8.04672, 0.0001),
        );
      },
    );

    test('apresenta altura imperial sem alterar centimetros canonicos', () {
      final height = UnitConversion.heightFromCentimeters(
        180,
        HeightUnit.feetInches,
      );

      expect(height.feet, 5);
      expect(height.inches, 11);
    });
  });

  test(
    'atualizar descanso aplica apenas o default para proximas sessoes',
    () async {
      final controller = SettingsController(
        repository: SettingsRepository(
          store: InMemorySettingsLocalStore(),
          userIdResolver: () async => 'gabriel',
        ),
      );
      await controller.load();

      await controller.update(
        (value) => value.copyWith(
          account: value.account.copyWith(
            rest: value.account.rest.copyWith(defaultRestSeconds: 90),
          ),
        ),
      );

      expect(WorkoutSettingsRuntime.rest.defaultRestSeconds, 90);
    },
  );
}
