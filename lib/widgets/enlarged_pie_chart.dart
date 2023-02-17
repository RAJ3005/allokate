import 'package:allokate/constants/styles.dart';
import 'package:flutter/material.dart';

class EnlargedChart extends StatefulWidget {
  const EnlargedChart({Key key, @required this.chart, this.onWillPop}) : super(key: key);

  final Widget chart;
  final VoidCallback onWillPop;

  @override
  _EnlargedChartState createState() => _EnlargedChartState();
}

class _EnlargedChartState extends State<EnlargedChart> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: kMainColor,
          child: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onWillPop != null) widget.onWillPop.call();
            Navigator.of(context).pop();
          },
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: widget.chart,
            ),
          ),
        ),
      ),
    );
  }
}
