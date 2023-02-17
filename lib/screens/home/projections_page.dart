// ignore_for_file: implementation_imports
import 'package:allokate/constants/styles.dart';
import 'package:allokate/model/funds.dart';
import 'package:allokate/model/projection_data.dart';
import 'package:allokate/utils/design_utils.dart';
import 'package:allokate/utils/string_utils.dart';
import 'package:allokate/widgets/fund_chart_grid_item.dart';
import 'package:charts_flutter/flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:charts_flutter/src/text_element.dart' as charts_text;
import 'package:charts_flutter/src/text_style.dart' as style;
import 'dart:math';
import 'package:charts_common/common.dart' as common show Color;

enum DataTimeScale { short, medium, long }
String labelForTimeScale(DataTimeScale timeScale) {
  switch (timeScale) {
    case DataTimeScale.short:
      return '3 months';
    case DataTimeScale.medium:
      return '6 months';
    case DataTimeScale.long:
      return '1 year';
    default:
      return '';
  }
}

int monthsForTimeScale(DataTimeScale timeScale) {
  switch (timeScale) {
    case DataTimeScale.short:
      return 3;
    case DataTimeScale.medium:
      return 6;
    case DataTimeScale.long:
      return 12;
    default:
      return 1;
  }
}

class ProjectionsPage extends StatefulWidget {
  const ProjectionsPage({Key key}) : super(key: key);

  @override
  _ProjectionsPageState createState() => _ProjectionsPageState();
}

class _ProjectionsPageState extends State<ProjectionsPage> {
  DataTimeScale timeScale = DataTimeScale.medium;
  String _selectedPointDescription = '';

  @override
  Widget build(BuildContext context) {
    var overallChart = SizedBox(height: 200, child: _buildOverallChart(context));

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: kMainColor,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  image: DecorationImage(image: AssetImage('assets/wave_background.png'), fit: BoxFit.cover),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Projections',
                      style: DesignUtils.defaultStyle(fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    _buildChips(context),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Overall',
                          style:
                              DesignUtils.defaultStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _selectedPointDescription,
                          style:
                              DesignUtils.defaultStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    overallChart,
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Provider.of<FundList>(context).getFundIds.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                        child: Text(
                          'Add funds on the home page and track how they evolve over time here',
                          style: DesignUtils.defaultStyle(fontSize: 17, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Column(
                        children: [
                          _buildGrid(context),
                        ],
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallChart(BuildContext context) {
    var data = Provider.of<ProjectionData>(context);
    return FutureBuilder<List<BalanceHistory>>(
        future: data.getBalanceHistory,
        builder: (context, snapshot) {
          if (snapshot.hasError || !snapshot.hasData) {
            return const SizedBox.shrink();
          }
          var seriesData = snapshot.data
              .map((e) => TimeSeriesBalance(DateTime.fromMillisecondsSinceEpoch(e.timestamp), e.balance))
              .toList();

          seriesData.sort((a, b) => a.date.compareTo(b.date));

          seriesData.add(TimeSeriesBalance(DateTime.now(), Provider.of<FundList>(context).totalAmount));

          for (var i = 1; i <= monthsForTimeScale(timeScale); i++) {
            var averageIncrease = snapshot.data
                .fold(0, (previousValue, element) => (previousValue + element.balance) / snapshot.data.length);

            seriesData.add(
              TimeSeriesBalance(
                DateTime.now().add(Duration(days: 30 * i)),
                Provider.of<FundList>(context).totalAmount + (averageIncrease * i),
              ),
            );
          }

          var seriesList = [
            charts.Series<TimeSeriesBalance, DateTime>(
              id: 'Overall',
              colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
              domainFn: (TimeSeriesBalance sales, _) => sales.date,
              measureFn: (TimeSeriesBalance sales, _) => sales.balance,
              data: seriesData,
            ),
          ];

          return charts.TimeSeriesChart(
            seriesList,
            animate: false,
            behaviors: [
              LinePointHighlighter(
                symbolRenderer: CustomCircleSymbolRenderer(common.Color.white), // add this line in behaviours
              ),
              charts.SelectNearest(eventTrigger: charts.SelectionTrigger.pressHold),
            ],
            selectionModels: [
              SelectionModelConfig(
                  changedListener: (SelectionModel model) {
                    if (!model.hasDatumSelection || !model.hasSeriesSelection) {
                      setState(() {
                        _selectedPointDescription = '';
                      });
                      return;
                    }
                    if (model.hasDatumSelection && model.hasAnySelection) {
                      final value = model.selectedSeries[0].measureFn(model.selectedDatum[0].index);
                      TimeSeriesBalance a = model.selectedDatum[0].datum;
                      DateFormat dateFormat = DateFormat.yMMM();
                      setState(() {
                        _selectedPointDescription =
                            '${dateFormat.format(a.date)}, ${StringUtils.formatMoney(value.toString(), decimalPlaces: 0)}';
                      });
                    }
                  },
                  type: SelectionModelType.info)
            ],
            defaultRenderer: charts.LineRendererConfig(
              includePoints: true,
            ),
            customSeriesRenderers: [charts.PointRendererConfig(customRendererId: 'Overall')],
            dateTimeFactory: const charts.LocalDateTimeFactory(),
            domainAxis: const charts.DateTimeAxisSpec(
              renderSpec: charts.SmallTickRendererSpec(
                  labelRotation: 60,
                  // Tick and Label styling here.
                  labelStyle: charts.TextStyleSpec(
                      fontSize: 12, // size in Pts.
                      color: charts.MaterialPalette.white),

                  // Change the line colors to match text color.
                  lineStyle: charts.LineStyleSpec(color: charts.MaterialPalette.black)),
              tickFormatterSpec: charts.AutoDateTimeTickFormatterSpec(
                month: charts.TimeFormatterSpec(format: DateFormat.ABBR_MONTH, transitionFormat: DateFormat.ABBR_MONTH),
              ),
              tickProviderSpec: charts.DayTickProviderSpec(increments: [28]),
            ),
            primaryMeasureAxis: charts.NumericAxisSpec(
              tickFormatterSpec: charts.BasicNumericTickFormatterSpec.fromNumberFormat(
                  NumberFormat.compactSimpleCurrency(locale: 'en_gb')),
              tickProviderSpec: const charts.BasicNumericTickProviderSpec(
                desiredTickCount: 5,
              ),
              renderSpec: const charts.GridlineRendererSpec(
                lineStyle: charts.LineStyleSpec(
                  dashPattern: [4, 4],
                ),
                labelStyle: charts.TextStyleSpec(
                    fontSize: 12, // size in Pts.
                    color: charts.MaterialPalette.white),
              ),
            ),
          );
        });
  }

  _buildChips(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: DataTimeScale.values.map((t) {
        bool isSelected = timeScale == t;
        return Expanded(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 20),
          child: GestureDetector(
            onTap: () {
              setState(() {
                timeScale = t;
              });
            },
            child: Chip(
                backgroundColor: isSelected ? Colors.blue : Colors.white,
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      labelForTimeScale(t),
                      style: DesignUtils.defaultStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 14),
                    )
                  ],
                )),
          ),
        ));
      }).toList(),
    );
  }

  _buildGrid(BuildContext context) {
    var fundList = Provider.of<FundList>(context);

    return GridView.count(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        children: List.generate(fundList.length, (i) {
          var fund = fundList.getFund(i);
          var fundId = fundList.getFundId(i);
          return FundChartGridItem(fundId: fundId, fund: fund, timeScale: timeScale);
        }));
  }
}

class TimeSeriesBalance {
  final DateTime date;
  final double balance;

  TimeSeriesBalance(this.date, this.balance);

  @override
  String toString() {
    return 'TimeSeriesBalance{date: $date, balance: $balance}';
  }
}

class CustomCircleSymbolRenderer extends CircleSymbolRenderer {
  final common.Color textColor;
  static String value;

  CustomCircleSymbolRenderer(this.textColor);
  @override
  void paint(ChartCanvas canvas, Rectangle<num> bounds,
      {List<int> dashPattern, Color fillColor, FillPatternType fillPattern, Color strokeColor, double strokeWidthPx}) {
    super.paint(canvas, bounds,
        dashPattern: dashPattern,
        fillColor: fillColor,
        fillPattern: fillPattern,
        strokeColor: strokeColor,
        strokeWidthPx: strokeWidthPx);
    // canvas.drawRect(Rectangle(bounds.left - 5, bounds.top - 30, bounds.width + 75, bounds.height + 10),
    //     fill: Color.white);
    var textStyle = style.TextStyle();
    textStyle.color = textColor;
    textStyle.fontSize = 15;
    canvas.drawText(charts_text.TextElement(value, style: textStyle), (bounds.left).round(), (bounds.top - 28).round());
  }
}
