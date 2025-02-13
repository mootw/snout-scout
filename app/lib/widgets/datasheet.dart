import 'dart:convert';
import 'dart:ui';

import 'package:app/services/snout_image_cache.dart';
import 'package:app/style.dart';
import 'package:app/widgets/image_view.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:download/download.dart';
import 'package:snout_db/config/surveyitem.dart';

const String noDataText = "";

class DataItem {
  //Helpers to create data items from different types
  DataItem.fromNumber(double? number)
      : displayValue = Text(
            number == null || number.isNaN ? noDataText : numDisplay(number)),
        exportValue =
            number == null || number.isNaN ? noDataText : number.toString(),
        //negative infinity will sort no data to the bottom by default
        sortingValue =
            number == null || number.isNaN ? double.negativeInfinity : number;

  DataItem.fromErrorNumber(({double? value, String? error}) number)
      : displayValue = number.error != null
            ? Text(number.error!, style: const TextStyle(color: warningColor))
            : (Text(number.value == null || number.value!.isNaN
                ? noDataText
                : numDisplay(number.value))),
        //TODO If the error is not passed into the export value the table will not
        //know if the value is long enough to wrap. This is problematic and is
        //a sign of poorly written code.
        exportValue = number.error != null
            ? number.error!
            : (number.value == null || number.value!.isNaN
                ? noDataText
                : number.value.toString()),
        //negative infinity will sort no data to the bottom by default
        sortingValue = number.value == null || number.value!.isNaN
            ? double.negativeInfinity
            : number.value!;

  // This is a builder because why not
  static DataItem fromSurveyItem(int team, dynamic value, SurveyItem survey) {
    switch (survey.type) {
      case SurveyItemType.picture:
        return DataItem(
            displayValue: value == null
                ? const SizedBox()
                : ImageViewer(
                    child: Image(
                    image: snoutImageCache.getCached(value),
                    fit: BoxFit.cover,
                  )),
            exportValue: value == null ? '' : 'Image',
            sortingValue: value == null ? 0 : 1);
      default:
        return DataItem.fromText(value?.toString());
    }
  }

  DataItem.fromText(String? text)
      : displayValue = Text(text ?? noDataText),
        exportValue = text ?? noDataText,
        //Empty string will sort to the bottom by default
        sortingValue = text?.toLowerCase() ?? "";

  const DataItem(
      {required this.displayValue,
      required this.exportValue,
      required this.sortingValue});

  final Widget displayValue; //Widget to be displayed in the app
  final String exportValue; //Used to export to CSV
  final Comparable sortingValue; //Value used to sort the data

  @override
  String toString() => exportValue;
}

class DataSheet extends StatefulWidget {
  const DataSheet(
      {super.key, this.title, required this.columns, required this.rows});

  final String? title;
  final List<List<DataItem>> rows;
  final List<DataItem> columns;

  @override
  State<DataSheet> createState() => _DataSheetState();
}

//Creates a data-table that can be scrolled horizontally and can export to csv
class _DataSheetState extends State<DataSheet> {
  // //This is the sorted data! This way we do not re-calculate sorting every moment

  int? _currentSortColumn;
  bool _sortAscending = true;

  void updateSort(int columnIndex, bool ascending) {
    setState(() {
      _currentSortColumn = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentSortColumn != null) {
      widget.rows.sort((a, b) {
        final aValue = a[_currentSortColumn!].sortingValue;
        final bValue = b[_currentSortColumn!].sortingValue;
        return _sortAscending
            ? Comparable.compare(aValue, bValue)
            : Comparable.compare(bValue, aValue);
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Wrap(
            children: [
              if (widget.title != null)
                Text('${widget.title}',
                    style: Theme.of(context).textTheme.titleLarge),
              TextButton(
                  onPressed: () async {
                    final stream = Stream.fromIterable(utf8
                        .encode(dataTableToCSV(widget.columns, widget.rows)));
                    download(
                        stream,
                        widget.title != null
                            ? '${widget.title}.csv'
                            : 'table.csv');
                  },
                  child: const Text("Export CSV")),
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
              columnSpacing: 12,
              sortAscending: _sortAscending,
              sortColumnIndex: _currentSortColumn,
              border: const TableBorder(
                  verticalInside: BorderSide(
                width: 1,
                color: Colors.white10,
              )),
              //Make the data-table more compact (this basically fits 2 lines perfectly)
              //This is definitely against best practice, but it significantly improves
              //the readability of the table at the cost of touch target size
              dataRowMaxHeight: kMinInteractiveDimension - 8,
              dataRowMinHeight: kMinInteractiveDimension - 8,
              columns: [
                for (final column in widget.columns)
                  DataColumn(
                      label: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          //Make the text smaller so that long text fits
                          //This is more of a hack than best practice
                          child: DefaultTextStyle(
                              maxLines: 2,
                              style: Theme.of(context).textTheme.bodySmall!,
                              child: column.displayValue)),
                      onSort: updateSort),
              ],
              rows: [
                for (final row in widget.rows)
                  DataRow(cells: [
                    for (final cell in row)
                      DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Container(
                              color: cell.exportValue.length < 40
                                  ? null
                                  : Colors.blue.withAlpha(40),
                              child: DefaultTextStyle(
                                  maxLines: 2,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium!,
                                  child: cell.displayValue),
                            ),
                          ),
                          onTap: cell.exportValue.length < 40
                              ? null
                              : () {
                                  //If the cell's export value length (basically the text of whatever the display value is)
                                  //we will have an on-tap that will display a dialog with the complete data
                                  showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                            content: cell.displayValue,
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text("Ok")),
                                            ],
                                          ));
                                })
                  ]),
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
