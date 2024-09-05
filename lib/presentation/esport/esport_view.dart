import 'package:flutter/material.dart';

class EsportView extends StatefulWidget {
  const EsportView({Key? key}) : super(key: key);

  @override
  State<EsportView> createState() => _EsportViewState();
}

class _EsportViewState extends State<EsportView>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const Scaffold(
      body: Center(
        child: Text('Esport View'),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
