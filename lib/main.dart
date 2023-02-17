import 'package:allokate/screens/onboarding/splash_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'model/funds.dart';
import 'model/icons.dart';
import 'model/info_cards.dart';
import 'model/projection_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<FundList>(create: (_) => FundList()),
          ChangeNotifierProvider<IconList>(create: (_) => IconList()),
          ChangeNotifierProvider<InfoCardList>(create: (_) => InfoCardList()),
          ChangeNotifierProvider<ProjectionData>(create: (_) => ProjectionData())
        ],
        child: MaterialApp(
          title: 'Flutter Demo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(primarySwatch: Colors.blue, fontFamily: GoogleFonts.aBeeZee().fontFamily),
          home: const SplashPage(),
        ));
  }
}
