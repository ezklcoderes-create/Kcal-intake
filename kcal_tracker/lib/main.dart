import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const KcalTrackerApp());
}

class KcalTrackerApp extends StatelessWidget {
  const KcalTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KCAL TRACKER',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4C8C78)),
        scaffoldBackgroundColor: const Color(0xFFEAF4F0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(.60),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.white.withOpacity(.8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF4C8C78), width: 1.5),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }
        if (snapshot.hasData) return const DashboardScreen();
        return const AuthScreen();
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.57),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(.85), width: 1.2),
            boxShadow: [
              BoxShadow(color: const Color(0xFF547A6C).withOpacity(.08), blurRadius: 22, offset: const Offset(0, 9)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      if (_register) {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        await credential.user?.updateDisplayName(_name.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
          'displayName': _name.text.trim(),
          'email': _email.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(_authError(e));
    } catch (e) {
      _showMessage('Something went wrong. Check your connection and Firebase setup.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use': return 'That email is already registered.';
      case 'invalid-email': return 'Please enter a valid email address.';
      case 'weak-password': return 'Please choose a stronger password.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential': return 'Email or password is incorrect.';
      default: return e.message ?? 'Unable to sign in. Please try again.';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      height: 78,
                      width: 78,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(.72), shape: BoxShape.circle),
                      child: const Icon(Icons.spa_rounded, color: Color(0xFF397765), size: 40),
                    ),
                    const SizedBox(height: 18),
                    const Text('KCAL TRACKER', textAlign: TextAlign.center, style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFF24483D))),
                    const SizedBox(height: 7),
                    Text(_register ? 'Create your food journal account' : 'A simple space to track what you eat', textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey.shade700)),
                    const SizedBox(height: 30),
                    GlassPanel(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(_register ? 'Create account' : 'Welcome back', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF24483D))),
                            const SizedBox(height: 20),
                            if (_register) ...[
                              TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null),
                              const SizedBox(height: 13),
                            ],
                            TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline)), validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null),
                            const SizedBox(height: 13),
                            TextFormField(controller: _password, obscureText: _hidePassword, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => _hidePassword = !_hidePassword), icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined))), validator: (v) => (v == null || v.length < 6) ? 'Use at least 6 characters' : null),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: _busy ? null : _submit,
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF397765), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
                              child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_register ? 'Create account' : 'Log in', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 12),
                            TextButton(onPressed: _busy ? null : () => setState(() => _register = !_register), child: Text(_register ? 'Already have an account? Log in' : 'New here? Create an account', style: const TextStyle(color: Color(0xFF397765)))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Track meals. Notice patterns. Build food awareness.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SoftBackground extends StatelessWidget {
  const SoftBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE4F2EC), Color(0xFFF5F8F5), Color(0xFFDDECE7)]),
      ),
      child: Stack(
        children: [
          Positioned(top: -70, right: -55, child: _orb(220, const Color(0xFF9CCDBA).withOpacity(.32))),
          Positioned(bottom: -90, left: -70, child: _orb(250, const Color(0xFFB5CFE0).withOpacity(.30))),
          child,
        ],
      ),
    );
  }

  Widget _orb(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDate = DateTime.now();
  String _mealFilter = 'All';

  User get _user => FirebaseAuth.instance.currentUser!;
  CollectionReference<Map<String, dynamic>> get _entries => FirebaseFirestore.instance.collection('users').doc(_user.uid).collection('food_entries');

  DateTime get _dayStart => DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
  DateTime get _dayEnd => _dayStart.add(const Duration(days: 1));

  Query<Map<String, dynamic>> get _dayQuery => _entries.where('loggedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_dayStart)).where('loggedAt', isLessThan: Timestamp.fromDate(_dayEnd)).orderBy('loggedAt', descending: true);

  Future<void> _openEntry({DocumentSnapshot<Map<String, dynamic>>? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EntrySheet(entries: _entries, existing: existing, defaultDate: _selectedDate),
    );
  }

  Future<void> _changeDate() async {
    final chosen = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)));
    if (chosen != null) setState(() => _selectedDate = chosen);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.isSameDay(_selectedDate, DateTime.now());
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _dayQuery.snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              final total = docs.fold<int>(0, (sum, doc) => sum + ((doc.data()['kcal'] as num?)?.round() ?? 0));
              final filtered = _mealFilter == 'All' ? docs : docs.where((d) => d.data()['meal'] == _mealFilter).toList();
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                    sliver: SliverList(delegate: SliverChildListDelegate([
                      Row(
                        children: [
                          Container(width: 45, height: 45, decoration: BoxDecoration(color: Colors.white.withOpacity(.72), shape: BoxShape.circle), child: const Icon(Icons.spa_rounded, color: Color(0xFF397765))),
                          const SizedBox(width: 11),
                          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('KCAL TRACKER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1, color: Color(0xFF24483D))), Text('Your daily food journal', style: TextStyle(fontSize: 12, color: Colors.blueGrey))])),
                          IconButton(tooltip: 'Log out', onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout_rounded, color: Color(0xFF397765))),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(children: [const Expanded(child: Text('Your dashboard', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Color(0xFF24483D)))), TextButton.icon(onPressed: _changeDate, icon: const Icon(Icons.calendar_month, size: 18), label: Text(DateFormat('MMM d').format(_selectedDate)))]),
                      const SizedBox(height: 12),
                      GlassPanel(
                        padding: const EdgeInsets.all(22),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(today ? "TODAY'S FOOD ENERGY" : DateFormat('EEEE, MMM d').format(_selectedDate).toUpperCase(), style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade600)),
                          const SizedBox(height: 8),
                          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(NumberFormat('#,###').format(total), style: const TextStyle(fontSize: 43, fontWeight: FontWeight.w900, color: Color(0xFF24483D))), const Padding(padding: EdgeInsets.only(bottom: 8, left: 7), child: Text('kcal logged', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600)))]),
                          const SizedBox(height: 6),
                          Text('${docs.length} food ${docs.length == 1 ? 'entry' : 'entries'} recorded', style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13)),
                          const SizedBox(height: 16),
                          Container(height: 8, decoration: BoxDecoration(color: const Color(0xFFDCE9E3), borderRadius: BorderRadius.circular(20)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 1, child: Container(decoration: BoxDecoration(color: const Color(0xFF78A995), borderRadius: BorderRadius.circular(20))))),
                          const SizedBox(height: 9),
                          const Text('A simple record of what you have eaten — no daily target required.', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: _statCard(Icons.restaurant_menu, '${docs.length}', 'Food entries')),
                        const SizedBox(width: 12),
                        Expanded(child: _statCard(Icons.local_fire_department_outlined, NumberFormat('#,###').format(total), 'Total kcal')),
                      ]),
                      const SizedBox(height: 22),
                      Row(children: [const Expanded(child: Text('Food diary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF24483D)))), FilledButton.icon(onPressed: () => _openEntry(), icon: const Icon(Icons.add, size: 18), label: const Text('Add food'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF397765), foregroundColor: Colors.white))]),
                      const SizedBox(height: 12),
                      SizedBox(height: 39, child: ListView(scrollDirection: Axis.horizontal, children: ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snack'].map((meal) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(meal), selected: _mealFilter == meal, onSelected: (_) => setState(() => _mealFilter = meal), selectedColor: const Color(0xFFBBD9CB), backgroundColor: Colors.white.withOpacity(.6), side: BorderSide(color: Colors.white.withOpacity(.8)))).toList())),
                      const SizedBox(height: 12),
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData)
                        const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
                      else if (filtered.isEmpty)
                        GlassPanel(child: Column(children: [const Icon(Icons.no_food_rounded, size: 38, color: Color(0xFF78A995)), const SizedBox(height: 9), const Text('No food entries yet', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF24483D))), const SizedBox(height: 4), const Text('Add a meal or snack to start your journal.', textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey, fontSize: 12)), const SizedBox(height: 12), OutlinedButton.icon(onPressed: () => _openEntry(), icon: const Icon(Icons.add), label: const Text('Add your first food'))]))
                      else
                        ...filtered.map((doc) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _foodTile(doc))),
                      const SizedBox(height: 12),
                      GlassPanel(padding: const EdgeInsets.all(15), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.lightbulb_outline, color: Color(0xFF397765)), const SizedBox(width: 10), const Expanded(child: Text('Food values are estimates. Serving sizes and recipes can change the actual nutrition information.', style: TextStyle(fontSize: 12, color: Colors.blueGrey, height: 1.4)))])),
                    ])),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _openEntry(), backgroundColor: const Color(0xFF397765), foregroundColor: Colors.white, icon: const Icon(Icons.add), label: const Text('Add kcal')),
    );
  }

  Widget _statCard(IconData icon, String value, String label) => GlassPanel(padding: const EdgeInsets.all(15), child: Row(children: [Icon(icon, color: const Color(0xFF397765), size: 23), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: Color(0xFF24483D))), Text(label, style: const TextStyle(fontSize: 11, color: Colors.blueGrey))]))]));

  Widget _foodTile(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final kcal = (data['kcal'] as num?)?.round() ?? 0;
    final meal = data['meal'] as String? ?? 'Snack';
    final time = (data['loggedAt'] as Timestamp?)?.toDate();
    final icon = switch (meal) { 'Breakfast' => Icons.wb_twilight, 'Lunch' => Icons.wb_sunny_outlined, 'Dinner' => Icons.nights_stay_outlined, _ => Icons.apple_outlined };
    return GlassPanel(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(children: [Container(width: 43, height: 43, decoration: BoxDecoration(color: const Color(0xFFDCECE4), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: const Color(0xFF397765))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['name'] as String? ?? 'Food', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF24483D))), Text('$meal${time == null ? '' : ' • ${DateFormat('h:mm a').format(time)}'}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey))])), Text('$kcal kcal', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF397765))), PopupMenuButton<String>(onSelected: (value) { if (value == 'edit') _openEntry(existing: doc); if (value == 'delete') _confirmDelete(doc); }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete'))]) ]));
  }

  Future<void> _confirmDelete(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Delete food entry?'), content: const Text('This removes the entry from your food diary.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))]));
    if (yes == true) await doc.reference.delete();
  }
}

class EntrySheet extends StatefulWidget {
  const EntrySheet({super.key, required this.entries, this.existing, required this.defaultDate});
  final CollectionReference<Map<String, dynamic>> entries;
  final DocumentSnapshot<Map<String, dynamic>>? existing;
  final DateTime defaultDate;

  @override
  State<EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<EntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _kcal;
  late final TextEditingController _serving;
  late String _meal;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.existing?.data();
    _name = TextEditingController(text: data?['name'] as String? ?? '');
    _kcal = TextEditingController(text: data?['kcal']?.toString() ?? '');
    _serving = TextEditingController(text: data?['serving'] as String? ?? '1 serving');
    _meal = data?['meal'] as String? ?? 'Breakfast';
  }

  @override
  void dispose() {
    _name.dispose();
    _kcal.dispose();
    _serving.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'name': _name.text.trim(),
      'kcal': int.parse(_kcal.text.trim()),
      'serving': _serving.text.trim(),
      'meal': _meal,
      'loggedAt': Timestamp.fromDate(widget.defaultDate),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    try {
      if (widget.existing == null) {
        await widget.entries.add({...data, 'createdAt': FieldValue.serverTimestamp()});
      } else {
        await widget.existing!.reference.update(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save entry. Please try again.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: Color(0xFFF0F7F3), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(22, 14, 22, 24), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFB7CFC4), borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 18),
          Text(widget.existing == null ? 'Add food entry' : 'Edit food entry', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF24483D))),
          const SizedBox(height: 5),
          const Text('Enter the food and its estimated energy.', style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
          const SizedBox(height: 18),
          TextFormField(controller: _name, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Food name', prefixIcon: Icon(Icons.restaurant)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a food name' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _kcal, keyboardType: const TextInputType.numberWithOptions(decimal: false), decoration: const InputDecoration(labelText: 'Calories (kcal)', prefixIcon: Icon(Icons.local_fire_department_outlined), suffixText: 'kcal'), validator: (v) { final n = int.tryParse(v ?? ''); if (n == null || n < 0 || n > 100000) return 'Enter a valid kcal number'; return null; }),
          const SizedBox(height: 12),
          TextFormField(controller: _serving, decoration: const InputDecoration(labelText: 'Serving / portion', prefixIcon: Icon(Icons.scale_outlined)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a serving description' : null),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: _meal, decoration: const InputDecoration(labelText: 'Meal category', prefixIcon: Icon(Icons.category_outlined)), items: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(), onChanged: (v) => setState(() => _meal = v ?? 'Snack')),
          const SizedBox(height: 20),
          FilledButton(onPressed: _saving ? null : _save, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF397765), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))), child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(widget.existing == null ? 'Save food entry' : 'Update entry')),
        ]))),
      ),
    );
  }
}
