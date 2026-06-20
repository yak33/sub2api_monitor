import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Theme Mode ──
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('theme_mode') ?? 0;
    state = ThemeMode.values[index];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }
}

// ── Base URL ──
final baseUrlProvider = StateNotifierProvider<BaseUrlNotifier, String>((ref) {
  return BaseUrlNotifier();
});

class BaseUrlNotifier extends StateNotifier<String> {
  BaseUrlNotifier() : super('http://localhost:8080') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('base_url') ?? 'http://localhost:8080';
  }

  Future<void> setBaseUrl(String url) async {
    state = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_url', url);
  }
}
