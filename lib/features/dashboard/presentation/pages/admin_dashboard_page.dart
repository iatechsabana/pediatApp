import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'document_viewer_page.dart';
import '../../../auth/presentation/pages/login_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> sendEmailToUser(
    String email,
    String subject,
    String body,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Panel Administrador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content: const Text(
                    '¿Estás seguro que deseas cerrar sesión?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
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
                const SizedBox(height: 18),

                /// BUSCADOR
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

                /// LISTA PENDIENTES
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('type', isEqualTo: 'pediatra')
                          .where('estado', isEqualTo: 'pendiente')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text('No hay pediatras pendientes.'),
                          );
                        }

                        final docs = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final search = searchController.text.toLowerCase();

                          return data['name']?.toLowerCase().contains(search) ==
                                  true ||
                              data['email']?.toLowerCase().contains(search) ==
                                  true;
                        }).toList();

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;

                            final polizaOk = (data['polizaUrl'] ?? '')
                                .toString()
                                .isNotEmpty;
                            final tarjetaOk =
                                (data['tarjetaProfesionalUrl'] ?? '')
                                    .toString()
                                    .isNotEmpty;

                            return Card(
                              child: ListTile(
                                title: Text(data['name'] ?? ''),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Email: ${data['email'] ?? ''}'),
                                    Text('Tel: ${data['phone'] ?? ''}'),
                                    if (!polizaOk)
                                      const Text(
                                        'Falta póliza',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    if (!tarjetaOk)
                                      const Text(
                                        'Falta tarjeta profesional',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (polizaOk && tarjetaOk)
                                      ElevatedButton(
                                        onPressed: () async {
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(docs[index].id)
                                              .update({'estado': 'habilitado'});

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Registro aprobado y usuario notificado',
                                              ),
                                            ),
                                          );

                                          final email = data['email'] ?? '';
                                          if (email.isNotEmpty) {
                                            await sendEmailToUser(
                                              email,
                                              'Tu cuenta ha sido habilitada en doctorKinds',
                                              '¡Bienvenido! Tu registro fue aprobado.',
                                            );
                                          }
                                        },
                                        child: const Text('Aprobar'),
                                      ),

                                    const SizedBox(width: 8),

                                    /// RECHAZAR
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text(
                                              'Confirmar rechazo',
                                            ),
                                            content: const Text(
                                              '¿Eliminar registro y todos sus archivos?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  ctx,
                                                ).pop(false),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(true),
                                                child: const Text('Eliminar'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm != true) return;

                                        final storage =
                                            FirebaseStorage.instance;
                                        final List<String> urls = [];

                                        void addUrl(String? url) {
                                          if (url != null && url.isNotEmpty)
                                            urls.add(url);
                                        }

                                        addUrl(data['polizaUrl']);
                                        addUrl(data['tarjetaProfesionalUrl']);
                                        addUrl(
                                          data['documentoIdentidadFrenteUrl'],
                                        );
                                        addUrl(
                                          data['documentoIdentidadReversoUrl'],
                                        );

                                        if (data['documentos'] is List) {
                                          urls.addAll(
                                            (data['documentos'] as List)
                                                .whereType<String>(),
                                          );
                                        }

                                        for (final url in urls) {
                                          try {
                                            final ref = storage.refFromURL(url);
                                            await ref.delete();
                                          } catch (_) {}
                                        }

                                        final email = data['email'] ?? '';
                                        if (email.isNotEmpty) {
                                          await sendEmailToUser(
                                            email,
                                            'Registro rechazado',
                                            'Tu registro fue rechazado y eliminado.',
                                          );
                                        }

                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(docs[index].id)
                                            .delete();

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Registro rechazado y eliminado',
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Rechazar',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),

                                /// VER DOCUMENTOS
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text(
                                        'Documentos de ${data['name'] ?? ''}',
                                      ),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildDocRow(
                                              'Póliza',
                                              data['polizaUrl'],
                                              context,
                                            ),
                                            const SizedBox(height: 12),
                                            _buildDocRow(
                                              'Tarjeta Profesional',
                                              data['tarjetaProfesionalUrl'],
                                              context,
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              'Documentos adicionales:',
                                            ),
                                            if (data['documentos'] is List)
                                              ...List<Widget>.from(
                                                (data['documentos'] as List).map(
                                                  (docUrl) => InkWell(
                                                    child: Text(
                                                      docUrl,
                                                      style: const TextStyle(
                                                        color: Colors.blue,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                      ),
                                                    ),
                                                    onTap: () {
                                                      Navigator.of(
                                                        context,
                                                      ).push(
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              DocumentViewerPage(
                                                                url: docUrl,
                                                                title:
                                                                    'Documento adicional',
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              )
                                            else
                                              const Text('No subidos'),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
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

                /// HABILITADOS
                const Text(
                  'Pediatras habilitados',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('type', isEqualTo: 'pediatra')
                          .where('estado', isEqualTo: 'habilitado')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text('No hay pediatras habilitados.'),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;
                            return Card(
                              child: ListTile(
                                title: Text(data['name'] ?? ''),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Email: ${data['email'] ?? ''}'),
                                    Text('Tel: ${data['phone'] ?? ''}'),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocRow(String label, String? url, BuildContext context) {
    final valid = url != null && url.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        valid
            ? InkWell(
                child: Text(
                  url!,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          DocumentViewerPage(url: url, title: label),
                    ),
                  );
                },
              )
            : const Text('No subido'),
      ],
    );
  }
}
