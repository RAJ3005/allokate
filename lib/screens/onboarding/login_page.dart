import 'package:allokate/constants/styles.dart';
import 'package:allokate/screens/onboarding/sign_up_page.dart';
import 'package:allokate/screens/onboarding/verify_email_page.dart';
import 'package:allokate/services/auth.dart';
import 'package:allokate/services/database.dart';
import 'package:allokate/utils/alerts.dart';
import 'package:allokate/utils/string_utils.dart';
import 'package:allokate/widgets/blue_button.dart';
import 'package:allokate/widgets/social_media_login_options.dart';
import 'package:allokate/widgets/underlined_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import '../main_tabs.dart';

class LoginPage extends StatefulWidget {
  final bool fromSignOut;

  const LoginPage({Key key, this.fromSignOut}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _emailController, _passwordController;

  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  bool get userInformationIsValid =>
      !(StringUtils.isNullOrEmpty(_emailController.text) || StringUtils.isNullOrEmpty(_passwordController.text));

  void forgotPassword() async {
    if (StringUtils.isNullOrEmpty(_emailController.text)) {
      Alerts.showErrorAlert(
          context: context,
          title: 'Enter Email',
          message: 'Enter your email address to reset your '
              'password');
    } else {
      try {
        await Auth().sendForgotPasswordEmail(_emailController.text);
        Alerts.showSuccessAlert(
            context: context,
            title: 'Check your inbox (and spam)',
            message: 'Follow the link in '
                'the email to reset your password.');
      } catch (e) {
        Alerts.showErrorAlert(
            context: context,
            title: 'Password Reset Failed',
            message: 'Please check your email '
                'address and try '
                'again.');
      }
    }
  }

  void signIn() async {
    if (userInformationIsValid) {
      String userId;
      String errorMessage;

      try {
        userId = await Auth().signIn(_emailController.text, _passwordController.text);
      } catch (error) {
        switch (error.code) {
          case 'wrong-password':
            errorMessage = 'You entered an incorrect password';
            break;
          case 'user-not-found':
            errorMessage = 'There was no user found with this email address';
            break;
          default:
            errorMessage = 'Please check your details and try again.';
        }
      }
      if (errorMessage != null) {
        Alerts.showErrorAlert(context: context, title: 'Error', message: errorMessage);
        return;
      }

      if (!StringUtils.isNullOrEmpty(userId)) {
        // await Alerts.showSuccessAlert(context: context, title: 'Logged In', message: 'You are successfully logged in');
        if (FirebaseAuth.instance.currentUser.emailVerified) {
          if (await DatabaseService.usersDocumentExistsInDatabase) {
            Navigator.of(context, rootNavigator: true)
                .pushReplacement(MaterialPageRoute(builder: (_) => const MainTabs()));
          } else {
            await FirebaseAuth.instance.signOut();
            await Alerts.showErrorAlert(
              context: context,
              title: 'Account Not Found',
              message: 'This account is invalid and cannot be used.',
            );
            Navigator.of(context, rootNavigator: true)
                .pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage(fromSignOut: true)));
          }
        } else {
          Navigator.of(context, rootNavigator: true).pushReplacement(MaterialPageRoute(
              builder: (_) => VerifyEmailPage(
                    email: FirebaseAuth.instance.currentUser.email,
                  )));
        }
      }
    } else {
      Alerts.showErrorAlert(
          context: context,
          title: 'Missing info',
          message: 'Please enter your email and password '
              'to sign in.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: widget.fromSignOut
              ? null
              : IconButton(
                  icon: const Icon(
                    Ionicons.chevron_back_circle_outline,
                    color: kMainColor,
                    size: 30,
                  ),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                )),
      body: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/login_page_graphic.png',
                      width: 300,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  'Login',
                  style: GoogleFonts.montserrat(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Text(
                  'Please login to your account',
                  style: GoogleFonts.montserrat(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                UnderlinedTextField(
                  obscureText: false,
                  labelText: 'Email Address',
                  controller: _emailController,
                ),
                const SizedBox(height: 20),
                UnderlinedTextField(
                  suffixIcon: IconButton(
                    icon: Icon(obscurePassword ? Ionicons.eye_off : Ionicons.eye, color: Colors.black),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  obscureText: obscurePassword,
                  labelText: 'Password',
                  controller: _passwordController,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.montserrat(),
                      ),
                      onPressed: forgotPassword,
                    )
                  ],
                ),
                const SizedBox(height: 10),
                BlueButton(
                  buttonTitle: 'Login',
                  onPressed: signIn,
                ),
                const SizedBox(height: 40),
                const SocialMediaLoginOptions(),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account?',
                      style: GoogleFonts.montserrat(fontSize: 16),
                    ),
                    const SizedBox(width: 5),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'Register here',
                        style: GoogleFonts.montserrat(color: kBlueColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SignUpPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 30)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
