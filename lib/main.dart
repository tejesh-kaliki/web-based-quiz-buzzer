import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'admin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tech Kshetra',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      routes: {
        "/home": (context) => const MyHomePage(title: "Home"),
        "/buzzer": (context) => const BuzzerPage(),
        "/buzzer-admin": (context) => const BuzzerAdminPage(),
      },
      //TODO: Change this when publishing
      initialRoute: "/buzzer",
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[Text("This Do Not Exist.")],
        ),
      ),
    );
  }
}

class BuzzerPage extends StatefulWidget {
  const BuzzerPage({super.key});

  @override
  State<BuzzerPage> createState() => _BuzzerPageState();
}

class _BuzzerPageState extends State<BuzzerPage> {
  String teamName = "";
  bool nameSubmitted = false;
  bool submitProcessing = false;
  bool buzzerEnabled = false;
  DatabaseReference ref = FirebaseDatabase.instance.ref("buzzer");
  DatabaseReference buzzerRef = FirebaseDatabase.instance.ref("buzzer/enabled");
  DatabaseReference? currentTeamRef;

  @override
  void initState() {
    super.initState();
    buzzerRef.onValue.listen((event) {
      setState(() => buzzerEnabled = event.snapshot.value as bool? ?? false);
    });
  }

  @override
  void dispose() {
    currentTeamRef?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget header = Container(
      margin: const EdgeInsets.all(10),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: Colors.greenAccent.shade200,
        boxShadow: const [
          BoxShadow(offset: Offset(0, 5), blurRadius: 5, color: Colors.black45)
        ],
      ),
      child: Center(
        child: Text(
          "Buzzer",
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );

    List<Widget> children = [header];
    if (!nameSubmitted) {
      children.add(getUserName());
    } else {
      children.addAll(
        [
          displayTeamName(),
          Expanded(
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 8,
                  shape: const CircleBorder(),
                  fixedSize: const Size(200, 200),
                  side: const BorderSide(color: Colors.white, width: 5),
                ),
                onPressed: buzzerEnabled ? _raiseHand : null,
                child: const Text(
                  "Raise Hand!",
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Column(children: children),
    );
  }

  void _raiseHand() async {
    setState(() => buzzerEnabled = false);
    DatabaseReference activeTeamsRef = ref.child("active-teams");
    await activeTeamsRef.push().set(teamName.toLowerCase());  
  }

  Widget displayTeamName() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        "Your Team: $teamName",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget getUserName() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              width: 300,
              child: TextField(
                maxLength: 30,
                onChanged: (value) => setState(() => teamName = value),
                style: const TextStyle(fontWeight: FontWeight.bold),
                onSubmitted: (v) => _submitTeam(),
                decoration: InputDecoration(
                  hintText: "Enter the team name",
                  labelText: "Team Name",
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: CupertinoColors.activeGreen,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  floatingLabelStyle:
                      const TextStyle(color: CupertinoColors.activeGreen),
                ),
              ),
            ),
            ElevatedButton(
              onPressed:
                  teamName.isNotEmpty && !submitProcessing ? _submitTeam : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: CupertinoColors.activeGreen),
              child: const Text("Confirm"),
            ),
          ],
        ),
      ),
    );
  }

  void _submitTeam() async {
    if (!submitProcessing) {
      setState(() => submitProcessing = true);
      String name = teamName.toLowerCase();
      DataSnapshot teamData = await ref.child("teams").get();
      for (DataSnapshot snapshot in teamData.children) {
        if (snapshot.value == name) currentTeamRef = snapshot.ref;
      }

      if (!teamData.exists || currentTeamRef == null) {
        currentTeamRef = ref.child("teams").push()..set(name);
      }

      currentTeamRef!.onValue.listen((event) {
        if (!event.snapshot.exists) {
          setState(() {
            nameSubmitted = false;
            submitProcessing = false;
          });
        }
      });

      setState(() => nameSubmitted = true);
    }
  }
}
