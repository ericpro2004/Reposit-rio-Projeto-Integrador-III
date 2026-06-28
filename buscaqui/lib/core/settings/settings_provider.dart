import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configurações do app persistidas localmente (tema, notificações).
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;

  AppSettings copyWith({ThemeMode? themeMode, bool? notificationsEnabled}) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );
}

/// Injetado em [main] (após carregar o SharedPreferences) via override.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider deve ser sobrescrito'),
);

const _kTheme = 'theme_mode';
const _kNotifications = 'notifications_enabled';

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return AppSettings(
      themeMode: _themeFromString(prefs.getString(_kTheme)),
      notificationsEnabled: prefs.getBool(_kNotifications) ?? true,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref.read(sharedPrefsProvider).setString(_kTheme, mode.name);
  }

  Future<void> setNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await ref.read(sharedPrefsProvider).setBool(_kNotifications, enabled);
  }

  /// Restaura as configurações para o padrão.
  Future<void> reset() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.remove(_kTheme);
    await prefs.remove(_kNotifications);
    state = const AppSettings();
  }

  static ThemeMode _themeFromString(String? v) => switch (v) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
