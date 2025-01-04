import 'package:flutter/material.dart';
import 'view/home_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LeatherShaperApp());
}

class LeatherShaperApp extends StatelessWidget {
  const LeatherShaperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MultiMaskCamera(),
    );
  }
}
