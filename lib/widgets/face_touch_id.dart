import 'package:allokate/constants/strings.dart';
import 'package:allokate/constants/styles.dart';
import 'package:allokate/utils/alerts.dart';
import 'package:allokate/utils/local_auth_helper.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FaceTouchId extends StatefulWidget {
  const FaceTouchId({Key key}) : super(key: key);

  @override
  _FaceTouchIdState createState() => _FaceTouchIdState();
}

class _FaceTouchIdState extends State<FaceTouchId> {
  @override
  void initState() {
    super.initState();
    _initBiometrics();
  }

  _initBiometrics() async {
    var prefs = await SharedPreferences.getInstance();
    bool b = prefs.getBool(sharedPrefsBiometricsActive) ?? false;
    setState(() {
      _biometricsEnabled = b;
    });
  }

  _onBiometricsSwitchChanged(BuildContext context, bool v) async {
    bool success;

    try {
      success = await LocalAuthHelper.offerBiometrics();
    } catch (e) {
      Alerts.showErrorAlert(context: context, title: 'Error', message: 'There was an error starting biometrics.');
      return;
    }

    if (success) {
      setState(() => _biometricsEnabled = v);
      var prefs = await SharedPreferences.getInstance();
      await prefs.setBool(sharedPrefsBiometricsActive, v);
      Alerts.showSuccessAlert(
          context: context, title: 'Success', message: 'Biometric login was turned ${v ? 'on' : 'off'}.');
      return;
    } else {
      Alerts.showErrorAlert(context: context, title: 'Error', message: 'There was an error starting biometrics.');
      return;
    }
  }

  bool _biometricsEnabled = false;

  @override
  Widget build(BuildContext context) {
    Widget appBar = AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: kBlueColor),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Image.asset('assets/fingerprint.png', height: 60),
              const SizedBox(
                height: 10,
              ),
              const Text(
                'Toggle Fingerprint/Face ID Authentication',
                style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                'You can enable biometric authentication every time the app is opened.',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                  width: 200,
                  height: 100,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(
                        child: AutoSizeText('Biometric login is currently ${_biometricsEnabled ? 'on' : 'off'}',
                            minFontSize: 6,
                            maxFontSize: 16,
                            textAlign: TextAlign.end,
                            style: TextStyle(color: Colors.grey[500], fontSize: 16))),
                    Switch(value: _biometricsEnabled, onChanged: (v) => _onBiometricsSwitchChanged(context, v))
                  ]))
            ],
          ),
        ),
      ),
    );
  }
}
