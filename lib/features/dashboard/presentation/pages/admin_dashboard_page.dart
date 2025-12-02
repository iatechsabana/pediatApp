import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminDashboardPage extends StatelessWidget {
  AdminDashboardPage({Key? key}) : super(key: key);

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Panel Administrador'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, AppColors.primary],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Panel de Administración',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 18),
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre o email...',
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').where('type', isEqualTo: 'pediatra').where('estado', isEqualTo: 'pendiente').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No hay pediatras pendientes.'));
                        }
                        final docs = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final search = searchController.text.toLowerCase();
                          return data['name']?.toLowerCase().contains(search) == true || data['email']?.toLowerCase().contains(search) == true;
                        }).toList();
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            final polizaOk = data['polizaUrl'] != null && data['polizaUrl'].toString().isNotEmpty;
                            final tarjetaOk = data['tarjetaProfesionalUrl'] != null && data['tarjetaProfesionalUrl'].toString().isNotEmpty;
                            return Card(
                              child: ListTile(
                                title: Text(data['name'] ?? ''),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Email: ${data['email'] ?? ''}'),
                                    Text('Tel: ${data['phone'] ?? ''}'),
                                    if (!polizaOk)
                                      const Text('Falta póliza', style: TextStyle(color: Colors.red)),
                                    if (!tarjetaOk)
                                      const Text('Falta tarjeta profesional', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                                trailing: (polizaOk && tarjetaOk)
                                    ? ElevatedButton(
                                        onPressed: () async {
                                          await FirebaseFirestore.instance.collection('users').doc(docs[index].id).update({'estado': 'habilitado'});
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario habilitado')));
                                        },
                                        child: const Text('Aprobar'),
                                      )
                                    : const Text('Documentos incompletos', style: TextStyle(color: Colors.orange)),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text('Documentos de ${data['name'] ?? ''}'),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Poliza:'),
                                            polizaOk
                                                ? InkWell(
                                                    child: Text(data['polizaUrl'], style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                                                    onTap: () => _launchUrl(context, data['polizaUrl']),
                                                  )
                                                : const Text('No subido'),
                                            const SizedBox(height: 8),
                                            Text('Tarjeta Profesional:'),
                                            tarjetaOk
                                                ? InkWell(
                                                    child: Text(data['tarjetaProfesionalUrl'], style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                                                    onTap: () => _launchUrl(context, data['tarjetaProfesionalUrl']),
                                                  )
                                                : const Text('No subido'),
                                            const SizedBox(height: 8),
                                            Text('Documentos adicionales:'),
                                            if (data['documentos'] != null && data['documentos'] is List && (data['documentos'] as List).isNotEmpty)
                                              ...List<Widget>.from((data['documentos'] as List).map((docUrl) => InkWell(
                                                    child: Text(docUrl, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                                                    onTap: () => _launchUrl(context, docUrl),
                                                  )))
                                            else
                                              const Text('No subidos'),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Cerrar'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Pediatras habilitados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                Card(
                  color: Colors.white,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').where('type', isEqualTo: 'pediatra').where('estado', isEqualTo: 'habilitado').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No hay pediatras habilitados.'));
                        }
                        final docs = snapshot.data!.docs;
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            return Card(
                              child: ListTile(
                                title: Text(data['name'] ?? ''),
                                subtitle: Text('Email: ${data['email'] ?? ''}\nTel: ${data['phone'] ?? ''}'),
                                trailing: const Text('Habilitado', style: TextStyle(color: Colors.green)),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text('Documentos de ${data['name'] ?? ''}'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Poliza: ${data['polizaUrl'] ?? 'No subido'}'),
                                          Text('Tarjeta Profesional: ${data['tarjetaProfesionalUrl'] ?? 'No subido'}'),
                                          Text('Documentos: ${(data['documentos'] ?? []).toString()}'),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Cerrar'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                // ...aquí va el resto del dashboard limpio y funcional...
              ],
            ),
          ),
        ),
      ),
    );
  }
}
