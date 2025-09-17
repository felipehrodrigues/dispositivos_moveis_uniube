import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;
  DateTime diaSelecionado = DateTime.now();
  final TextEditingController tarefaController = TextEditingController();

  CollectionReference get tarefasRef => FirebaseFirestore.instance
      .collection('usuarios')
      .doc(user!.uid)
      .collection('tarefas');

  String formatarData(DateTime data) {
    return DateFormat('yyyy-MM-dd').format(data);
  }

  void adicionarTarefa() async {
    if (tarefaController.text.isNotEmpty) {
      await tarefasRef.add({
        "texto": tarefaController.text,
        "concluida": false,
        "data": formatarData(diaSelecionado),
        "criadoEm": DateTime.now(),
      });
      tarefaController.clear();
    }
  }

  void abrirDialogoAdicionar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nova tarefa"),
        content: TextField(
          controller: tarefaController,
          decoration: const InputDecoration(hintText: "Digite a tarefa"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              adicionarTarefa();
              Navigator.pop(context);
            },
            child: const Text("Adicionar"),
          ),
        ],
      ),
    );
  }

  void marcarConcluida(String id, bool atual) async {
    await tarefasRef.doc(id).update({"concluida": !atual});
  }

  void removerTarefa(String id) async {
    await tarefasRef.doc(id).delete();
  }

  Stream<QuerySnapshot> obterStreamTarefas(DateTime dia) {
    String diaString = formatarData(dia);
    return tarefasRef
        .where("data", isEqualTo: diaString)
        .orderBy("criadoEm")
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        title: const Text("Gerenciador de Tarefas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              color: Colors.white,
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: diaSelecionado,
                selectedDayPredicate: (day) =>
                    day.year == diaSelecionado.year &&
                    day.month == diaSelecionado.month &&
                    day.day == diaSelecionado.day,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    diaSelecionado = selectedDay;
                  });
                },
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: obterStreamTarefas(diaSelecionado),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Erro ao carregar tarefas",
                      style: TextStyle(color: Colors.black),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Nenhum tarefa neste dia",
                      style: TextStyle(color: Colors.black),
                    ),
                  );
                }

                return ListView(
                  children: docs.map((tarefa) {
                    return ListTile(
                      leading: Checkbox(
                        value: tarefa["concluida"],
                        onChanged: (value) =>
                            marcarConcluida(tarefa.id, tarefa["concluida"]),
                      ),
                      title: Text(
                        tarefa["texto"],
                        style: TextStyle(
                          color: Colors.black,
                          decoration: tarefa["concluida"]
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => removerTarefa(tarefa.id),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Text(
                  "Gerenciador de Tarefas",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  "Feito por Felipe Rodriguese - RA 1174615",
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: abrirDialogoAdicionar,
        child: const Icon(Icons.add),
      ),
    );
  }
}
