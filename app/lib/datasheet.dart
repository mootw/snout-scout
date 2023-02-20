import 'dart:ui';

import 'package:flutter/material.dart';

class DataItem {
  //Helpers to create data items from different types
  DataItem.fromNumber(double? number)
      : displayValue = Text(number == null || number.isNaN ? "No Data" : numDisplay(number)),
        exportValue = number == null || number.isNaN ? "No Data" : numDisplay(number),
        sortingValue = number == null || number.isNaN ? 0 : number;

  DataItem.fromText(String text)
      : displayValue = ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(text)),
        exportValue = text,
        sortingValue = text.toLowerCase();

  DataItem(
      {required this.displayValue,
      required this.exportValue,
      required this.sortingValue});

  Widget displayValue; //Widget to be displayed in the app
  String exportValue; //Used to export to CSV
  Comparable sortingValue; //Value used to sort the data

  @override
  String toString() => exportValue;
}

class DataSheet extends StatefulWidget {
  const DataSheet({super.key, required this.columns, required this.rows});

  ///Rows<Columns<DataItem<Comparable>>
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
    if(_currentSortColumn != null) {
        widget.rows.sort((a, b) {
        final aValue = a[_currentSortColumn!].sortingValue;
        final bValue = b[_currentSortColumn!].sortingValue;
        return _sortAscending
            ? Comparable.compare(aValue, bValue)
            : Comparable.compare(bValue, aValue);
      });
    }
    return ScrollConfiguration(
      behavior: MouseInteractableScrollBehavior(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          //This is to make the data more compact
          columnSpacing: 24,
          sortAscending: _sortAscending,
          sortColumnIndex: _currentSortColumn,
          columns: [
            for (final column in widget.columns)
              DataColumn(label: column.displayValue, onSort: updateSort),
          ],
          rows: [
            for (final row in widget.rows)
              DataRow(
                  cells: [for (final cell in row) DataCell(cell.displayValue)]),
          ],
        ),
      ),
    );
  }
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
    return "No Data";
  }
  return ((input * 10).round() / 10).toString();
}