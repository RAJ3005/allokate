import 'package:allokate/utils/design_utils.dart';
import 'package:flutter/cupertino.dart';

class AccountIcon extends StatelessWidget {
  const AccountIcon({Key key, @required this.color, @required this.image}) : super(key: key);

  final Color color;
  final Image image;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
        aspectRatio: 1,
        child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0), color: color.withOpacity(0.3)),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Stack(
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.matrix(ColorFilterGenerator.brightnessAdjustMatrix(value: 0.3)),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.matrix(ColorFilterGenerator.saturationAdjustMatrix(value: 0.25)),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(color, BlendMode.modulate),
                        child: image,
                      ),
                    ),
                  ),
                  // Opacity(opacity: 0.2,
                  //     child: image),
                ],
              ),
            )));
  }
}
