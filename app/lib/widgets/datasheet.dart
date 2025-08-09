import 'dart:convert';
import 'dart:ui';

import 'package:app/screens/match_page.dart';
import 'package:app/services/snout_image_cache.dart';
import 'package:app/style.dart';
import 'package:app/widgets/image_view.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:download/download.dart';
import 'package:snout_db/config/surveyitem.dart';

const String noDataText = '';

class DataItem {
  //Helpers to create data items from different types
  DataItem.fromNumber(double? number)
    : displayValue = Text(
        number == null || number.isNaN ? noDataText : numDisplay(number),
      ),
      exportValue =
          number == null || number.isNaN ? noDataText : number.toString(),
      //negative infinity will sort no data to the bottom by default
      sortingValue =
          number == null || number.isNaN ? double.negativeInfinity : number,
      numericValue = number;

  DataItem.fromErrorNumber(({double? value, String? error}) number)
    : displayValue =
          number.error != null
              ? Text(number.error!, style: const TextStyle(color: warningColor))
              : (Text(
                number.value == null || number.value!.isNaN
                    ? noDataText
                    : numDisplay(number.value),
              )),
      //TODO If the error is not passed into the export value the table will not
      //know if the value is long enough to wrap. This is problematic and is
      //a sign of poorly written code.
      exportValue =
          number.error != null
              ? number.error!
              : (number.value == null || number.value!.isNaN
                  ? noDataText
                  : number.value.toString()),
      //negative infinity will sort no data to the bottom by default
      sortingValue =
          number.value == null || number.value!.isNaN
              ? double.negativeInfinity
              : number.value!,
      numericValue =
          number.value == null || number.value!.isNaN ? null : number.value!;

  // This is a builder because why not
  static DataItem fromSurveyItem(dynamic value, SurveyItem survey) {
    switch (survey.type) {
      case SurveyItemType.picture:
        return DataItem(
          displayValue:
              value == null
                  ? const SizedBox()
                  : ImageViewer(
                    child: Image(
                      image: snoutImageCache.getCached(value),
                      fit: BoxFit.cover,
                    ),
                  ),
          exportValue: value == null ? noDataText : 'Image',
          sortingValue: value == null ? 0 : 1,
        );
      case SurveyItemType.toggle:
        return DataItem(
          displayValue: value == null ? SizedBox() : Text(value.toString()),
          exportValue: value?.toString() ?? noDataText,
          sortingValue: switch (value as bool?) {
            null => -1,
            false => 0,
            true => 1,
          },
        );
      default:
        return DataItem.fromText(value?.toString());
    }
  }

  DataItem.fromText(String? text)
    : displayValue = Text(text ?? noDataText),
      exportValue = text ?? noDataText,
      //Empty string will sort to the bottom by default
      sortingValue = text?.toLowerCase() ?? "",
      numericValue = null;

  DataItem.match({
    required BuildContext context,
    required String key,
    required String label,
    Color? color,
    DateTime? time,
  }) : displayValue = TextButton(
         child: Text(label, style: TextStyle(color: color)),
         onPressed:
             () => Navigator.push(
               context,
               MaterialPageRoute(builder: (context) => MatchPage(matchid: key)),
             ),
       ),
       exportValue = label,
       sortingValue = time ?? DateTime(2000),
       numericValue = null;

  const DataItem({
    required this.displayValue,
    required this.exportValue,
    required this.sortingValue,
    this.numericValue,
  });

  final Widget displayValue; //Widget to be displayed in the app
  final String exportValue; //Used to export to CSV
  final Comparable sortingValue; //Value used to sort the data
  final double? numericValue;

  @override
  String toString() => exportValue;
}

class DataItemColumn {
  DataItem item;
  bool largerIsBetter;
  double width;

  DataItemColumn(
    this.item, {
    this.largerIsBetter = true,
    this.width = defaultColumnWidth,
  });

  factory DataItemColumn.fromSurveyItem(SurveyItem item) {
    return DataItemColumn(
      DataItem.fromText(item.label),
      largerIsBetter: true,
      width: switch (item.type) {
        SurveyItemType.number => numericWidth,
        SurveyItemType.picture => numericWidth,
        SurveyItemType.toggle => numericWidth,
        _ => defaultColumnWidth,
      },
    );
  }

  @override
  String toString() =>
      'DataItemWithHints(label:${item.exportValue} largerIsBetter: $largerIsBetter)';
}

class DataSheet extends StatefulWidget {
  const DataSheet({
    super.key,
    this.title,
    required this.columns,
    required this.rows,
  });

  final String? title;
  final List<List<DataItem>> rows;
  final List<DataItemColumn> columns;

  @override
  State<DataSheet> createState() => _DataSheetState();
}

Color rainbowColor(double min, double max, double value) {
  return HSVColor.lerp(
    HSVColor.fromColor(Colors.red),
    HSVColor.fromColor(Colors.green),
    (value - min) / (max - min),
  )!.withAlpha(0.7).toColor();
}

// Used for numbers
const double numericWidth = 80;
// Default, usually used for text
const double defaultColumnWidth = 160;

//Creates a data-table that can be scrolled horizontally and can export to csv
class _DataSheetState extends State<DataSheet> {
  // //This is the sorted data! This way we do not re-calculate sorting every moment

  int? _currentSortColumn;
  bool _sortAscending = true;

  bool _showRainbow = true;

  void updateSort(int columnIndex, bool ascending) {
    setState(() {
      _currentSortColumn = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      widget.rows.add([
        ...List.generate(
          widget.columns.length,
          (_) => DataItem.fromText("EMPTY"),
        ),
      ]);
    }
    if (_currentSortColumn != null) {
      widget.rows.sort((a, b) {
        final aValue = a[_currentSortColumn!].sortingValue;
        final bValue = b[_currentSortColumn!].sortingValue;
        return _sortAscending
            ? aValue.compareTo(bValue)
            : bValue.compareTo(aValue);
      });
    }

    // Calculate minMaxes
    int numRows = widget.rows.length;
    int numColumns = numRows == 0 ? 0 : widget.rows[0].length;

    final numericMinMaxes = List<(double, double)?>.filled(numColumns, null);

    if (widget.rows.isNotEmpty) {
      for (int columnIdx = 0; columnIdx < numColumns; columnIdx++) {
        double? min;
        double? max;

        for (int rowIdx = 0; rowIdx < numRows; rowIdx++) {
          // Go through each row in the column to calculate the min and max
          final numeric = widget.rows[rowIdx][columnIdx].numericValue;

          if (numeric != null) {
            min ??= numeric;
            max ??= numeric;

            if (numeric < min) {
              min = numeric;
            }
            if (numeric > max) {
              max = numeric;
            }
          }
        }

        if ((min != null && max != null) && (max - min != 0)) {
          numericMinMaxes[columnIdx] = (min, max);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Wrap(
            children: [
              if (widget.title != null)
                Text(
                  '${widget.title}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              SizedBox(width: 32),
              Checkbox(
                value: _showRainbow,
                onChanged:
                    (newValue) => setState(() {
                      _showRainbow = newValue!;
                    }),
              ),
              Text("Rainbow"),
              SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  final stream = Stream.fromIterable(
                    utf8.encode(
                      dataTableToCSV(
                        widget.columns.map((e) => e.item).toList(),
                        widget.rows,
                      ),
                    ),
                  );
                  download(
                    stream,
                    widget.title != null ? '${widget.title}.csv' : 'table.csv',
                  );
                },
                child: const Text("Export CSV"),
              ),
            ],
          ),
        ),
        ScrollConfiguration(
          behavior: MouseInteractableScrollBehavior(),
          child: SingleChildScrollView(
            clipBehavior:
                Clip.none, //Maybe this improves the scrolling performance???
            scrollDirection: Axis.horizontal,
            child: DataTable(
              //This is to make the data more compact
              columnSpacing: 0,
              //Make the data-table more compact (this basically fits 2 lines perfectly)
              //This is definitely against best practice, but it significantly improves
              //the readability of the table at the cost of touch target size
              dataRowMaxHeight: 40,
              dataRowMinHeight: 40,
              sortAscending: _sortAscending,
              sortColumnIndex: _currentSortColumn,
              border: const TableBorder(
                horizontalInside: BorderSide(width: 0, color: Colors.white10),
                verticalInside: BorderSide(width: 0, color: Colors.white10),
              ),
              columns: [
                for (final column in widget.columns)
                  DataColumn(
                    label: ConstrainedBox(
                      // -16 for the sorting arrow
                      constraints: BoxConstraints(maxWidth: column.width - 16),
                      //Make the text smaller so that long text fits
                      //This is more of a hack than best practice
                      child: DefaultTextStyle(
                        maxLines: 3,
                        style: Theme.of(context).textTheme.bodySmall!,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: column.item.displayValue,
                        ),
                      ),
                    ),
                    onSort: updateSort,
                  ),
              ],
              rows: [
                for (final row in widget.rows)
                  DataRow(
                    cells: [
                      for (final (columnIdx, cell) in row.indexed)
                        DataCell(
                          SizedBox.expand(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: widget.columns[columnIdx].width,
                              ),
                              child: Container(
                                padding: EdgeInsets.only(left: 4, right: 4),
                                color: () {
                                  if (cell.exportValue == "true") {
                                    return Colors.green;
                                  }
                                  if (cell.exportValue == "false") {
                                    return Colors.red;
                                  }

                                  if (_showRainbow &&
                                      cell.numericValue != null &&
                                      numericMinMaxes[columnIdx] != null) {
                                    double min = numericMinMaxes[columnIdx]!.$1;
                                    double max = numericMinMaxes[columnIdx]!.$2;

                                    return widget
                                            .columns[columnIdx]
                                            .largerIsBetter
                                        ? rainbowColor(
                                          min,
                                          max,
                                          cell.numericValue!,
                                        )
                                        : rainbowColor(
                                          max,
                                          min,
                                          cell.numericValue!,
                                        );
                                  }

                                  return cell.exportValue.length < 40
                                      ? null
                                      : Colors.blue.withAlpha(40);
                                }(),
                                child: DefaultTextStyle(
                                  maxLines: 2,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium!,
                                  child: Align(
                                    alignment:
                                        cell.numericValue != null
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                    child: cell.displayValue,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          onTap:
                              cell.exportValue.length < 40
                                  ? null
                                  : () {
                                    //If the cell's export value length (basically the text of whatever the display value is)
                                    //we will have an on-tap that will display a dialog with the complete data
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            content: cell.displayValue,
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: const Text("Ok"),
                                              ),
                                            ],
                                          ),
                                    );
                                  },
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String dataTableToCSV(List<DataItem> columns, List<List<DataItem>> rows) {
  //Append the colums to the top of the rows
  List<List<DataItem>> combined = [columns, ...rows];
  return const ListToCsvConverter().convert(combined);
}

class MouseInteractableScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

/// Displays a rounded number to tenths place or No Data if null or NaN
String numDisplay(double? input) {
  if (input == null || input.isNaN) {
    return noDataText;
  }
  return ((input * 10).round() / 10).toString();
}
