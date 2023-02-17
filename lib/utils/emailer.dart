import 'package:allokate/constants/strings.dart';
import 'package:flutter/foundation.dart';
import 'package:sendgrid_mailer/sendgrid_mailer.dart';

class SendGridEmailer {
  sendEmail({String name, @required String emailAddress}) async {
    final mailer = Mailer(apiKey);
    final toAddress = Address(emailAddress);
    const fromAddress = Address(senderEmailAddress);
    const subject = '';
    final personalization = Personalization([toAddress], dynamicTemplateData: {'name': name});

    final email = Email([personalization], fromAddress, subject, templateId: welcomeEmailTemplateId);
    var result = await mailer.send(email);
    if (result.isError) {
      if (kDebugMode) {
        print(result.asError.error.toString());
      }
    }
  }
}
