import 'package:flutter/material.dart';

class NavDrawerHeader extends StatefulWidget {
  const NavDrawerHeader({Key key}) : super(key: key);

  @override
  _NavDrawerHeaderState createState() => _NavDrawerHeaderState();
}

class _NavDrawerHeaderState extends State<NavDrawerHeader> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 200,
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.fill,
            image: AssetImage('assets/allokate_nav_header.png'),
          ),
        ),
      ),
    );
  }
}
