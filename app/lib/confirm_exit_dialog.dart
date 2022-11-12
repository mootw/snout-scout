import 'package:flutter/material.dart';


///Wrapping a widget with this will prompt for a confirm if
///the scope is popped. This should be used for edit menus
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
                  title: const Text('Are you sure?'),
                  content: const Text('Leave without saving'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              )) ??
              false;
        },
        child: child);
  }
}
