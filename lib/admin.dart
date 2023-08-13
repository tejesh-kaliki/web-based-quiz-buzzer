import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class BuzzerAdminPage extends StatefulWidget {
  const BuzzerAdminPage({super.key});

  @override
  State<BuzzerAdminPage> createState() => _BuzzerAdminPageState();
}

class _BuzzerAdminPageState extends State<BuzzerAdminPage> {
  DatabaseReference teamRef = FirebaseDatabase.instance.ref("buzzer/teams");
  DatabaseReference buzzerRef = FirebaseDatabase.instance.ref("buzzer/enabled");
  DatabaseReference raisedHandsRef =
      FirebaseDatabase.instance.ref("buzzer/active-teams");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Center(
            child: Text(
              "Buzzer Admin",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Center(
              child: StreamBuilder<DatabaseEvent>(
                stream: buzzerRef.onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.snapshot.exists) {
                    return const Text("Getting buzzer status...");
                  }
                  bool enabled = snapshot.data!.snapshot.value as bool;

                  if (enabled) {
                    return ElevatedButton(
                      onPressed: _disableBuzzer,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                      child: const Text("Deactivate Buzzer"),
                    );
                  }

                  return ElevatedButton(
                    onPressed: _enableBuzzer,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent),
                    child: const Text(
                      "Activate Buzzer",
                      style: TextStyle(color: Colors.black),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.green.shade50.withOpacity(0.8),
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: StreamBuilder<DatabaseEvent>(
              stream: raisedHandsRef.onValue,
              builder: (context, snapshot) {
                List<String> teams = [];
                if (snapshot.hasData && snapshot.data!.snapshot.exists) {
                  teams = snapshot.data!.snapshot.children
                      .map((v) => v.value.toString())
                      .toList();
                }
                if (teams.length >= 5) buzzerRef.set(false);

                return ExpansionTile(
                  initiallyExpanded: true,
                  title: Text("Raised Hands List (${teams.length})"),
                  children: [
                    for (int i = 0; i < teams.length; i++)
                      ListTile(
                        title: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: Colors.green,
                              ),
                              child: Center(
                                child: Text(
                                  "${i + 1}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(teams[i]),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          StreamBuilder<DatabaseEvent>(
            stream: teamRef.onValue,
            builder: (context, snapshot) {
              Map<String, String> teams = {};
              if (snapshot.hasData && snapshot.data!.snapshot.exists) {
                teams = (snapshot.data!.snapshot.value as Map)
                    .map<String, String>(
                        (k, v) => MapEntry(k.toString(), v.toString()));
              }
              return ExpansionTile(
                title: Text("Team List (${teams.length})"),
                children: teams.map(displayTeamTile).values.toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  MapEntry<String, Widget> displayTeamTile(key, value) {
    return MapEntry(
      key,
      ListTile(
        title: Text(value),
        trailing: IconButton(
          onPressed: () => _removeTeam(key, value),
          icon: const Icon(Icons.delete),
        ),
      ),
    );
  }

  void _disableBuzzer() {
    showConfirmationDialog(
      "Are You Sure?",
      "This deactivates the buzzer.",
      onCancel: () => Navigator.of(context).pop("Cancel"),
      onConfirm: () async {
        Navigator.of(context).pop("Confirm");
        await buzzerRef.set(false);
      },
    );
  }

  void _enableBuzzer() {
    showConfirmationDialog(
      "Are You Sure?",
      "This clears the Raised Hands and activates the buzzer.",
      onCancel: () => Navigator.of(context).pop("Cancel"),
      onConfirm: () async {
        Navigator.of(context).pop("Confirm");
        await raisedHandsRef.remove();
        await buzzerRef.set(true);
      },
    );
  }

  void _removeTeam(String key, String teamName) async {
    showConfirmationDialog(
      "Are You Sure?",
      "Do you want to delete team '$teamName'?",
      onCancel: () => Navigator.of(context).pop("Cancel"),
      onConfirm: () async {
        Navigator.of(context).pop("Confirm");
        await teamRef.child(key).remove();
      },
    );
  }

  Future<dynamic> showConfirmationDialog(String title, String content,
      {void Function()? onCancel, void Function()? onConfirm}) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(content),
          actions: [
            TextButton(onPressed: onCancel, child: const Text("Cancel")),
            ElevatedButton(onPressed: onConfirm, child: const Text("Confirm")),
          ],
        );
      },
    );
  }
}
