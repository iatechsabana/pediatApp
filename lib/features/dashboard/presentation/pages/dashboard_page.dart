import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import '../../../assistant/presentation/pages/assistant_page.dart';
import 'request_service_page.dart';
import 'medical_history_page.dart';
import 'family_core_page.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import './_thread_comments_widget.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ============================================================
  //   Mock data (SUSTITUIR por datos reales desde Firebase)
  // ============================================================
  int hijosRegistrados = 2; // TODO: Reemplazar por valor real desde FamilyCorePage
  int creditosDisponibles = 50;
  int creditosUsadosMes = 7;
  double balance = 125000;
  double usoMensual = 86;

  // Las notas ahora se obtendrán en tiempo real desde Firestore

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ============================================================
      //   APP BAR SUPERIOR (con Chatbot + Notificaciones)
      // ============================================================
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        toolbarHeight: 44,
        title: const Text(
          "Panel de control",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: "Asistente pediátrico",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AssistantPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar sesión",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Cerrar sesión"),
                  content: const Text("¿Estás seguro que deseas cerrar sesión?"),
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
                try {
                  await FirebaseAuth.instance.signOut();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error al cerrar sesión: $e")),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),

      // ============================================================
      //   MENÚ LATERAL
      // ============================================================
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Row(
                children: const [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.textWhite,
                    child: Icon(Icons.person, color: AppColors.primary),
                  ),
                  SizedBox(width: AppDimens.paddingMedium),
                  Expanded(
                    child: Text(
                      'Hola, Usuario',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Inicio'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.history_edu),
              title: const Text('Antecedentes médicos'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MedicalHistoryPage()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.family_restroom),
              title: const Text('Núcleo familiar'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FamilyCorePage()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: const Text('Historias clínicas'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MedicalHistoryPage()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: const Text('Solicitar servicio'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RequestServicePage()),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),

      // ============================================================
      //   CUERPO PRINCIPAL DEL DASHBOARD
      // ============================================================
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMetricDashboard(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.family_restroom, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        "Hijos registrados: $hijosRegistrados",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildUsageCard(),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 340,
                    child: _buildThreadsWithComments(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //   ENCABEZADO DEL DASHBOARD
  // ============================================================
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Hola 👋",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              "Bienvenido al Panel",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //   MÉTRICAS PRINCIPALES
  // ============================================================
  Widget _buildMetricDashboard() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: _metricCard(
              "Hijos",
              "$hijosRegistrados",
              Icons.child_care_outlined,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 180,
            child: _metricCard(
              "Créditos",
              "$creditosDisponibles",
              Icons.monetization_on_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String titulo, String valor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  //   BALANCE + USO DE APLICACIÓN
  // ============================================================
  Widget _buildUsageCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Uso y balance",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _usageTile(
                  "Créditos usados este mes",
                  "$creditosUsadosMes",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _usageTile(
                  "Balance actual",
                  "\$${balance.toStringAsFixed(0)}",
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          LinearProgressIndicator(
            value: usoMensual / 100,
            color: AppColors.primary,
            backgroundColor: Colors.grey.shade300,
          ),

          const SizedBox(height: 6),

          Text(
            "Uso de la app este mes: $usoMensual%",
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _usageTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ============================================================
  //   NOTAS SOCIALES (TIMELINE)
  // ============================================================
  // Mostrar publicaciones de médicos (threads) y permitir solo comentar
  Widget _buildThreadsWithComments() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('threads').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final threads = snapshot.data?.docs ?? [];
        if (threads.isEmpty) {
          return const Center(child: Text('No hay publicaciones de médicos.'));
        }
        return ListView.builder(
          itemCount: threads.length,
          itemBuilder: (context, i) {
            final data = threads[i].data() as Map<String, dynamic>;
            final threadId = threads[i].id;
            final String author = data['authorName'] ?? 'Médico';
            final String content = data['content'] ?? '';
            DateTime? createdAt;
            if (data['createdAt'] is Timestamp) {
              createdAt = (data['createdAt'] as Timestamp).toDate();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.note_alt_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(author),
                  subtitle: Text(createdAt != null ? '${createdAt.day}/${createdAt.month}/${createdAt.year}' : ''),
                  isThreeLine: true,
                  trailing: null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Text(content, style: const TextStyle(fontSize: 15)),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 8, bottom: 8),
                  child: ThreadCommentsWidget(threadId: threadId),
                ),
                const Divider(),
              ],
            );
          },
        );
      },
    );
  }

// ...existing code...
}
