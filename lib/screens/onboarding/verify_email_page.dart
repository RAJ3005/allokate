import 'package:allokate/constants/styles.dart';
import 'package:allokate/screens/main_tabs.dart';
import 'package:allokate/screens/onboarding/login_page.dart';
import 'package:allokate/utils/alerts.dart';
import 'package:allokate/utils/emailer.dart';
import 'package:allokate/widgets/blue_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';

class VerifyEmailPage extends StatefulWidget {
  final String fullName;
  final String email;

  const VerifyEmailPage({Key key, this.fullName, this.email}) : super(key: key);

  @override
  _VerifyEmailPageState createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool loading = false;

  void showSnackbar(BuildContext context, {String message}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void load() {
    setState(() {
      loading = true;
    });
  }

  void endLoad() {
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.logout,
                color: kMainColor,
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(fromSignOut: true),
                  ),
                );
              },
            )
          ],
          leading: !Navigator.of(context).canPop()
              ? null
              : IconButton(
                  icon: const Icon(
                    Ionicons.chevron_back_circle_outline,
                    color: kMainColor,
                    size: 30,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('An email has been sent to you',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset(
                    'assets/email.png',
                    height: 150,
                  ),
                ),
                const Text(
                    'Please follow the link in the email to verify your account. Make sure to your check spam/junk folder.',
                    textAlign: TextAlign.center),
                const SizedBox(
                  height: 45,
                ),
                BlueButton(
                  buttonTitle: 'Verify',
                  onPressed: () async {
                    load();

                    try {
                      await FirebaseAuth.instance.currentUser.reload();
                      if (FirebaseAuth.instance.currentUser.emailVerified) {
                        SendGridEmailer().sendEmail(name: widget.fullName, emailAddress: widget.email);

                        await Alerts.showSuccessAlert(
                            context: context, title: 'Success', message: 'Your email has been confirmed');

                        Navigator.of(context, rootNavigator: true)
                            .push(MaterialPageRoute(builder: (_) => const MainTabs()));
                      } else {
                        await Alerts.showErrorAlert(
                            context: context, title: 'Error', message: 'We could not confirm your email');
                      }
                    } catch (e) {
                      await Alerts.showErrorAlert(context: context, title: 'Error', message: e.toString());
                    }

                    endLoad();
                  },
                ),
                const SizedBox(
                  height: 40,
                ),
                const Text('Didn\'t get the email?'),
                const SizedBox(
                  height: 10,
                ),
                GestureDetector(
                  child: const Text(
                    'Resend Email',
                    style: TextStyle(color: Colors.blueAccent, fontSize: 16),
                  ),
                  onTap: () async {
                    load();

                    try {
                      await FirebaseAuth.instance.currentUser.sendEmailVerification();
                      showSnackbar(context, message: 'You have been sent a new email');
                    } catch (e) {
                      await Alerts.showErrorAlert(context: context, title: 'Error', message: e.toString());
                    }

                    endLoad();
                  },
                )
              ],
            ),
            !loading
                ? Container()
                : Container(
                    color: Colors.white.withOpacity(0.5),
                    child: const Center(
                        child: CircularProgressIndicator(
                      color: kMainColor,
                    )),
                  )
          ],
        ),
      ),
    );
  }
}
