import 'dart:convert';
import 'dart:ui';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:download/download.dart';

String noDataText = "";

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

  DataItem.fromText(String? text)
      : displayValue = ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            //Make the text smaller so that long text fits
            //This is more of a hack than best practice
            child: Text(text ?? noDataText)),
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
  const DataSheet({super.key, this.title, required this.columns, required this.rows});

  ///Rows<Columns<DataItem<Comparable>>
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

  @override
  void initState() {
    super.initState();
  }

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
              if(widget.title != null)
                Text('${widget.title}', style: Theme.of(context).textTheme.titleLarge),
              TextButton(
                  onPressed: () async {
                    final stream = Stream.fromIterable(utf8
                        .encode(dataTableToCSV(widget.columns, widget.rows)));
                    download(stream, widget.title != null ? '${widget.title}.csv' : 'table.csv');
                  },
                  child: const Text("Export CSV")),
            ],
          ),
        ),
        ScrollConfiguration(
          behavior: MouseInteractableScrollBehavior(),
          child: SingleChildScrollView(
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
                )
              ),
              columns: [
                for (final column in widget.columns)
                  DataColumn(label: DefaultTextStyle(maxLines: 2, style: Theme.of(context).textTheme.bodySmall!, child: column.displayValue), onSort: updateSort),
              ],
              rows: [
                for (final row in widget.rows)
                  DataRow(cells: [
                    for (final cell in row) DataCell(cell.displayValue, onTap: cell.exportValue.length < 50 ? null : () {
                      //If the cell's export value length (basically the text of whatever the display value is)
                      //we will have an on-tap that will display a dialog with the complete data
                      showDialog(context: context, builder: (context) => AlertDialog(
                        content: cell.displayValue,
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Ok")),
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
        // etc.
      };
}

//Displays a rounded number or No Data if null or NaN
String numDisplay(double? input) {
  if (input == null || input.isNaN) {
    return noDataText;
  }
  return ((input * 10).round() / 10).toString();
}
