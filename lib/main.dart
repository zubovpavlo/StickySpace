import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

const double boardWidth = 1800;
const double boardHeight = 1250;
const double noteWidth = 232;
const double noteHeight = 210;

const Map<String, Color> paperColors = {
  'yellow': Color(0xFFFFF0A5),
  'pink': Color(0xFFFFC9D5),
  'blue': Color(0xFFC9E9FF),
  'mint': Color(0xFFD1F4D6),
  'lilac': Color(0xFFE6D8FF),
  'white': Color(0xFFFFFDF5),
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
  runApp(const StickySpaceApp());
}

class StickySpaceApp extends StatelessWidget {
  const StickySpaceApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'StickySpace',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF425D76)),
          scaffoldBackgroundColor: const Color(0xFFF3F1EA),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
        home: supabaseUrl.isEmpty || supabaseAnonKey.isEmpty
            ? const SetupPage()
            : const AuthGate(),
      );
}

class SetupPage extends StatelessWidget {
  const SetupPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.sticky_note_2_outlined, size: 54),
                  SizedBox(height: 18),
                  Text('StickySpace',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text('Щоб увімкнути синхронізацію, запусти застосунок із параметрами SUPABASE_URL та SUPABASE_ANON_KEY. Інструкція є у README.md.'),
                ],
              ),
            ),
          ),
        ),
      );
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late User? user;
  late StreamSubscription<AuthState> sub;

  @override
  void initState() {
    super.initState();
    final auth = Supabase.instance.client.auth;
    user = auth.currentUser;
    sub = auth.onAuthStateChange.listen((state) {
      if (mounted) setState(() => user = state.session?.user);
    });
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => user == null
      ? const LoginPage()
      : NotesPage(key: ValueKey(user!.id), userId: user!.id);
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool registering = false;
  String? error;
  String? info;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() { loading = true; error = null; info = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (registering) {
        final result = await auth.signUp(
          email: email.text.trim(), password: password.text,
        );
        if (result.session == null && mounted) {
          setState(() => info = 'Перевір пошту й підтвердь реєстрацію, тоді увійди.');
        }
      } else {
        await auth.signInWithPassword(
          email: email.text.trim(), password: password.text,
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) setState(() => error = 'Не вдалося підключитися: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 410),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.sticky_note_2_outlined, size: 60),
                    const SizedBox(height: 12),
                    const Text('StickySpace', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(registering ? 'Створити особистий акаунт' : 'Твої нотатки на всіх пристроях',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 26),
                    TextField(controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Електронна пошта')),
                    const SizedBox(height: 12),
                    TextField(controller: password, obscureText: true,
                        onSubmitted: (_) => submit(),
                        decoration: const InputDecoration(labelText: 'Пароль (мінімум 6 символів)')),
                    if (error != null) Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(error!, style: const TextStyle(color: Colors.red))),
                    if (info != null) Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(info!)),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: loading ? null : submit,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(loading ? 'Підключення…' : (registering ? 'Зареєструватися' : 'Увійти')),
                      ),
                    ),
                    TextButton(
                      onPressed: loading ? null : () => setState(() {
                        registering = !registering; error = null; info = null;
                      }),
                      child: Text(registering ? 'Уже є акаунт? Увійти' : 'Немає акаунта? Зареєструватися'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class StickyNote {
  final String id;
  final String body;
  final String color;
  final double x;
  final double y;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  const StickyNote({
    required this.id,
    required this.body,
    required this.color,
    required this.x,
    required this.y,
    this.deletedAt,
  });

  factory StickyNote.fromJson(Map<String, dynamic> m) => StickyNote(
        id: m['id'] as String,
        body: m['body'] as String? ?? '',
        color: m['color'] as String? ?? 'yellow',
        x: (m['pos_x'] as num?)?.toDouble() ?? 50,
        y: (m['pos_y'] as num?)?.toDouble() ?? 50,
        deletedAt: m['deleted_at'] == null
            ? null
            : DateTime.tryParse(m['deleted_at'] as String),
      );
}

class NotesPage extends StatefulWidget {
  final String userId;
  const NotesPage({super.key, required this.userId});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late Stream<List<Map<String, dynamic>>> notesStream;
  final Map<String, Offset> draggedPositions = {};
  final Set<String> purgedNoteIds = <String>{};
  final Set<String> deletingNoteIds = <String>{};
  Timer? trashRefreshTimer;
  String search = '';
  bool busy = false;
  bool showTrash = false;

  Stream<List<Map<String, dynamic>>> makeNotesStream() => Supabase.instance.client
      .from('notes')
      .stream(primaryKey: ['id'])
      .eq('user_id', widget.userId)
      .order('created_at', ascending: true);

  @override
  void initState() {
    super.initState();
    notesStream = makeNotesStream();
  }

  // Supabase DELETE events may not pass the stream's user_id filter under RLS.
  // While the bin is visible, re-fetch periodically to reconcile hard deletes
  // made on another signed-in device, without exposing other users' IDs.
  void updateTrashRefresh() {
    trashRefreshTimer?.cancel();
    trashRefreshTimer = null;
    if (showTrash) {
      trashRefreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
        if (mounted && showTrash) {
          setState(() => notesStream = makeNotesStream());
        }
      });
    }
  }

  @override
  void dispose() {
    trashRefreshTimer?.cancel();
    super.dispose();
  }

  void showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Помилка: $error')),
    );
  }

  Future<void> createNote(int count) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final i = count;
      final created = await Supabase.instance.client.from('notes').insert({
        'user_id': widget.userId,
        'body': '',
        'color': 'yellow',
        'pos_x': (55 + (i % 5) * 260).toDouble(),
        'pos_y': (55 + ((i ~/ 5) % 4) * 240).toDouble(),
      }).select().single();
      if (!mounted) return;
      await editNote(StickyNote.fromJson(created));
    } catch (e) {
      showError(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> editNote(StickyNote note) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NoteEditor(note: note),
    );
  }

  Future<void> updatePosition(StickyNote note, Offset offset) async {
    try {
      await Supabase.instance.client.from('notes').update({
        'pos_x': offset.dx,
        'pos_y': offset.dy,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', note.id);
    } catch (e) {
      showError(e);
    } finally {
      if (mounted) setState(() => draggedPositions.remove(note.id));
    }
  }

  Future<void> restoreNote(StickyNote note) async {
    try {
      final result = await Supabase.instance.client
          .from('notes')
          .update({
            'deleted_at': null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', note.id)
          .eq('user_id', widget.userId)
          .select('id')
          .maybeSingle();
      if (result == null) {
        throw StateError('Нотатку не знайдено або немає дозволу на відновлення.');
      }
    } catch (e) {
      showError(e);
    }
  }

  Future<void> permanentlyDeleteNote(StickyNote note) async {
    if (deletingNoteIds.contains(note.id)) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Видалити назавжди?'),
        content: const Text(
          'Цю записочку буде безповоротно видалено з бази даних. '
          'Відновити її з кошика буде неможливо.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Скасувати'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Видалити назавжди'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;

    setState(() => deletingNoteIds.add(note.id));
    try {
      final deleted = await Supabase.instance.client
          .from('notes')
          .delete()
          .eq('id', note.id)
          .eq('user_id', widget.userId)
          .select('id')
          .maybeSingle();
      if (deleted == null) {
        throw StateError('Нотатку не знайдено або немає дозволу на видалення.');
      }
      if (!mounted) return;
      // Remove locally at once, even if DELETE is not delivered by Realtime.
      setState(() {
        purgedNoteIds.add(note.id);
        notesStream = makeNotesStream();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нотатку остаточно видалено.')),
      );
    } catch (e) {
      showError(e);
    } finally {
      if (mounted) setState(() => deletingNoteIds.remove(note.id));
    }
  }

  Widget trashList(List<StickyNote> notes) => Container(
    color: const Color(0xFFEAE6DB),
    child: notes.isEmpty
        ? const Center(child: Text('Кошик порожній.'))
        : ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              final body = note.body.trim();
              return Card(
                color: paperColors[note.color] ?? paperColors['yellow'],
                child: ListTile(
                  leading: const Icon(Icons.sticky_note_2_outlined),
                  title: Text(
                    body.isEmpty ? 'Нова нотатка' : body.split('\n').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    body.isEmpty ? 'Порожня нотатка' : body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: deletingNoteIds.contains(note.id)
                            ? null : () => restoreNote(note),
                        icon: const Icon(Icons.restore),
                        label: const Text('Відновити'),
                      ),
                      IconButton(
                        tooltip: 'Видалити назавжди',
                        onPressed: deletingNoteIds.contains(note.id)
                            ? null : () => permanentlyDeleteNote(note),
                        icon: deletingNoteIds.contains(note.id)
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_forever_outlined),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
  );

  Widget desktopBoard(List<StickyNote> notes) => Container(
    color: const Color(0xFFE5E0D5),
    child: InteractiveViewer(
      minScale: 0.55,
      maxScale: 2.5,
      boundaryMargin: const EdgeInsets.all(150),
      constrained: false,
      child: SizedBox(
        width: boardWidth,
        height: boardHeight,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: BoardGridPainter())),
            for (final note in notes)
              Positioned(
                left: (draggedPositions[note.id]?.dx ?? note.x).clamp(0.0, boardWidth - noteWidth),
                top: (draggedPositions[note.id]?.dy ?? note.y).clamp(0.0, boardHeight - noteHeight),
                child: GestureDetector(
                  onTap: () => editNote(note),
                  onPanUpdate: (details) => setState(() {
                    final old = draggedPositions[note.id] ?? Offset(note.x, note.y);
                    draggedPositions[note.id] = Offset(
                      (old.dx + details.delta.dx).clamp(0.0, boardWidth - noteWidth),
                      (old.dy + details.delta.dy).clamp(0.0, boardHeight - noteHeight),
                    );
                  }),
                  onPanEnd: (_) {
                    final offset = draggedPositions[note.id];
                    if (offset != null) updatePosition(note, offset);
                  },
                  child: StickyNoteCard(note: note, width: noteWidth, height: noteHeight),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget mobileList(List<StickyNote> notes) => Container(
    color: const Color(0xFFEAE6DB),
    child: notes.isEmpty
        ? const Center(child: Text('Поки немає нотаток. Натисни +, щоб створити.'))
        : LayoutBuilder(builder: (context, c) {
            final columns = c.maxWidth > 550 ? 2 : 1;
            return GridView.builder(
              padding: const EdgeInsets.all(18),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: columns == 1 ? 1.8 : 1.2,
              ),
              itemCount: notes.length,
              itemBuilder: (_, i) => InkWell(
                onTap: () => editNote(notes[i]),
                child: StickyNoteCard(note: notes[i], width: double.infinity,
                    height: double.infinity, rotate: false),
              ),
            );
          }),
  );

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Map<String, dynamic>>>(
    stream: notesStream,
    builder: (context, snapshot) {
      final all = (snapshot.data ?? []).map(StickyNote.fromJson).toList();
      final filtered = all.where((n) =>
        !purgedNoteIds.contains(n.id) &&
        n.isDeleted == showTrash &&
        n.body.toLowerCase().contains(search.toLowerCase())).toList();
      final narrow = MediaQuery.sizeOf(context).width < 700;

      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F6EE),
          title: Text(showTrash ? 'StickySpace — Кошик' : 'StickySpace',
            style: const TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              tooltip: showTrash ? 'Повернутися до дошки' : 'Кошик',
              icon: Icon(showTrash ? Icons.dashboard_outlined : Icons.delete_outline),
              onPressed: () {
                setState(() {
                  showTrash = !showTrash;
                  notesStream = makeNotesStream();
                });
                updateTrashRefresh();
              },
            ),
            if (!narrow)
              SizedBox(width: 250, child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextField(
                  onChanged: (value) => setState(() => search = value),
                  decoration: const InputDecoration(
                    hintText: 'Знайти нотатку', prefixIcon: Icon(Icons.search),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              )),
            IconButton(
              tooltip: 'Вийти з акаунта',
              onPressed: () async => Supabase.instance.client.auth.signOut(),
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: narrow
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(54),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      onChanged: (value) => setState(() => search = value),
                      decoration: const InputDecoration(
                        hintText: 'Пошук нотаток', prefixIcon: Icon(Icons.search),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                )
              : null,
        ),
        body: snapshot.hasError
            ? Center(child: Text('Помилка завантаження: ${snapshot.error}'))
            : !snapshot.hasData
                ? const Center(child: CircularProgressIndicator())
                : showTrash
                    ? trashList(filtered)
                    : Stack(children: [
                    Positioned.fill(child: narrow
                      ? mobileList(filtered)
                      : desktopBoard(filtered)),
                    if (!narrow)
                      const Positioned(left: 20, bottom: 20,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: Color(0xE9FFFFFF),
                            borderRadius: BorderRadius.all(Radius.circular(12))),
                          child: Padding(padding: EdgeInsets.all(12),
                            child: Text('Перетягни нотатку, щоб перемістити. Натисни, щоб редагувати.')),
                        )),
                  ]),
        floatingActionButton: showTrash ? null : FloatingActionButton.extended(
          onPressed: busy ? null : () => createNote(all.where((n) => !n.isDeleted).length),
          label: const Text('Нова нотатка'),
          icon: const Icon(Icons.add),
        ),
      );
    },
  );
}

class StickyNoteCard extends StatelessWidget {
  final StickyNote note;
  final double width;
  final double height;
  final bool rotate;

  const StickyNoteCard({super.key, required this.note, required this.width,
    required this.height, this.rotate = true});

  @override
  Widget build(BuildContext context) {
    final angle = rotate ? ((note.id.hashCode % 7) - 3) * math.pi / 600 : 0.0;
    final firstLine = note.body.trim().split('\n').first;
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width, height: height,
        padding: const EdgeInsets.fromLTRB(17, 20, 17, 14),
        decoration: BoxDecoration(
          color: paperColors[note.color] ?? paperColors['yellow'],
          borderRadius: BorderRadius.circular(3),
          boxShadow: const [
            BoxShadow(color: Color(0x30000000), blurRadius: 13, offset: Offset(2, 7)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 3, width: 35, color: const Color(0x3A282828)),
            const SizedBox(height: 14),
            Text(firstLine.isEmpty ? 'Нова нотатка' : firstLine,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700,
                color: Color(0xFF34322E))),
            const SizedBox(height: 9),
            Expanded(
              child: Text(
                note.body.contains('\n')
                    ? note.body.substring(note.body.indexOf('\n') + 1)
                    : '',
                overflow: TextOverflow.fade,
                style: const TextStyle(fontSize: 15, height: 1.4,
                  color: Color(0xFF45423D)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BoardGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x29968C79);
    for (double x = 18; x < size.width; x += 35) {
      for (double y = 18; y < size.height; y += 35) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoardGridPainter oldDelegate) => false;
}

class NoteEditor extends StatefulWidget {
  final StickyNote note;
  const NoteEditor({super.key, required this.note});

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final TextEditingController textController;
  late String color;
  Timer? debounce;
  Future<void> saveQueue = Future<void>.value();
  bool closing = false;
  String? saveError;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: widget.note.body);
    color = widget.note.color;
  }

  void scheduleSave() {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 650), queueSave);
  }

  void queueSave() {
    final body = textController.text;
    final currentColor = color;
    saveQueue = saveQueue.catchError((Object _) {}).then((_) async {
      await Supabase.instance.client.from('notes').update({
        'body': body,
        'color': currentColor,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', widget.note.id);
    });
    saveQueue.catchError((Object error) {
      if (mounted) setState(() => saveError = 'Помилка збереження: $error');
    });
  }

  Future<void> finish() async {
    if (closing) return;
    setState(() { closing = true; saveError = null; });
    debounce?.cancel();
    queueSave();
    try {
      await saveQueue;
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() { closing = false; saveError = 'Не вдалося зберегти: $e'; });
    }
  }

  Future<void> deleteNote() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Перемістити в кошик?'),
        content: const Text('Нотатку можна буде відновити з кошика.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати')),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('У кошик')),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;
    setState(() => closing = true);
    debounce?.cancel();
    try {
      await saveQueue.catchError((Object _) {});
      final result = await Supabase.instance.client.from('notes')
          .update({
            'deleted_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', widget.note.id)
          .select('id')
          .maybeSingle();
      if (result == null) {
        throw StateError('Нотатку не знайдено або немає дозволу на видалення.');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { closing = false; saveError = '$e'; });
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.sticky_note_2_outlined),
              const SizedBox(width: 8),
              const Expanded(child: Text('Редагування нотатки',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
              IconButton(tooltip: 'У кошик', onPressed: closing ? null : deleteNote,
                icon: const Icon(Icons.delete_outline)),
            ]),
            const SizedBox(height: 14),
            Flexible(
              child: TextField(
                controller: textController,
                autofocus: true,
                maxLines: null,
                expands: true,
                onChanged: (_) => scheduleSave(),
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Напиши свою нотатку…',
                  filled: true,
                  fillColor: paperColors[color],
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 18, height: 1.45),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(spacing: 10, runSpacing: 8, children: [
              for (final entry in paperColors.entries)
                InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: closing ? null : () { setState(() => color = entry.key); scheduleSave(); },
                  child: CircleAvatar(
                    radius: 19, backgroundColor: entry.value,
                    child: color == entry.key ? const Icon(Icons.check, size: 19,
                      color: Colors.black87) : null,
                  ),
                ),
            ]),
            if (saveError != null) Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(saveError!, style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 14),
            Row(children: [
              const Expanded(child: Text('Автозбереження під час редагування',
                style: TextStyle(fontSize: 12, color: Colors.black54))),
              FilledButton(onPressed: closing ? null : finish,
                child: Text(closing ? 'Збереження…' : 'Готово')),
            ]),
          ],
        ),
      ),
    ),
  );
}
