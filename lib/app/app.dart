import 'package:material_ui/material_ui.dart';

import '../features/notes/note_list_screen.dart';

class PrivateMemoApp extends StatelessWidget {
  const PrivateMemoApp({super.key});

  static const _seed = Color(0xFFE0A800); // 메모 앱 느낌의 노란색 포인트

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '프라이빗 메모',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const NoteListScreen(),
    );
  }
}
