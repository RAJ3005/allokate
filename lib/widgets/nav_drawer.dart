import 'package:allokate/constants/strings.dart';
import 'package:allokate/screens/onboarding/login_page.dart';
import 'package:allokate/services/auth.dart';
import 'package:allokate/widgets/face_touch_id.dart';
import 'package:allokate/widgets/nav_drawer_header.dart';
import 'package:allokate/widgets/pdf_view_page.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class NavDrawer extends StatefulWidget {
  const NavDrawer({Key key}) : super(key: key);

  @override
  _NavDrawerState createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  void faceTouchIdClicked() async {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => const FaceTouchId(),
      ),
    );
  }

  void privacyPolicyClicked() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PdfViewPage(
          appBarTitle: 'Privacy Policy',
          pdfUrl: privacyPolicyUrl,
        ),
      ),
    );
  }

  void termsAndConditionsClicked() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PdfViewPage(
          appBarTitle: 'Terms & Conditions',
          pdfUrl: termsAndConditionsUrl,
        ),
      ),
    );
  }

  void signOut() async {
    await Auth().signOut();
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => const LoginPage(
          fromSignOut: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget menuItem({String title, IconData icon, @required VoidCallback onPressed}) {
      return Material(
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              children: [
                Expanded(
                  child: Icon(
                    icon,
                    size: 20,
                    color: Colors.black,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget myDrawerList() {
      return Container(
        padding: const EdgeInsets.only(
          top: 15,
        ),
        child: Column(
          // shows the list of menu drawer
          children: [
            FutureBuilder<bool>(
                future: LocalAuthentication().canCheckBiometrics,
                builder: (context, snap) {
                  if (snap == null || snap.data == null) return Container();
                  if (snap.data == false) {
                    return Container();
                  }
                  return menuItem(title: 'Face/Touch ID login', icon: Icons.fingerprint, onPressed: faceTouchIdClicked);
                }),
            menuItem(title: 'Privacy policy', icon: Icons.privacy_tip_outlined, onPressed: privacyPolicyClicked),
            menuItem(
                title: 'Terms & Conditions', icon: Icons.text_snippet_outlined, onPressed: termsAndConditionsClicked),
            menuItem(title: 'Sign out', icon: Icons.logout_sharp, onPressed: signOut),
          ],
        ),
      );
    }

    return Drawer(
      child: Drawer(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const NavDrawerHeader(),
              myDrawerList(),
            ],
          ),
        ),
      ),
    );
  }
}
