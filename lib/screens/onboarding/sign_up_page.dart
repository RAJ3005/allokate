import 'package:allokate/constants/styles.dart';
import 'package:allokate/screens/onboarding/verify_email_page.dart';
import 'package:allokate/services/auth.dart';
import 'package:allokate/utils/alerts.dart';
import 'package:allokate/utils/string_utils.dart';
import 'package:allokate/widgets/blue_button.dart';
import 'package:allokate/widgets/social_media_login_options.dart';
import 'package:allokate/widgets/underlined_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  TextEditingController _fullNameController, _emailController, _phoneNumberController, _passwordController;

  bool get userInformationIsValid => !(StringUtils.isNullOrEmpty(_fullNameController.text) ||
      StringUtils.isNullOrEmpty(_emailController.text) ||
      StringUtils.isNullOrEmpty(_phoneNumberController.text) ||
      StringUtils.isNullOrEmpty(_passwordController.text));

  bool obscurePassword = true;

  @override
  void initState() {
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _passwordController = TextEditingController();
    super.initState();
  }

  void signUp() async {
    if (userInformationIsValid) {
      String userId;
      String errorMessage;

      try {
        userId = await Auth().signUp(_emailController.text, _passwordController.text);
      } catch (error) {
        switch (error.code) {
          case 'wrong-password':
            errorMessage = 'You entered an incorrect password';
            break;
          case 'email-already-in-use':
            errorMessage = 'This email address is already in use. Please log in.';
            break;
          case 'user-not-found':
            errorMessage = 'There was no user found with this email address';
            break;
          case 'invalid-email':
            errorMessage = 'You entered an invalid email';
            break;
          default:
            errorMessage = 'Please check your details and try again.';
        }
      }
      if (errorMessage != null) {
        Alerts.showErrorAlert(context: context, title: 'Error', message: errorMessage);
        return;
      }
      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'fullName': _fullNameController.text,
          'email': _emailController.text,
          'phoneNumber': _phoneNumberController.text,
          'balanceHistory': {
            DateTime.now().millisecondsSinceEpoch.toString(): 0,
          }
        });

        await FirebaseAuth.instance.currentUser.sendEmailVerification();
        await Alerts.showSuccessAlert(
            context: context,
            title: 'Success',
            message: 'Your account has been created'
                ' successfully');

        Navigator.of(context, rootNavigator: true)
            .pushReplacement(MaterialPageRoute(builder: (_) => VerifyEmailPage(email: _emailController.text)));
      }
    } else {
      Alerts.showErrorAlert(
          context: context,
          title: 'Missing info',
          message: 'Please complete the '
              'form to sign up.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(
              Ionicons.chevron_back_circle_outline,
              color: kMainColor,
              size: 30,
            ),
            onPressed: () {
              Navigator.of(context).pop();
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
                      'assets/create_account_page_graphic.png',
                      width: 300,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  'Create Account',
                  style: GoogleFonts.montserrat(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Text(
                  'Please register your account',
                  style: GoogleFonts.montserrat(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                UnderlinedTextField(
                  labelText: 'Full Name',
                  controller: _fullNameController,
                ),
                const SizedBox(height: 20),
                UnderlinedTextField(
                  labelText: 'Email Address',
                  controller: _emailController,
                ),
                const SizedBox(height: 20),
                UnderlinedTextField(
                  labelText: 'Phone Number',
                  prefixText: '+44',
                  controller: _phoneNumberController,
                  formatterList: [LengthLimitingTextInputFormatter(10)],
                ),
                const SizedBox(height: 30),
                UnderlinedTextField(
                  suffixIcon: IconButton(
                    icon: Icon(obscurePassword ? Ionicons.eye_off : Ionicons.eye, color: Colors.black),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  labelText: 'Password',
                  controller: _passwordController,
                  obscureText: obscurePassword,
                ),
                const SizedBox(height: 30),
                BlueButton(
                  buttonTitle: 'Register',
                  onPressed: signUp,
                ),
                const SizedBox(height: 30),
                const SocialMediaLoginOptions(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: GoogleFonts.montserrat(fontSize: 16),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'Login',
                        style: GoogleFonts.montserrat(color: kBlueColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
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
