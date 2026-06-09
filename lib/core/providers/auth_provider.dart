import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';
import '../services/api_service.dart';

final secureStorageProvider = Provider((ref) => SecureStorageService());
final authServiceProvider = Provider((ref) => AuthService());
final apiServiceProvider = Provider((ref) => ApiService());

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      ref.read(authServiceProvider),
      ref.read(secureStorageProvider),
      ref.read(apiServiceProvider),
    );
  },
);

class AuthState {
  final bool fbLoginState;
  final bool twitterLoginState;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.fbLoginState = false,
    this.twitterLoginState = false,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? fbLoginState,
    bool? twitterLoginState,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      fbLoginState: fbLoginState ?? this.fbLoginState,
      twitterLoginState: twitterLoginState ?? this.twitterLoginState,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;
  final SecureStorageService _secureStorage;
  final ApiService _apiService;

  AuthController(this._authService, this._secureStorage, this._apiService)
    : super(AuthState()) {
    _checkInitialAuthStates();
  }

  Future<void> _checkInitialAuthStates() async {
    final fbToken = await _secureStorage.getFbToken();
    final twToken = await _secureStorage.getTwitterToken();

    state = state.copyWith(
      fbLoginState: fbToken != null,
      twitterLoginState: twToken != null,
    );
  }

  Future<bool> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      state = state.copyWith(
        errorMessage: 'Please Check Your Internet Connection',
      );
      return false;
    }
    return true;
  }

  Future<void> toggleFacebookLogin() async {
    if (state.fbLoginState) {
      // Logout
      await _authService.logoutFacebook();
      await _secureStorage.clearFbToken();
      state = state.copyWith(fbLoginState: false, errorMessage: null);
    } else {
      // Login
      if (await _checkConnectivity()) {
        state = state.copyWith(isLoading: true, errorMessage: null);
        try {
          final token = await _authService.loginWithFacebook();
          if (token != null) {
            await _secureStorage.saveFbToken(token);
            state = state.copyWith(fbLoginState: true, isLoading: false);
          } else {
            state = state.copyWith(
              isLoading: false,
              errorMessage: 'Facebook Login Failed',
            );
          }
        } catch (e) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Facebook Config Error: Check Native Setup',
          );
        }
      }
    }
  }

  Future<void> toggleTwitterLogin() async {
    if (state.twitterLoginState) {
      // Logout
      await _secureStorage.clearTwitterToken();
      state = state.copyWith(twitterLoginState: false, errorMessage: null);
    } else {
      // Login
      if (await _checkConnectivity()) {
        state = state.copyWith(isLoading: true, errorMessage: null);
        try {
          final tokens = await _authService.loginWithTwitter();
          if (tokens != null) {
            await _secureStorage.saveTwitterToken(
              tokens['token']!,
              tokens['secret']!,
            );
            state = state.copyWith(twitterLoginState: true, isLoading: false);
          } else {
            state = state.copyWith(
              isLoading: false,
              errorMessage: 'Twitter Login Failed',
            );
          }
        } catch (e) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Twitter Error: $e',
          );
        }
      }
    }
  }

  Future<bool> postMessage(int platformId, String message) async {
    if (message.isEmpty) {
      state = state.copyWith(errorMessage: 'Kindly Fill the text to share');
      return false;
    }

    if (!await _checkConnectivity()) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);
    bool success = true;

    // platformId logic from Xamarin:
    // 3: Both
    // 1: FB only
    // 2: Twitter only
    try {
      if (platformId == 1 || platformId == 3) {
        final fbToken = await _secureStorage.getFbToken();
        if (fbToken != null) {
          final res = await _apiService.postToFacebook(fbToken, message);
          if (!res) success = false;
        }
      }

      if (platformId == 2 || platformId == 3) {
        final twTokens = await _secureStorage.getTwitterToken();
        if (twTokens != null) {
          final res = await _apiService.postToTwitter(
            twTokens['token']!,
            twTokens['secret']!,
            message,
          );
          if (!res) success = false;
        }
      }
    } catch (e) {
      success = false;
    }

    state = state.copyWith(isLoading: false);
    return success;
  }
}
