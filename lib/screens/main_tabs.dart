import 'package:allokate/constants/styles.dart';
import 'package:allokate/screens/home/home_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import 'home/allokate_page.dart';
import 'home/projections_page.dart';

class MainTabs extends StatefulWidget {
  static const id = 'tabs_home_page';

  const MainTabs({Key key}) : super(key: key);

  @override
  _MainTabsState createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> with TickerProviderStateMixin {
  final _controller = CupertinoTabController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      controller: _controller,
      tabBar: CupertinoTabBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Ionicons.home, size: 22), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(
                Ionicons.pie_chart,
                size: 22,
              ),
              label: 'Allokate'),
          BottomNavigationBarItem(icon: Icon(Ionicons.stats_chart, size: 22), label: 'Projections'),
        ],
        activeColor: kMainColor,
        inactiveColor: Colors.grey,
      ),
      tabBuilder: (context, index) {
        CupertinoTabView returnValue;
        switch (index) {
          case 0:
            returnValue = CupertinoTabView(builder: (context) {
              return const SafeArea(
                top: false,
                child: CupertinoPageScaffold(
                  child: HomePage(),
                ),
              );
            });
            break;
          case 1:
            returnValue = CupertinoTabView(builder: (context) {
              return CupertinoPageScaffold(
                child: AllokatePage(
                  mainTabsController: _controller,
                ),
              );
            });
            break;
          case 2:
            returnValue = CupertinoTabView(builder: (context) {
              return const ProjectionsPage();
            });
            break;
        }
        return returnValue;
      },
    );
  }
}
