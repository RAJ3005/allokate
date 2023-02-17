import 'dart:async';
import 'dart:io';
import 'package:allokate/constants/strings.dart';
import 'package:allokate/constants/styles.dart';
import 'package:allokate/screens/main_tabs.dart';
import 'package:allokate/screens/onboarding/landing_page.dart';
import 'package:allokate/services/database.dart';
import 'package:allokate/utils/local_auth_helper.dart';
import 'package:allokate/screens/onboarding/verify_email_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  User _currentUser;
  final Completer<void> _completer = Completer();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      FirebaseAuth.instance.userChanges().listen((user) {
        _currentUser = user;
        if (!_completer.isCompleted) {
          _completer.complete();
        }
      });
      await tryBiometrics();
      checkUserState();
    });
  }

  tryBiometrics() async {
    await _completer.future;
    if (_currentUser == null) {
      return;
    }
    var prefs = await SharedPreferences.getInstance();
    bool biometricsActive = prefs.getBool(sharedPrefsBiometricsActive) ?? false;
    if (!biometricsActive) return;
    bool success = await LocalAuthHelper.offerBiometrics();
    if (!success) {
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      } else {
        await FirebaseAuth.instance.signOut();
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LandingPage(),
          ),
        );
      }
    }
  }

  checkUserState() async {
    if (_currentUser != null) {
      if (_currentUser.emailVerified) {
        if (await DatabaseService.usersDocumentExistsInDatabase) {
          Navigator.of(context, rootNavigator: true).pushReplacement(MaterialPageRoute(
            builder: (context) => const MainTabs(),
          ));
        } else {
          await FirebaseAuth.instance.signOut();
          Navigator.of(context, rootNavigator: true).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const LandingPage(),
            ),
          );
        }
      } else {
        Navigator.of(context, rootNavigator: true).pushReplacement(MaterialPageRoute(
          builder: (context) => VerifyEmailPage(
            email: _currentUser.email,
          ),
        ));
      }
    } else {
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LandingPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: kMainColor,
        child: Center(
          child: Image.asset(
            'assets/allokate_logo_white.png',
            width: 200,
          ),
        ),
      ),
    );
  }
}
