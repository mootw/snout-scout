import 'dart:convert';

import 'package:app/widgets/datasheet.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:download/download.dart';

class DataSheetFullScreen extends StatefulWidget {
  const DataSheetFullScreen({
    super.key,
    this.title,
    required this.columns,
    required this.rows,
    this.numFixedColumns = 1,
  });

  final int numFixedColumns;

  final String? title;
  final List<List<DataItem>> rows;
  final List<DataItemColumn> columns;

  @override
  State<DataSheetFullScreen> createState() => _DataSheetFullScreenState();
}

//Creates a data-table that can be scrolled horizontally and can export to csv
class _DataSheetFullScreenState extends State<DataSheetFullScreen> {
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
        Expanded(
          child: ScrollConfiguration(
            behavior: MouseInteractableScrollBehavior(),
            child: DataTable2(
              //This is to make the data more compact
              dataRowHeight: 40,
              // the +250 is a workaround https://github.com/maxim-saplin/data_table_2/issues/348
              minWidth: (160 * widget.columns.length) + 250,
              fixedLeftColumns: widget.numFixedColumns,
              fixedTopRows: 1,
              horizontalMargin: 12,
              columnSpacing: 0,
              sortAscending: _sortAscending,
              sortColumnIndex: _currentSortColumn,
              border: const TableBorder(
                horizontalInside: BorderSide(width: 0, color: Colors.white10),
                verticalInside: BorderSide(width: 0, color: Colors.white10),
              ),
              columns: [
                for (final column in widget.columns)
                  DataColumn2(
                    fixedWidth: column.width,
                    label: DefaultTextStyle(
                      maxLines: 3,
                      style: Theme.of(context).textTheme.bodySmall!,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: column.item.displayValue,
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
                              constraints: const BoxConstraints(
                                maxWidth: defaultColumnWidth,
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
