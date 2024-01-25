import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:picmory/repositories/auth_repository.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SigninViewmodel extends ChangeNotifier {
  final _authRepository = AuthRepository();

  /// 구글 로그인
  signinWithGoogle(BuildContext context) async {
    try {
      final webClientId = dotenv.get('GOOGLE_WEB_CLIENT_ID');

      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        serverClientId: webClientId,
      ).signIn();

      if (googleUser == null) throw 'No googleUser';

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null || accessToken == null) {
        throw 'No idToken or accessToken';
      }

      await _authRepository
          .signInWithGoogle(
            idToken: idToken,
            accessToken: accessToken,
          )
          .then(
            (value) => value ? context.go('/home') : null,
          );
    } catch (error) {
      log(
        error.toString(),
        name: 'signinWithGoogle',
        error: error,
      );
    }
  }

  /// 애플 로그인
  signinWithApple(BuildContext context) async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw 'No ID Token found.';
      }

      _authRepository
          .signInWithApple(
            idToken: idToken,
          )
          .then(
            (value) => value ? context.go('/home') : null,
          );
    } catch (error) {
      log(
        error.toString(),
        name: 'signInWithApple',
        error: error,
      );
    }
  }
}
