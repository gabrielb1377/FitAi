/// Tipos canônicos de preferências do FitIA.
///
/// Valores de unidades continuam canônicos no armazenamento de cada domínio.
/// Estas preferências definem somente como o valor será apresentado.
enum SettingOrigin { device, account, defaultValue }

enum SettingsSyncStatus { local, pending, synced, unavailable }

enum AppThemePreference { system, dark, light }

enum AppLocalePreference { system, portugueseBrazil }

enum WeightUnit { kilogram, pound }

enum HeightUnit { centimeter, feetInches }

enum DistanceUnit { kilometer, mile }

enum PaceUnit { minutesPerKilometer, minutesPerMile }

enum TimeFormat { system, twentyFourHour, twelveHour }

enum EnergyUnit { kilocalorie, kilojoule }

enum IntegrationStatus { notConfigured, future, available }

class SettingsMetadata {
  const SettingsMetadata({
    required this.origin,
    required this.syncStatus,
    required this.updatedAt,
  });

  factory SettingsMetadata.defaults(SettingOrigin origin) => SettingsMetadata(
    origin: origin,
    syncStatus: SettingsSyncStatus.local,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  final SettingOrigin origin;
  final SettingsSyncStatus syncStatus;
  final DateTime updatedAt;

  SettingsMetadata touch() => SettingsMetadata(
    origin: origin,
    syncStatus: syncStatus,
    updatedAt: DateTime.now().toUtc(),
  );

  Map<String, Object> toJson() => {
    'origin': origin.name,
    'syncStatus': syncStatus.name,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  factory SettingsMetadata.fromJson(
    Object? value, {
    required SettingOrigin fallbackOrigin,
  }) {
    final json = _map(value);
    return SettingsMetadata(
      origin: _enumByName(SettingOrigin.values, json['origin'], fallbackOrigin),
      syncStatus: _enumByName(
        SettingsSyncStatus.values,
        json['syncStatus'],
        SettingsSyncStatus.local,
      ),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class AppearanceSettings {
  const AppearanceSettings({
    required this.theme,
    required this.reduceMotion,
    required this.highContrast,
    required this.metadata,
  });

  factory AppearanceSettings.defaults() => AppearanceSettings(
    theme: AppThemePreference.dark,
    reduceMotion: false,
    highContrast: false,
    metadata: SettingsMetadata.defaults(SettingOrigin.device),
  );

  final AppThemePreference theme;
  final bool reduceMotion;
  final bool highContrast;
  final SettingsMetadata metadata;

  AppearanceSettings copyWith({
    AppThemePreference? theme,
    bool? reduceMotion,
    bool? highContrast,
    SettingsMetadata? metadata,
  }) => AppearanceSettings(
    theme: theme ?? this.theme,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    highContrast: highContrast ?? this.highContrast,
    metadata: metadata ?? this.metadata,
  );

  Map<String, Object> toJson() => {
    'theme': theme.name,
    'reduceMotion': reduceMotion,
    'highContrast': highContrast,
    'metadata': metadata.toJson(),
  };

  factory AppearanceSettings.fromJson(Object? value) {
    final json = _map(value);
    final defaults = AppearanceSettings.defaults();
    return defaults.copyWith(
      theme: _enumByName(
        AppThemePreference.values,
        json['theme'],
        defaults.theme,
      ),
      reduceMotion: _bool(json['reduceMotion'], defaults.reduceMotion),
      highContrast: _bool(json['highContrast'], defaults.highContrast),
      metadata: SettingsMetadata.fromJson(
        json['metadata'],
        fallbackOrigin: SettingOrigin.device,
      ),
    );
  }
}

class LocaleSettings {
  const LocaleSettings({required this.locale, required this.metadata});

  factory LocaleSettings.defaults() => LocaleSettings(
    locale: AppLocalePreference.system,
    metadata: SettingsMetadata.defaults(SettingOrigin.device),
  );

  final AppLocalePreference locale;
  final SettingsMetadata metadata;

  LocaleSettings copyWith({
    AppLocalePreference? locale,
    SettingsMetadata? metadata,
  }) => LocaleSettings(
    locale: locale ?? this.locale,
    metadata: metadata ?? this.metadata,
  );

  Map<String, Object> toJson() => {
    'locale': locale.name,
    'metadata': metadata.toJson(),
  };

  factory LocaleSettings.fromJson(Object? value) {
    final json = _map(value);
    final defaults = LocaleSettings.defaults();
    return defaults.copyWith(
      locale: _enumByName(
        AppLocalePreference.values,
        json['locale'],
        defaults.locale,
      ),
      metadata: SettingsMetadata.fromJson(
        json['metadata'],
        fallbackOrigin: SettingOrigin.device,
      ),
    );
  }
}

class UnitSettings {
  const UnitSettings({
    required this.weight,
    required this.height,
    required this.distance,
    required this.pace,
    required this.timeFormat,
    required this.energy,
    required this.metadata,
  });

  factory UnitSettings.defaults() => UnitSettings(
    weight: WeightUnit.kilogram,
    height: HeightUnit.centimeter,
    distance: DistanceUnit.kilometer,
    pace: PaceUnit.minutesPerKilometer,
    timeFormat: TimeFormat.system,
    energy: EnergyUnit.kilocalorie,
    metadata: SettingsMetadata.defaults(SettingOrigin.account),
  );

  final WeightUnit weight;
  final HeightUnit height;
  final DistanceUnit distance;
  final PaceUnit pace;
  final TimeFormat timeFormat;
  final EnergyUnit energy;
  final SettingsMetadata metadata;

  UnitSettings copyWith({
    WeightUnit? weight,
    HeightUnit? height,
    DistanceUnit? distance,
    PaceUnit? pace,
    TimeFormat? timeFormat,
    EnergyUnit? energy,
    SettingsMetadata? metadata,
  }) => UnitSettings(
    weight: weight ?? this.weight,
    height: height ?? this.height,
    distance: distance ?? this.distance,
    pace: pace ?? this.pace,
    timeFormat: timeFormat ?? this.timeFormat,
    energy: energy ?? this.energy,
    metadata: metadata ?? this.metadata,
  );

  Map<String, Object> toJson() => {
    'weight': weight.name,
    'height': height.name,
    'distance': distance.name,
    'pace': pace.name,
    'timeFormat': timeFormat.name,
    'energy': energy.name,
    'metadata': metadata.toJson(),
  };

  factory UnitSettings.fromJson(Object? value) {
    final json = _map(value);
    final defaults = UnitSettings.defaults();
    return defaults.copyWith(
      weight: _enumByName(WeightUnit.values, json['weight'], defaults.weight),
      height: _enumByName(HeightUnit.values, json['height'], defaults.height),
      distance: _enumByName(
        DistanceUnit.values,
        json['distance'],
        defaults.distance,
      ),
      pace: _enumByName(PaceUnit.values, json['pace'], defaults.pace),
      timeFormat: _enumByName(
        TimeFormat.values,
        json['timeFormat'],
        defaults.timeFormat,
      ),
      energy: _enumByName(EnergyUnit.values, json['energy'], defaults.energy),
      metadata: SettingsMetadata.fromJson(
        json['metadata'],
        fallbackOrigin: SettingOrigin.account,
      ),
    );
  }
}

class WorkoutSettings {
  const WorkoutSettings({
    required this.showSuggestedLoad,
    required this.metadata,
  });

  factory WorkoutSettings.defaults() => WorkoutSettings(
    showSuggestedLoad: true,
    metadata: SettingsMetadata.defaults(SettingOrigin.account),
  );

  final bool showSuggestedLoad;
  final SettingsMetadata metadata;

  WorkoutSettings copyWith({
    bool? showSuggestedLoad,
    SettingsMetadata? metadata,
  }) => WorkoutSettings(
    showSuggestedLoad: showSuggestedLoad ?? this.showSuggestedLoad,
    metadata: metadata ?? this.metadata,
  );

  Map<String, Object> toJson() => {
    'showSuggestedLoad': showSuggestedLoad,
    'metadata': metadata.toJson(),
  };

  factory WorkoutSettings.fromJson(Object? value) {
    final json = _map(value);
    final defaults = WorkoutSettings.defaults();
    return defaults.copyWith(
      showSuggestedLoad: _bool(
        json['showSuggestedLoad'],
        defaults.showSuggestedLoad,
      ),
      metadata: SettingsMetadata.fromJson(
        json['metadata'],
        fallbackOrigin: SettingOrigin.account,
      ),
    );
  }
}

class RestSettings {
  const RestSettings({
    required this.defaultRestSeconds,
    required this.quickAddSeconds,
    required this.autoStartRest,
    required this.autoAdvanceExercise,
    required this.lastSecondsAlert,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.metadata,
  }) : assert(defaultRestSeconds >= 15 && defaultRestSeconds <= 600),
       assert(quickAddSeconds == 15 || quickAddSeconds == 30);

  factory RestSettings.defaults() => RestSettings(
    defaultRestSeconds: 60,
    quickAddSeconds: 15,
    autoStartRest: true,
    autoAdvanceExercise: false,
    lastSecondsAlert: false,
    soundEnabled: false,
    vibrationEnabled: false,
    metadata: SettingsMetadata.defaults(SettingOrigin.account),
  );

  final int defaultRestSeconds;
  final int quickAddSeconds;
  final bool autoStartRest;
  final bool autoAdvanceExercise;
  final bool lastSecondsAlert;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final SettingsMetadata metadata;

  RestSettings copyWith({
    int? defaultRestSeconds,
    int? quickAddSeconds,
    bool? autoStartRest,
    bool? autoAdvanceExercise,
    bool? lastSecondsAlert,
    bool? soundEnabled,
    bool? vibrationEnabled,
    SettingsMetadata? metadata,
  }) => RestSettings(
    defaultRestSeconds: _validRest(
      defaultRestSeconds ?? this.defaultRestSeconds,
    ),
    quickAddSeconds: _validQuickAdd(quickAddSeconds ?? this.quickAddSeconds),
    autoStartRest: autoStartRest ?? this.autoStartRest,
    autoAdvanceExercise: autoAdvanceExercise ?? this.autoAdvanceExercise,
    lastSecondsAlert: lastSecondsAlert ?? this.lastSecondsAlert,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    metadata: metadata ?? this.metadata,
  );

  Map<String, Object> toJson() => {
    'defaultRestSeconds': defaultRestSeconds,
    'quickAddSeconds': quickAddSeconds,
    'autoStartRest': autoStartRest,
    'autoAdvanceExercise': autoAdvanceExercise,
    'lastSecondsAlert': lastSecondsAlert,
    'soundEnabled': soundEnabled,
    'vibrationEnabled': vibrationEnabled,
    'metadata': metadata.toJson(),
  };

  factory RestSettings.fromJson(Object? value) {
    final json = _map(value);
    final defaults = RestSettings.defaults();
    return defaults.copyWith(
      defaultRestSeconds: _validRest(
        _int(json['defaultRestSeconds'], defaults.defaultRestSeconds),
      ),
      quickAddSeconds: _validQuickAdd(
        _int(json['quickAddSeconds'], defaults.quickAddSeconds),
      ),
      autoStartRest: _bool(json['autoStartRest'], defaults.autoStartRest),
      autoAdvanceExercise: _bool(
        json['autoAdvanceExercise'],
        defaults.autoAdvanceExercise,
      ),
      lastSecondsAlert: _bool(
        json['lastSecondsAlert'],
        defaults.lastSecondsAlert,
      ),
      soundEnabled: _bool(json['soundEnabled'], defaults.soundEnabled),
      vibrationEnabled: _bool(
        json['vibrationEnabled'],
        defaults.vibrationEnabled,
      ),
      metadata: SettingsMetadata.fromJson(
        json['metadata'],
        fallbackOrigin: SettingOrigin.account,
      ),
    );
  }
}

class NotificationSettings {
  const NotificationSettings({
    required this.workoutReminders,
    required this.progressUpdates,
    required this.goalUpdates,
    required this.systemUpdates,
    required this.metadata,
  });

  factory NotificationSettings.defaults() => NotificationSettings(
    workoutReminders: false,
    progressUpdates: false,
    goalUpdates: false,
    systemUpdates: true,
    metadata: SettingsMetadata.defaults(SettingOrigin.account),
  );

  final bool workoutReminders;
  final bool progressUpdates;
  final bool goalUpdates;
  final bool systemUpdates;
  final SettingsMetadata metadata;

  NotificationSettings copyWith({
    bool? workoutReminders,
    bool? progressUpdates,
    bool? goalUpdates,
    bool? systemUpdates,
    SettingsMetadata? metadata,
  }) => NotificationSettings(
    workoutReminders: workoutReminders ?? this.workoutReminders,
    progressUpdates: progressUpdates ?? this.progressUpdates,
    goalUpdates: goalUpdates ?? this.goalUpdates,
    systemUpdates: systemUpdates ?? this.systemUpdates,
    metadata: metadata ?? this.metadata,
  );

  Map<String, Object> toJson() => {
    'workoutReminders': workoutReminders,
    'progressUpdates': progressUpdates,
    'goalUpdates': goalUpdates,
    'systemUpdates': systemUpdates,
    'metadata': metadata.toJson(),
  };

  factory NotificationSettings.fromJson(Object? value) {
    final json = _map(value);
    final defaults = NotificationSettings.defaults();
    return defaults.copyWith(
      workoutReminders: _bool(
        json['workoutReminders'],
        defaults.workoutReminders,
      ),
      progressUpdates: _bool(json['progressUpdates'], defaults.progressUpdates),
      goalUpdates: _bool(json['goalUpdates'], defaults.goalUpdates),
      systemUpdates: _bool(json['systemUpdates'], defaults.systemUpdates),
      metadata: SettingsMetadata.fromJson(
        json['metadata'],
        fallbackOrigin: SettingOrigin.account,
      ),
    );
  }
}

class PrivacySettings {
  const PrivacySettings({
    required this.profileVisible,
    required this.shareActivities,
    required this.shareRouteMaps,
    required this.healthDataConsent,
    required this.aiPersonalizationConsent,
    required this.analyticsConsent,
    required this.metadata,
  });

  factory PrivacySettings.defaults() => PrivacySettings(
    profileVisible: false,
    shareActivities: false,
    shareRouteMaps: false,
    healthDataConsent: false,
    aiPersonalizationConsent: false,
    analyticsConsent: false,
    metadata: SettingsMetadata.defaults(SettingOrigin.account),
  );

  final bool profileVisible;
  final bool shareActivities;
  final bool shareRouteMaps;
  final bool healthDataConsent;
  final bool aiPersonalizationConsent;
  final bool analyticsConsent;
  final SettingsMetadata metadata;

  PrivacySettings copyWith({
    bool? profileVisible,
    bool? shareActivities,
    bool? shareRouteMaps,
    bool? healthDataConsent,
    bool? aiPersonalizationConsent,
    bool? analyticsConsent,
    SettingsMetadata? metadata,
  }) => PrivacySettings(
    profileVisible: profileVisible ?? this.profileVisible,
    shareActivities: shareActivities ?? this.shareActivities,
    shareRouteMaps: shareRouteMaps ?? this.shareRouteMaps,
    healthDataConsent: healthDataConsent ?? this.healthDataConsent,
    aiPersonalizationConsent:
        aiPersonalizationConsent ?? this.aiPersonalizationConsent,
    analyticsConsent: analyticsConsent ?? this.analyticsConsent,
    metadata: metadata ?? this.metadata,
  );

  Map<String, Object> toJson() => {
    'profileVisible': profileVisible,
    'shareActivities': shareActivities,
    'shareRouteMaps': shareRouteMaps,
    'healthDataConsent': healthDataConsent,
    'aiPersonalizationConsent': aiPersonalizationConsent,
    'analyticsConsent': analyticsConsent,
    'metadata': metadata.toJson(),
  };

  factory PrivacySettings.fromJson(Object? value) {
    final json = _map(value);
    final defaults = PrivacySettings.defaults();
    return defaults.copyWith(
      profileVisible: _bool(json['profileVisible'], defaults.profileVisible),
      shareActivities: _bool(json['shareActivities'], defaults.shareActivities),
      shareRouteMaps: _bool(json['shareRouteMaps'], defaults.shareRouteMaps),
      healthDataConsent: _bool(
        json['healthDataConsent'],
        defaults.healthDataConsent,
      ),
      aiPersonalizationConsent: _bool(
        json['aiPersonalizationConsent'],
        defaults.aiPersonalizationConsent,
      ),
      analyticsConsent: _bool(
        json['analyticsConsent'],
        defaults.analyticsConsent,
      ),
      metadata: SettingsMetadata.fromJson(
        json['metadata'],
        fallbackOrigin: SettingOrigin.account,
      ),
    );
  }
}

class SecuritySettings {
  const SecuritySettings({
    required this.biometricRequested,
    required this.metadata,
  });

  factory SecuritySettings.defaults() => SecuritySettings(
    biometricRequested: false,
    metadata: SettingsMetadata.defaults(SettingOrigin.device),
  );

  final bool biometricRequested;
  final SettingsMetadata metadata;

  SecuritySettings copyWith({
    bool? biometricRequested,
    SettingsMetadata? metadata,
  }) => SecuritySettings(
    biometricRequested: biometricRequested ?? this.biometricRequested,
    metadata: metadata ?? this.metadata,
  );

  Map<String, Object> toJson() => {
    'biometricRequested': biometricRequested,
    'metadata': metadata.toJson(),
  };

  factory SecuritySettings.fromJson(Object? value) {
    final json = _map(value);
    final defaults = SecuritySettings.defaults();
    return defaults.copyWith(
      biometricRequested: _bool(
        json['biometricRequested'],
        defaults.biometricRequested,
      ),
      metadata: SettingsMetadata.fromJson(
        json['metadata'],
        fallbackOrigin: SettingOrigin.device,
      ),
    );
  }
}

class SyncSettings {
  const SyncSettings({required this.autoSync, required this.metadata});

  factory SyncSettings.defaults() => SyncSettings(
    autoSync: true,
    metadata: SettingsMetadata.defaults(SettingOrigin.account),
  );

  final bool autoSync;
  final SettingsMetadata metadata;

  SyncSettings copyWith({bool? autoSync, SettingsMetadata? metadata}) =>
      SyncSettings(
        autoSync: autoSync ?? this.autoSync,
        metadata: metadata ?? this.metadata,
      );

  Map<String, Object> toJson() => {
    'autoSync': autoSync,
    'metadata': metadata.toJson(),
  };

  factory SyncSettings.fromJson(Object? value) {
    final json = _map(value);
    final defaults = SyncSettings.defaults();
    return defaults.copyWith(
      autoSync: _bool(json['autoSync'], defaults.autoSync),
      metadata: SettingsMetadata.fromJson(
        json['metadata'],
        fallbackOrigin: SettingOrigin.account,
      ),
    );
  }
}

class IntegrationSettings {
  const IntegrationSettings({
    required this.appleHealth,
    required this.healthConnect,
    required this.garmin,
    required this.strava,
    required this.metadata,
  });

  factory IntegrationSettings.defaults() => IntegrationSettings(
    appleHealth: IntegrationStatus.future,
    healthConnect: IntegrationStatus.notConfigured,
    garmin: IntegrationStatus.future,
    strava: IntegrationStatus.future,
    metadata: SettingsMetadata.defaults(SettingOrigin.account),
  );

  final IntegrationStatus appleHealth;
  final IntegrationStatus healthConnect;
  final IntegrationStatus garmin;
  final IntegrationStatus strava;
  final SettingsMetadata metadata;

  Map<String, Object> toJson() => {
    'appleHealth': appleHealth.name,
    'healthConnect': healthConnect.name,
    'garmin': garmin.name,
    'strava': strava.name,
    'metadata': metadata.toJson(),
  };

  factory IntegrationSettings.fromJson(Object? value) {
    final json = _map(value);
    final defaults = IntegrationSettings.defaults();
    return IntegrationSettings(
      appleHealth: _enumByName(
        IntegrationStatus.values,
        json['appleHealth'],
        defaults.appleHealth,
      ),
      healthConnect: _enumByName(
        IntegrationStatus.values,
        json['healthConnect'],
        defaults.healthConnect,
      ),
      garmin: _enumByName(
        IntegrationStatus.values,
        json['garmin'],
        defaults.garmin,
      ),
      strava: _enumByName(
        IntegrationStatus.values,
        json['strava'],
        defaults.strava,
      ),
      metadata: SettingsMetadata.fromJson(
        json['metadata'],
        fallbackOrigin: SettingOrigin.account,
      ),
    );
  }
}

class AccountSettings {
  const AccountSettings({
    required this.units,
    required this.workout,
    required this.rest,
    required this.notifications,
    required this.privacy,
    required this.security,
    required this.sync,
    required this.integrations,
  });

  factory AccountSettings.defaults() => AccountSettings(
    units: UnitSettings.defaults(),
    workout: WorkoutSettings.defaults(),
    rest: RestSettings.defaults(),
    notifications: NotificationSettings.defaults(),
    privacy: PrivacySettings.defaults(),
    security: SecuritySettings.defaults(),
    sync: SyncSettings.defaults(),
    integrations: IntegrationSettings.defaults(),
  );

  final UnitSettings units;
  final WorkoutSettings workout;
  final RestSettings rest;
  final NotificationSettings notifications;
  final PrivacySettings privacy;
  final SecuritySettings security;
  final SyncSettings sync;
  final IntegrationSettings integrations;

  AccountSettings copyWith({
    UnitSettings? units,
    WorkoutSettings? workout,
    RestSettings? rest,
    NotificationSettings? notifications,
    PrivacySettings? privacy,
    SecuritySettings? security,
    SyncSettings? sync,
    IntegrationSettings? integrations,
  }) => AccountSettings(
    units: units ?? this.units,
    workout: workout ?? this.workout,
    rest: rest ?? this.rest,
    notifications: notifications ?? this.notifications,
    privacy: privacy ?? this.privacy,
    security: security ?? this.security,
    sync: sync ?? this.sync,
    integrations: integrations ?? this.integrations,
  );

  Map<String, Object> toJson() => {
    'units': units.toJson(),
    'workout': workout.toJson(),
    'rest': rest.toJson(),
    'notifications': notifications.toJson(),
    'privacy': privacy.toJson(),
    'security': security.toJson(),
    'sync': sync.toJson(),
    'integrations': integrations.toJson(),
  };

  factory AccountSettings.fromJson(Object? value) {
    final json = _map(value);
    return AccountSettings(
      units: UnitSettings.fromJson(json['units']),
      workout: WorkoutSettings.fromJson(json['workout']),
      rest: RestSettings.fromJson(json['rest']),
      notifications: NotificationSettings.fromJson(json['notifications']),
      privacy: PrivacySettings.fromJson(json['privacy']),
      security: SecuritySettings.fromJson(json['security']),
      sync: SyncSettings.fromJson(json['sync']),
      integrations: IntegrationSettings.fromJson(json['integrations']),
    );
  }
}

class DeviceSettings {
  const DeviceSettings({required this.appearance, required this.locale});

  factory DeviceSettings.defaults() => DeviceSettings(
    appearance: AppearanceSettings.defaults(),
    locale: LocaleSettings.defaults(),
  );

  final AppearanceSettings appearance;
  final LocaleSettings locale;

  DeviceSettings copyWith({
    AppearanceSettings? appearance,
    LocaleSettings? locale,
  }) => DeviceSettings(
    appearance: appearance ?? this.appearance,
    locale: locale ?? this.locale,
  );

  Map<String, Object> toJson() => {
    'appearance': appearance.toJson(),
    'locale': locale.toJson(),
  };

  factory DeviceSettings.fromJson(Object? value) {
    final json = _map(value);
    return DeviceSettings(
      appearance: AppearanceSettings.fromJson(json['appearance']),
      locale: LocaleSettings.fromJson(json['locale']),
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.schemaVersion,
    required this.device,
    required this.account,
    required this.updatedAt,
  });

  static const currentSchemaVersion = 1;

  factory AppSettings.defaults() => AppSettings(
    schemaVersion: currentSchemaVersion,
    device: DeviceSettings.defaults(),
    account: AccountSettings.defaults(),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  final int schemaVersion;
  final DeviceSettings device;
  final AccountSettings account;
  final DateTime updatedAt;

  AppSettings copyWith({
    DeviceSettings? device,
    AccountSettings? account,
    DateTime? updatedAt,
  }) => AppSettings(
    schemaVersion: currentSchemaVersion,
    device: device ?? this.device,
    account: account ?? this.account,
    updatedAt: updatedAt ?? DateTime.now().toUtc(),
  );

  Map<String, Object> toJson() => {
    'schemaVersion': schemaVersion,
    'device': device.toJson(),
    'account': account.toJson(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}

int _validRest(int value) => value.clamp(15, 600).toInt();

int _validQuickAdd(int value) => value == 30 ? 30 : 15;

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const <String, dynamic>{};

bool _bool(Object? value, bool fallback) => value is bool ? value : fallback;

int _int(Object? value, int fallback) =>
    value is num ? value.toInt() : fallback;

T _enumByName<T extends Enum>(List<T> values, Object? value, T fallback) {
  final name = value?.toString();
  for (final candidate in values) {
    if (candidate.name == name) return candidate;
  }
  return fallback;
}
