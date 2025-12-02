import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/constants/app_colors.dart';
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

  Future<void> sendEmailToUser(String email, String subject, String body) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryLight, AppColors.primary],
              ),
            ),
          ),
          SafeArea(child: _buildBody()),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      title: const Text("Panel Administrador"),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Cerrar sesión"),
                content: const Text("¿Deseas cerrar sesión?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text("Cancelar"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text("Cerrar sesión"),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            }
          },
        )
      ],
    );
  }

  /// ==========================================================
  /// CUERPO PRINCIPAL COMPLETO (AHORA FUNCIONAL)
  /// ==========================================================
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearch(),
          const SizedBox(height: 20),

          /// Sección de pendientes
          _buildPendingSection(),
          const SizedBox(height: 30),

          /// Sección de habilitados
          _buildEnabledSection(),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: "Buscar pediatra...",
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// ==========================================================
  /// SECCIÓN - PEDIATRAS PENDIENTES
  /// ==========================================================
  Widget _buildPendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pediatras pendientes",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .where("type", isEqualTo: "pediatra")
                  .where("estado", isEqualTo: "pendiente")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final search = searchController.text.toLowerCase();

                  return data["name"]?.toLowerCase().contains(search) == true ||
                      data["email"]?.toLowerCase().contains(search) == true;
                }).toList();

                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text("No hay pediatras pendientes.")),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (_, i) =>
                      _buildPendingCard(docs[i], docs[i].id),
                );
              },
            ),
          ),
        )
      ],
    );
  }

  Widget _buildPendingCard(DocumentSnapshot doc, String id) {
    final data = doc.data() as Map<String, dynamic>;

    final polizaOk = (data["polizaUrl"] ?? "").toString().isNotEmpty;
    final tarjetaOk =
        (data["tarjetaProfesionalUrl"] ?? "").toString().isNotEmpty;

    return Card(
      child: InkWell(
        onTap: () => _openDocumentsDialog(data),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserHeader(data, id, polizaOk, tarjetaOk),
              const SizedBox(height: 10),
              _buildUserInfo(data),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(
      Map<String, dynamic> data, String userId, bool polizaOk, bool tarjetaOk) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.person, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data["name"] ?? "",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            ],
          ),
        ),

        /// Botones
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.check_circle,
                color: polizaOk && tarjetaOk ? Colors.green : Colors.grey,
              ),
              tooltip:
                  polizaOk && tarjetaOk ? "Aprobar registro" : "Faltan documentos",
              onPressed:
                  polizaOk && tarjetaOk ? () => _approveUser(userId, data) : null,
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              tooltip: "Rechazar registro",
              onPressed: () => _rejectUser(userId, data),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildUserInfo(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(Icons.email, data["email"]),
        _infoRow(Icons.phone, data["phone"]),
        if ((data["polizaUrl"] ?? "").isEmpty ||
            (data["tarjetaProfesionalUrl"] ?? "").isEmpty)
          Row(
            children: const [
              Icon(Icons.warning, color: Colors.red, size: 18),
              SizedBox(width: 6),
              Text(
                "Documentos faltantes",
                style: TextStyle(color: Colors.red),
              ),
            ],
          )
      ],
    );
  }

  Widget _infoRow(IconData icon, String? value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey),
        const SizedBox(width: 6),
        Expanded(child: Text(value ?? "")),
      ],
    );
  }

  /// ==========================================================
  /// APROBAR USUARIO
  /// ==========================================================
  Future<void> _approveUser(String id, Map<String, dynamic> data) async {
    final email = data["email"] ?? "";

    await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .update({"estado": "habilitado"});

    if (email.isNotEmpty) {
      await sendEmailToUser(email, "Cuenta aprobada",
          "Tu cuenta ha sido habilitada en doctorKinds.");
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Registro aprobado")));
  }

  /// ==========================================================
  /// RECHAZAR USUARIO
  /// ==========================================================
  Future<void> _rejectUser(String id, Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rechazar registro"),
        content: const Text("¿Eliminar el registro y todos sus archivos?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final storage = FirebaseStorage.instance;
    final urls = <String>[];

    void add(String? url) {
      if (url != null && url.isNotEmpty) urls.add(url);
    }

    add(data["polizaUrl"]);
    add(data["tarjetaProfesionalUrl"]);
    add(data["documentoIdentidadFrenteUrl"]);
    add(data["documentoIdentidadReversoUrl"]);

    if (data["documentos"] is List) {
      urls.addAll((data["documentos"] as List).whereType<String>());
    }

    for (final url in urls) {
      try {
        await storage.refFromURL(url).delete();
      } catch (_) {}
    }

    await FirebaseFirestore.instance.collection("users").doc(id).delete();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Registro eliminado")));
  }

  /// ==========================================================
  /// DIÁLOGO DE DOCUMENTOS
  /// ==========================================================
  void _openDocumentsDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Documentos de ${data['name']}"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _docButton(data["polizaUrl"], "Póliza", Icons.shield),
              _docButton(
                  data["tarjetaProfesionalUrl"], "Tarjeta Profesional", Icons.credit_card),
              if (data["documentos"] is List)
                ...List.generate(
                  (data["documentos"] as List).length,
                  (i) => _docButton(data["documentos"][i],
                      "Documento ${i + 1}", Icons.attach_file),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  Widget _docButton(String? url, String label, IconData icon) {
    if (url == null || url.isEmpty) return const SizedBox.shrink();

    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label),
      onTap: () => _openDocument(url, label),
    );
  }

  Future<void> _openDocument(String url, String label) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentViewerPage(url: url, title: label),
      ),
    );
    // Todos los archivos se intentan mostrar dentro de la app
  }

  /// ==========================================================
  /// SECCIÓN - HABILITADOS
  /// ==========================================================
  Widget _buildEnabledSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pediatras habilitados",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 3,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .where("type", isEqualTo: "pediatra")
                .where("estado", isEqualTo: "habilitado")
                .snapshots(),
            builder: (_, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text("No hay pediatras habilitados.")),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(data["name"] ?? ""),
                    subtitle: Text(data["email"] ?? ""),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
