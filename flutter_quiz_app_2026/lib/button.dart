import 'package:flutter/material.dart';

class OutlinedButtonExample extends StatefulWidget {
  const OutlinedButtonExample(this.text, this.action, this.selectedIcon, {super.key});
  
  final void Function() action;
  final String text;
  final Icon selectedIcon;

  @override
  State<OutlinedButtonExample> createState() => _OutlinedButtonExampleState();
}

class _OutlinedButtonExampleState extends State<OutlinedButtonExample> {
  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = OutlinedButton.styleFrom(
        textStyle: const TextStyle(fontSize: 17),
        shape: const BeveledRectangleBorder(),
        side: const BorderSide(width: 0.1, color: Color.fromARGB(255, 197, 197, 197)),
        foregroundColor: Colors.white);

    return Center(
      child: Column(
        children: <Widget>[
          OutlinedButton.icon(
            style: style,
            onPressed: widget.action,
            label: Text(widget.text),
            icon: widget.selectedIcon,
          ),
        ],
      ),
    );
  }
}
