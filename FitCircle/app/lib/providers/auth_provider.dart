// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';
import '../models/profile.dart';
import '../models/family.dart';
import '../config/supabase_config.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();
  final _familyService = FamilyService();

  AuthStatus _status = AuthStatus.uninitialized;
  Profile? _profile;
  Family? _family;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  Profile? get profile => _profile;
  Family? get family => _family;
  bool get hasFamily => _family != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _authService.currentUser;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _authService.authStateChanges.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        await loadUserData();
        _status = AuthStatus.authenticated;
      } else if (event == AuthChangeEvent.signedOut) {
        _profile = null;
        _family = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });

    if (_authService.isLoggedIn) {
      await loadUserData();
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> loadUserData() async {
    final user = currentUser;
    if (user == null) return;

    try {
      final client = SupabaseConfig.client;
      final profileData = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileData != null) {
        _profile = Profile.fromJson(profileData);
      }

      _family = await _familyService.getMyFamily();
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<bool> signUp({required String email, required String password, required String name}) async {
    _setLoading(true);
    try {
      final res = await _authService.signUp(email: email, password: password, name: name);
      if (res.user != null) {
        await loadUserData();
        _status = AuthStatus.authenticated;
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
    return false;
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    try {
      final res = await _authService.signIn(email: email, password: password);
      if (res.user != null) {
        await loadUserData();
        _status = AuthStatus.authenticated;
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
    return false;
  }

  Future<void> signOut() async {
    _setLoading(true);
    await _authService.signOut();
    _profile = null;
    _family = null;
    _status = AuthStatus.unauthenticated;
    _setLoading(false);
  }

  Future<bool> createFamily(String familyName) async {
    _setLoading(true);
    try {
      _family = await _familyService.createFamily(familyName);
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
    return false;
  }

  Future<bool> joinFamily(String code) async {
    _setLoading(true);
    try {
      _family = await _familyService.joinFamily(code);
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
    return false;
  }

  Future<void> updateProfile({String? name, int? dailyStepGoal}) async {
    final user = currentUser;
    if (user == null || _profile == null) return;
    try {
      final updates = <String, dynamic>{
        if (name != null) 'name': name,
        if (dailyStepGoal != null) 'daily_step_goal': dailyStepGoal,
      };

      await SupabaseConfig.client
          .from('profiles')
          .update(updates)
          .eq('id', user.id);

      _profile = _profile!.copyWith(name: name, dailyStepGoal: dailyStepGoal);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }
}
