import 'package:allokate/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class UnderlinedTextField extends StatelessWidget {
  final String labelText;
  final bool obscureText;
  final TextEditingController controller;
  final List<TextInputFormatter> formatterList;
  final String prefixText;
  final Widget suffixIcon;

  const UnderlinedTextField(
      {Key key,
      this.suffixIcon,
      this.labelText,
      this.obscureText = false,
      this.controller,
      this.formatterList,
      this.prefixText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        suffixIcon: suffixIcon,
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.withOpacity(0.5), width: 1)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: kMainColor, width: 1)),
        labelText: labelText,
        labelStyle: GoogleFonts.montserrat(color: kMainColor),
        prefixText: prefixText,
        prefixStyle: GoogleFonts.montserrat(color: kMainColor, fontSize: 16),
      ),
      inputFormatters: formatterList,
    );
  }
}
