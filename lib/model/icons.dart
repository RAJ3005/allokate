import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class IconList extends ChangeNotifier {
  IconList() {
    init();
  }

  List<IconImageData> list = [];

  init() async {
    var result = await FirebaseStorage.instance.ref('icons').listAll();

    var futureUrls = <Future<String>>[];
    for (var item in result.items) {
      futureUrls.add(item.getDownloadURL());
    }
    var urls = await Future.wait(futureUrls);

    List<Future<IconImageData>> futureImages = [];
    for (String url in urls) {
      futureImages
          .add(http.get(Uri.parse(url)).then((response) => IconImageData(Image.memory(response.bodyBytes), url)));
    }
    list = await Future.wait(futureImages);

    notifyListeners();
  }

  IconImageData getImage(String imageUrl) {
    try {
      return list.firstWhere((data) => data.downloadUrl == imageUrl);
    } catch (e) {
      return null;
    }
  }
}

class IconImageData {
  IconImageData(this.image, this.downloadUrl);

  Image image;
  String downloadUrl;

  /// Use this getter to get the image itself
  Image get getImage => image ?? Image.network(downloadUrl);
}
