import 'package:flutter/material.dart';

class ConfirmExitDialog extends StatelessWidget {
  final Widget child;

  const ConfirmExitDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          return (await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Are you sure?'),
                  content: Text('Leave without saving'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Yes'),
                    ),
                  ],
                ),
              )) ??
              false;
        },
        child: child);
  }
}
