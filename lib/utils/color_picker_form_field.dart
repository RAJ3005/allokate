import 'package:allokate/utils/validators.dart';
import 'package:flutter/material.dart';

class ColorPickerFormField extends FormField<int> {
  static const double iconPadding = 12.0;

  final List<Color> list;
  final double iconSize;

  ColorPickerFormField(
      {Key key, @required this.list, this.iconSize = 40.0, FormFieldSetter<int> onSaved, int initialValue = 0})
      : super(
            key: key,
            onSaved: onSaved,
            validator: Validators.defaultListValidator,
            initialValue: initialValue,
            builder: (FormFieldState<int> state) {
              return SizedBox(
                height: iconSize + 2 * iconPadding,
                child: ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      return GestureDetector(
                        onTap: () {
                          state.didChange(i);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(iconPadding),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: iconSize,
                                width: iconSize,
                                color: list[i],
                              ),
                              if (i == state.value)
                                const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
                                )
                            ],
                          ),
                        ),
                      );
                    }),
              );
            });
}
