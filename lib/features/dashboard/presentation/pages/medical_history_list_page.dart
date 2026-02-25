import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicalHistoryListPage extends StatefulWidget {
  const MedicalHistoryListPage({super.key});

  @override
  State<MedicalHistoryListPage> createState() => _MedicalHistoryListPageState();
}

class _MedicalHistoryListPageState extends State<MedicalHistoryListPage> {
  String? selectedChild;
  List<String> childNames = [];

  @override
  void initState() {
    super.initState();
    _loadChildNames();
  }

  Future<void> _loadChildNames() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final children = (userDoc.data()?['children'] ?? []) as List<dynamic>;
    setState(() {
      childNames = children.map((c) => c['name']?.toString() ?? '').where((n) => n.isNotEmpty).toList();
      if (childNames.isNotEmpty) selectedChild = childNames.first;
    });
  }

  Future<List<Map<String, dynamic>?>> fetchMedicalHistories() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final query = selectedChild == null || selectedChild!.isEmpty
        ? await FirebaseFirestore.instance
            .collection('medical_histories')
            .where('patientId', isEqualTo: userId)
            .orderBy('updatedAt', descending: true)
            .get()
        : await FirebaseFirestore.instance
            .collection('medical_histories')
            .where('patientId', isEqualTo: userId)
            .where('patientName', isEqualTo: selectedChild)
            .orderBy('updatedAt', descending: true)
            .get();
    return query.docs.map((d) {
      final data = d.data();
      if (data['updatedAt'] is Timestamp) {
        data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate();
      }
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 44,
        title: const Text(
          'Historias clínicas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Filtrar por hijo:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedChild,
                    isExpanded: true,
                    items: childNames.map((name) => DropdownMenuItem(
                      value: name,
                      child: Text(name),
                    )).toList(),
                    onChanged: (val) {
                      setState(() => selectedChild = val);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: fetchMedicalHistories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
                  return const Center(child: Text('No hay historias clínicas registradas.'));
                }
                final histories = snapshot.data as List<Map<String, dynamic>?>;
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: histories.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final h = histories[i];
                    return ListTile(
                      title: Text(h?['patientName'] ?? 'Paciente'),
                      subtitle: Text('Médico: ${h?['pediatricianId'] ?? ''}\nFecha: ${h?['updatedAt'] != null ? (h?['updatedAt'] as DateTime).toLocal().toString().split(' ')[0] : ''}'),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(h?['patientName'] ?? 'Paciente'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Médico: ${h?['pediatricianId'] ?? ''}'),
                                Text('Fecha: ${h?['updatedAt'] != null ? (h?['updatedAt'] as DateTime).toLocal().toString().split(' ')[0] : ''}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cerrar'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
