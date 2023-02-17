import 'package:allokate/screens/main_tabs.dart';
import 'package:allokate/services/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cmoon_icons/flutter_cmoon_icons.dart';
import 'dart:io' show Platform;

class SocialMediaLoginOptions extends StatelessWidget {
  const SocialMediaLoginOptions({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    void loginWithSocial(Function login) async {
      UserCredential userCredential = await login();
      if (userCredential == null) return;
      DocumentSnapshot user = await FirebaseFirestore.instance.collection('users').doc(userCredential.user.uid).get();
      if (!user.exists) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user.uid).set({
          'fullName': userCredential.user.displayName,
          'email': userCredential.user.email,
          'profilePhotoUrl': userCredential.user.photoURL
        });
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainTabs(),
          ),
        );
      } else {
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainTabs(),
          ),
        );
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => loginWithSocial(Auth().loginWithGoogle),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: const Color(0xffDB4437)),
            child: const Center(
              child: CIcon(
                IconMoon.icon_google,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 30),
        if (!Platform.isAndroid)
          Column(
            children: [
              const SizedBox(width: 30),
              GestureDetector(
                onTap: () => loginWithSocial(Auth().loginWithApple),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.black),
                  child: const Center(
                    child: CIcon(
                      IconMoon.icon_apple,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(width: 30),
        GestureDetector(
          onTap: () => loginWithSocial(Auth().loginWithFacebook),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: const Color(0xFF4267B2)),
            child: const Center(
              child: CIcon(
                IconMoon.icon_facebook,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        )
      ],
    );
  }
}
