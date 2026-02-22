import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

PreferredSizeWidget buildHubAppBar({
  required BuildContext context,
  required String title,
  List<Widget> actions = const <Widget>[],
}) {
  final canPop = context.canPop();
  return AppBar(
    automaticallyImplyLeading: false,
    leading: IconButton(
      tooltip: canPop ? 'Back' : 'Home',
      icon: Icon(canPop ? Icons.arrow_back : Icons.home_outlined),
      onPressed: () {
        if (canPop) {
          context.pop();
          return;
        }
        context.go('/');
      },
    ),
    title: Text(title),
    actions: actions,
  );
}
