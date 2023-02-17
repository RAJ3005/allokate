import 'package:allokate/model/funds.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryOptions extends StatefulWidget {
  final List<FundCategory> fundCategory;
  final List<String> categoriesValues;

  const CategoryOptions({Key key, this.fundCategory, this.categoriesValues}) : super(key: key);

  @override
  _CategoryOptionsState createState() => _CategoryOptionsState();
}

class _CategoryOptionsState extends State<CategoryOptions> {
  @override
  Widget build(BuildContext context) {
    Widget appBar = AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Colors.black,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar,
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView.separated(
          separatorBuilder: (BuildContext context, int index) => const Divider(),
          itemCount: widget.fundCategory.length,
          itemBuilder: (context, index) {
            String options = widget.categoriesValues[index];
            return ListTile(
              onTap: () {
                Navigator.of(context).pop(index);
              },
              title: Text(
                options ?? '',
                style: GoogleFonts.roboto(color: Colors.black, fontSize: 17),
              ),
            );
          },
        ),
      ),
    );
  }
}
