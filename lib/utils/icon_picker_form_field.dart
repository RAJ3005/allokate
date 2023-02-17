import 'package:allokate/model/icons.dart';
import 'package:allokate/utils/validators.dart';
import 'package:flutter/material.dart';

class IconPickerFormField extends FormField<int> {
  final List<IconImageData> list;
  final double iconSize;

  IconPickerFormField(
      {Key key, @required this.list, this.iconSize = 20.0, FormFieldSetter<int> onSaved, int initialValue})
      : super(
            key: key,
            onSaved: onSaved,
            validator: Validators.defaultListValidator,
            initialValue: initialValue,
            builder: (FormFieldState<int> state) {
              return GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 5,
                children: list.map((data) {
                  int i = list.indexOf(data);
                  return Container(
                    decoration: state.value != i
                        ? null
                        : BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(width: 2, color: Colors.blue.withOpacity(0.6))),
                    child: GestureDetector(
                      onTap: () {
                        state.didChange(i);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SizedBox(height: iconSize, width: iconSize, child: data.getImage),
                      ),
                    ),
                  );
                }).toList(),
              );
            });
}
