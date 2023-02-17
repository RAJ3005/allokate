import 'package:allokate/model/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class InfoCardList extends ChangeNotifier {
  InfoCardList() {
    init();
  }

  List<InfoCardData> list = [];

  init() async {
    var snap = await FirebaseFirestore.instance.collection(infoCardsCollection).get();
    if (snap.size == 0) return;

    List<Future<InfoCardData>> futureData = [];
    for (var doc in snap.docs) {
      var infoCardData = InfoCardData.fromDoc(doc.data());

      var query = FirebaseFirestore.instance
          .collection(infoCardThemesCollection)
          .doc(infoCardData.themeId)
          .get()
          .then((snap) => infoCardData..theme = InfoCardTheme.fromDoc(snap.data()));
      futureData.add(query);
    }

    list = await Future.wait(futureData);

    notifyListeners();
  }
}

class InfoCardData {
  InfoCardData({this.title, this.body, this.imageUrl, this.themeId});
  final String title;
  final String body;
  final String imageUrl;
  final String themeId;

  InfoCardTheme theme;

  factory InfoCardData.fromDoc(Map<String, dynamic> map) {
    return InfoCardData(title: map['title'], body: map['body'], imageUrl: map['imageUrl'], themeId: map['themeId']);
  }

  Map<String, dynamic> toDoc() {
    return {
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'themeId': themeId,
    };
  }
}

class InfoCardTheme {
  const InfoCardTheme({this.textColor, this.gradientColor1, this.gradientColor2});
  final int textColor;
  final int gradientColor1;
  final int gradientColor2;

  Color get getTextColor => Color(textColor);
  LinearGradient get getGradient => LinearGradient(colors: [Color(gradientColor1), Color(gradientColor2)]);

  factory InfoCardTheme.fromDoc(Map<String, dynamic> map) {
    return InfoCardTheme(
        textColor: map['textColor'], gradientColor1: map['gradientColor1'], gradientColor2: map['gradientColor2']);
  }

  Map<String, dynamic> toDoc() {
    return {'textColor': textColor, 'gradientColor1': gradientColor1, 'gradientColor2': gradientColor2};
  }
}
