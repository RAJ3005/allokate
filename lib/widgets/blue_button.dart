import 'package:allokate/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BlueButton extends StatelessWidget {
  final String buttonTitle;
  final VoidCallback onPressed;

  const BlueButton({Key key, this.buttonTitle, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 50,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: onPressed == null ? kMainColorkGreyColor : kBlueColor,
        ),
        onPressed: onPressed,
        child: Text(
          buttonTitle,
          style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}
