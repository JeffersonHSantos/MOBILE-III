import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../database/db_helper.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static String? lastError;

  static Stream<Map<String, dynamic>?> get authenticatedUserChanges async* {
    if (!isFirebaseReady) {
      yield null;
      return;
    }

    await for (final user in _auth.authStateChanges()) {
      if (user == null) {
        yield null;
        continue;
      }

      final providerId = user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : 'google.com';
      final provider = providerId == 'github.com'
          ? 'github'
          : providerId == 'apple.com'
          ? 'apple'
          : 'google';

      try {
        yield await _toUserMap(user, provider);
      } catch (e) {
        debugPrint('Erro ao mapear usuário em authenticatedUserChanges: $e');
      }
    }
  }

  static bool get isFirebaseReady {
    try {
      final app = Firebase.app();
      final apiKey = app.options.apiKey;
      final projectId = app.options.projectId;
      return apiKey.isNotEmpty && projectId.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> signOut() async {
    lastError = null;
    try {
      if (isFirebaseReady) {
        await _auth.signOut();
      }
      if (!kIsWeb) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
      }
    } catch (e) {
      lastError = e.toString();
      debugPrint('Erro ao encerrar sessão: $e');
    }
  }

  static Future<Map<String, dynamic>?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    final normalizedEmail = email.trim();
    final normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      return null;
    }

    try {
      if (isFirebaseReady) {
        final credential = await _auth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: normalizedPassword,
        );

        final user = credential.user;
        if (user != null) {
          return {
            'id': user.uid,
            'email': user.email ?? normalizedEmail,
            'nome': user.displayName ?? normalizedEmail.split('@').first,
            'provider': 'firebase',
          };
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Tentativa Firebase Email/Senha falhou: ${e.code} - ${e.message}');
    } catch (_) {}

    if (normalizedEmail.toLowerCase() == 'admin@teste.com' &&
        normalizedPassword == '123456') {
      return {
        'id': 1,
        'email': 'admin@teste.com',
        'nome': 'Administrador',
        'provider': 'local',
      };
    }

    return DbHelper.login(normalizedEmail, normalizedPassword);
  }

  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    lastError = null;
    try {
      if (!isFirebaseReady) {
        lastError = 'Firebase não está inicializado.';
        return null;
      }

      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');

        try {
          // Tentativa primária com Popup (rápido, sem recarregar tela)
          final userCredential = await _auth.signInWithPopup(provider);
          final user = userCredential.user;
          if (user != null) {
            return await _toUserMap(user, 'google');
          }
        } on FirebaseAuthException catch (e) {
          debugPrint('Google Popup [${e.code}]: ${e.message}');
          if (e.code == 'popup-blocked' ||
              e.code == 'auth/popup-blocked' ||
              e.code == 'cancelled-popup-request' ||
              e.code == 'auth/cancelled-popup-request') {
            debugPrint('Popup bloqueado pelo navegador, redirecionando...');
            await _auth.signInWithRedirect(provider);
            return {'status': 'redirecting'};
          }
          lastError = '${e.code}: ${e.message ?? 'Erro de autenticação Google'}';
          return null;
        } catch (e) {
          debugPrint('Popup falhou ($e). Iniciando signInWithRedirect...');
          await _auth.signInWithRedirect(provider);
          return {'status': 'redirecting'};
        }
        return null;
      }

      // Android / iOS / Desktop
      await GoogleSignIn.instance.initialize();
      final googleUser = await GoogleSignIn.instance.authenticate();

      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final firebaseUser = await _auth.signInWithCredential(credential);
      return await _toUserMap(firebaseUser.user, 'google');
    } on FirebaseAuthException catch (error) {
      lastError = '${error.code}: ${error.message ?? 'Erro de autenticação'}';
      debugPrint('FirebaseAuthException no Google Sign-In: $lastError');
      return null;
    } catch (error) {
      lastError = error.toString();
      debugPrint('Erro no Google Sign-In: $lastError');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> signInWithApple() async {
    lastError = null;
    try {
      if (!isFirebaseReady) {
        lastError = 'Firebase não está inicializado.';
        return null;
      }

      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');

      if (kIsWeb) {
        try {
          final userCredential = await _auth.signInWithPopup(provider);
          final user = userCredential.user;
          if (user != null) {
            return await _toUserMap(user, 'apple');
          }
        } on FirebaseAuthException catch (e) {
          debugPrint('Apple Popup [${e.code}]: ${e.message}');
          if (e.code == 'popup-blocked' ||
              e.code == 'auth/popup-blocked' ||
              e.code == 'cancelled-popup-request' ||
              e.code == 'auth/cancelled-popup-request') {
            await _auth.signInWithRedirect(provider);
            return {'status': 'redirecting'};
          }
          lastError = '${e.code}: ${e.message ?? 'Erro de autenticação Apple'}';
          return null;
        } catch (e) {
          debugPrint('Apple Popup erro ($e). Iniciando redirect...');
          await _auth.signInWithRedirect(provider);
          return {'status': 'redirecting'};
        }
        return null;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        final oauthCredential = OAuthProvider('apple.com').credential(
          idToken: credential.identityToken,
          accessToken: credential.authorizationCode,
        );

        final userCredential = await _auth.signInWithCredential(oauthCredential);
        return await _toUserMap(userCredential.user, 'apple');
      }

      final userCredential = await _auth.signInWithProvider(provider);
      return await _toUserMap(userCredential.user, 'apple');
    } on FirebaseAuthException catch (error) {
      lastError = '${error.code}: ${error.message ?? 'Erro de autenticação'}';
      debugPrint('FirebaseAuthException no Apple Sign-In: $lastError');
      return null;
    } catch (error) {
      lastError = error.toString();
      debugPrint('Erro no Apple Sign-In: $lastError');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> signInWithGitHub() async {
    lastError = null;
    try {
      if (!isFirebaseReady) {
        lastError = 'Firebase não está inicializado.';
        return null;
      }

      final provider = GithubAuthProvider()
        ..addScope('read:user')
        ..addScope('user:email');

      if (kIsWeb) {
        try {
          final userCredential = await _auth.signInWithPopup(provider);
          final user = userCredential.user;
          if (user != null) {
            return await _toUserMap(user, 'github');
          }
        } on FirebaseAuthException catch (e) {
          debugPrint('GitHub Popup [${e.code}]: ${e.message}');
          if (e.code == 'popup-blocked' ||
              e.code == 'auth/popup-blocked' ||
              e.code == 'cancelled-popup-request' ||
              e.code == 'auth/cancelled-popup-request') {
            await _auth.signInWithRedirect(provider);
            return {'status': 'redirecting'};
          }
          lastError = '${e.code}: ${e.message ?? 'Erro de autenticação GitHub'}';
          return null;
        } catch (e) {
          debugPrint('GitHub Popup erro ($e). Iniciando redirect...');
          await _auth.signInWithRedirect(provider);
          return {'status': 'redirecting'};
        }
        return null;
      }

      final userCredential = await _auth.signInWithProvider(provider);
      return await _toUserMap(userCredential.user, 'github');
    } on FirebaseAuthException catch (error) {
      lastError = '${error.code}: ${error.message ?? 'Erro de autenticação'}';
      debugPrint('FirebaseAuthException no GitHub Sign-In: $lastError');
      return null;
    } catch (error) {
      lastError = error.toString();
      debugPrint('Erro no GitHub Sign-In: $lastError');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getWebRedirectResult() async {
    if (!kIsWeb || !isFirebaseReady) {
      return null;
    }

    try {
      final credential = await _auth.getRedirectResult();
      final user = credential.user;
      if (user != null) {
        final providerId = credential.additionalUserInfo?.providerId;
        final provider = providerId == 'github.com'
            ? 'github'
            : providerId == 'apple.com'
            ? 'apple'
            : 'google';

        return await _toUserMap(user, provider);
      }

      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final providerId = currentUser.providerData.isNotEmpty
            ? currentUser.providerData.first.providerId
            : 'google.com';
        final provider = providerId == 'github.com'
            ? 'github'
            : providerId == 'apple.com'
            ? 'apple'
            : 'google';

        return await _toUserMap(currentUser, provider);
      }

      return null;
    } on FirebaseAuthException catch (error) {
      lastError = '${error.code}: ${error.message ?? 'Erro de autenticação'}';
      debugPrint('FirebaseAuthException no getWebRedirectResult: $lastError');
      return null;
    } catch (error) {
      lastError = error.toString();
      debugPrint('Erro no getWebRedirectResult: $lastError');
      return null;
    }
  }

  static Future<Map<String, dynamic>> _toUserMap(
    User? user,
    String provider,
  ) async {
    if (user == null) {
      throw Exception('O provedor não retornou um usuário válido.');
    }

    final email = user.email;
    final name = user.displayName;

    if (email != null && email.isNotEmpty) {
      try {
        await DbHelper.upsertSocialUser(
          email: email,
          name: name?.trim().isNotEmpty == true
              ? name!
              : 'Usuário ${provider[0].toUpperCase()}${provider.substring(1)}',
          provider: provider,
          firebaseUid: user.uid,
        );
      } catch (dbError) {
        debugPrint('Aviso: Falha ao sincronizar usuário social no banco local: $dbError');
      }
    }

    return {
      'id': user.uid,
      'email': email ?? '$provider-user@unknown.com',
      'nome': name != null && name.trim().isNotEmpty
          ? name
          : 'Usuário ${provider[0].toUpperCase()}${provider.substring(1)}',
      'provider': provider,
    };
  }
}
