import 'package:allokate/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class Alerts {
  static Future<bool> showErrorAlert({BuildContext context, String title, String message}) async {
    return await Alert(
      context: context,
      type: AlertType.error,
      title: title,
      desc: message,
      buttons: [
        DialogButton(
          child: const Text(
            'OK',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          width: 120,
          color: kMainColor,
        )
      ],
    ).show();
  }

  static Future<bool> showDeleteAlert(
      {BuildContext context, String title, String message, @required Function deleteFund}) async {
    return await Alert(
      context: context,
      type: AlertType.error,
      title: title,
      desc: message,
      buttons: [
        DialogButton(
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          width: 120,
          color: kMainColor,
        ),
        DialogButton(
          child: const Text(
            'Delete',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: deleteFund,
          width: 120,
          color: kMainColor,
        ),
      ],
    ).show();
  }

  static Future<bool> showSuccessAlert({BuildContext context, String title, String message}) async {
    return await Alert(
      context: context,
      type: AlertType.success,
      title: title,
      desc: message,
      buttons: [
        DialogButton(
          child: const Text(
            'OK',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
          width: 120,
          color: kMainColor,
        )
      ],
    ).show();
  }

  static Future<bool> showExceptionAlert({BuildContext context, Exception exception}) {
    return showErrorAlert(
        context: context, title: 'Error', message: exception.toString().substring('Exception: '.length));
  }

  static Future<bool> showWarningAlert({BuildContext context, String title = 'Warning', String message}) async {
    return await Alert(
      context: context,
      type: AlertType.warning,
      title: title,
      desc: message,
      buttons: [
        DialogButton(
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
          width: 120,
          color: kMainColor,
        ),
        DialogButton(
          child: const Text(
            'OK',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
          width: 120,
          color: kMainColor,
        )
      ],
    ).show();
  }
}
