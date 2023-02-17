import 'package:allokate/model/funds.dart';
import 'package:allokate/model/projection_data.dart';
import 'package:allokate/screens/home/projections_page.dart';
import 'package:allokate/utils/design_utils.dart';
import 'package:allokate/utils/string_utils.dart';
import 'package:charts_flutter/flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:charts_common/common.dart' as common show Color;

class FundChartGridItem extends StatefulWidget {
  final Fund fund;
  final String fundId;
  final DataTimeScale timeScale;

  const FundChartGridItem({Key key, @required this.fund, @required this.fundId, @required this.timeScale})
      : super(key: key);

  @override
  _FundChartGridItemState createState() => _FundChartGridItemState();
}

class _FundChartGridItemState extends State<FundChartGridItem> {
  String _selectedPointDescription = '';

  @override
  Widget build(BuildContext context) {
    Widget _buildFundChart(BuildContext context, Fund fund, String fundId) {
      var data = Provider.of<ProjectionData>(context);

      return FutureBuilder<List<BalanceHistory>>(
          future: data.getFundBalanceHistory(fundId),
          builder: (context, snapshot) {
            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox.shrink();
            }
            var seriesData = snapshot.data
                .map((e) => TimeSeriesBalance(DateTime.fromMillisecondsSinceEpoch(e.timestamp), e.balance))
                .toList();

            seriesData.sort((a, b) => a.date.compareTo(b.date));

            seriesData.add(TimeSeriesBalance(DateTime.now(), Provider.of<FundList>(context).totalAmount));

            for (var i = 1; i <= monthsForTimeScale(widget.timeScale); i++) {
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
                id: fundId,
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
                LinePointHighlighter(symbolRenderer: CustomCircleSymbolRenderer(common.Color.black) // add this line in
                    // behaviours
                    ),
                charts.SelectNearest(eventTrigger: charts.SelectionTrigger.tapAndDrag),
              ],
              selectionModels: [
                SelectionModelConfig(changedListener: (SelectionModel model) {
                  if (!model.hasDatumSelection || !model.hasSeriesSelection) {
                    setState(() {
                      _selectedPointDescription = '';
                    });
                    return;
                  }
                  if (model.hasDatumSelection) {
                    final value = model.selectedSeries[0].measureFn(model.selectedDatum[0].index);
                    TimeSeriesBalance a = model.selectedDatum[0].datum;
                    DateFormat dateFormat = DateFormat.yMMM();
                    setState(() {
                      _selectedPointDescription =
                          '${dateFormat.format(a.date)}, ${StringUtils.formatMoney(value.toString(), decimalPlaces: 0)}';
                    });
                  }
                })
              ],
              defaultRenderer: charts.LineRendererConfig(
                includePoints: true,
              ),
              customSeriesRenderers: [charts.PointRendererConfig(customRendererId: fundId)],
              domainAxis: const charts.DateTimeAxisSpec(
                renderSpec: charts.SmallTickRendererSpec(
                    labelRotation: 60,
                    // Tick and Label styling here.
                    labelStyle: charts.TextStyleSpec(
                        fontSize: 10, // size in Pts.
                        color: charts.MaterialPalette.black),

                    // Change the line colors to match text color.
                    lineStyle: charts.LineStyleSpec(color: charts.MaterialPalette.black)),
                tickFormatterSpec: charts.AutoDateTimeTickFormatterSpec(
                  month:
                      charts.TimeFormatterSpec(format: DateFormat.ABBR_MONTH, transitionFormat: DateFormat.ABBR_MONTH),
                ),
                tickProviderSpec: charts.DayTickProviderSpec(increments: [90]),
              ),
              primaryMeasureAxis: charts.NumericAxisSpec(
                tickFormatterSpec: charts.BasicNumericTickFormatterSpec.fromNumberFormat(
                    NumberFormat.compactSimpleCurrency(locale: 'en_gb')),
                tickProviderSpec: const charts.BasicNumericTickProviderSpec(
                  desiredTickCount: 2,
                ),
                renderSpec: const charts.GridlineRendererSpec(
                  lineStyle: charts.LineStyleSpec(
                    dashPattern: [4, 4],
                  ),
                  labelStyle: charts.TextStyleSpec(
                      fontSize: 10, // size in Pts.
                      color: charts.MaterialPalette.black),
                ),
              ),
            );
          });
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration:
            BoxDecoration(color: widget.fund.getColor.withOpacity(0.3), borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.fund.name, style: DesignUtils.defaultStyle(fontWeight: FontWeight.bold)),
              const SizedBox(
                height: 5,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('£' + widget.fund.amount.toStringAsFixed(0), style: DesignUtils.defaultStyle(fontSize: 14)),
                  Text(_selectedPointDescription, style: DesignUtils.defaultStyle(fontSize: 10)),
                ],
              ),
              Expanded(
                child: _buildFundChart(context, widget.fund, widget.fundId),
              ),
              Text('${((widget.fund.amount / Provider.of<FundList>(context).totalAmount) * 100).round()}%',
                  style: DesignUtils.defaultStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
