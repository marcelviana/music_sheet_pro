import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class Music {
  final String id;
  final String title;
  final String artist;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  Music({
    required this.id,
    required this.title,
    required this.artist,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.isFavorite,
  });
}

abstract class MusicRepository {
  Future<List<Music>> getAllMusics();
  Future<Music?> getMusicById(String id);
}

class FakeMusicRepositoryWithOneItem implements MusicRepository {
  @override
  Future<List<Music>> getAllMusics() async {
    return [
      Music(
        id: 'test-id',
        title: 'Test Song',
        artist: 'Test Artist',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
      ),
    ];
  }

  @override
  Future<Music?> getMusicById(String id) async =>
      getAllMusics().then((list) => list.first);
}

class TestApp extends StatelessWidget {
  final MusicRepository musicRepository;

  const TestApp({super.key, required this.musicRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Library')),
        body: FutureBuilder<List<Music>>(
          future: musicRepository.getAllMusics(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final musics = snapshot.data!;
            return ListView.builder(
              itemCount: musics.length,
              itemBuilder: (_, index) => ListTile(
                title: Text(musics[index].title),
                onTap: () => Navigator.pushNamed(context, '/viewer'),
              ),
            );
          },
        ),
      ),
      routes: {
        '/viewer': (context) => Scaffold(
              appBar: AppBar(title: Text('Viewer')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/pdf'),
                  child: Text('Open PDF'),
                ),
              ),
            ),
        '/pdf': (context) => Scaffold(
              appBar: AppBar(title: Text('PDF Viewer')),
              body: Center(child: Text('PDF is shown here')),
            ),
      },
    );
  }
}

void main() {
  testWidgets('no Hero tag conflict during navigation',
      (WidgetTester tester) async {
    final errors = <FlutterErrorDetails>[];

    FlutterError.onError = (FlutterErrorDetails details) {
      errors.add(details);
      FlutterError.dumpErrorToConsole(details);
    };

    await tester.pumpWidget(TestApp(
      musicRepository: FakeMusicRepositoryWithOneItem(),
    ));
    await tester.pumpAndSettle();

    final heroErrorsBefore = errors
        .where((e) => e
            .exceptionAsString()
            .contains('multiple heroes that share the same tag'))
        .toList();
    expect(heroErrorsBefore, isEmpty,
        reason:
            'There should be no Hero tag duplication errors before navigation.');

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    final heroErrorsAfter = errors
        .where((e) => e
            .exceptionAsString()
            .contains('multiple heroes that share the same tag'))
        .toList();
    expect(heroErrorsAfter, isEmpty,
        reason:
            'There should be no Hero tag duplication errors after navigation.');

    // Tap the "Open PDF" button to navigate to /pdf.
    await tester.tap(find.text('Open PDF'));
    await tester.pumpAndSettle();

    final heroErrorsFinal = errors
        .where((e) => e
            .exceptionAsString()
            .contains('multiple heroes that share the same tag'))
        .toList();
    expect(heroErrorsFinal, isEmpty,
        reason:
            'There should be no Hero tag duplication errors after navigating to PDF screen.');
  });
}
