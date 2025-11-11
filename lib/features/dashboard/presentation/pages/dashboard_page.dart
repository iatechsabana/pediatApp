import 'package:flutter/material.dart';
import '../../../assistant/presentation/pages/assistant_page.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Panel de control'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined)),
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AssistantPage())),
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Asistente pediátrico',
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Row(
                children: [
                  const CircleAvatar(radius: 28, backgroundColor: AppColors.textWhite, child: Icon(Icons.person, color: AppColors.primary)),
                  const SizedBox(width: AppDimens.paddingMedium),
                  const Expanded(
                    child: Text('Hola, Usuario', style: TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            ListTile(leading: const Icon(Icons.dashboard), title: const Text('Inicio'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.person), title: const Text('Perfil'), onTap: () {}),
            ListTile(leading: const Icon(Icons.calendar_today), title: const Text('Citas'), onTap: () {}),
            const Spacer(),
            ListTile(leading: const Icon(Icons.logout), title: const Text('Cerrar sesión'), onTap: () {}),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // Header area with gradient and greeting
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.horizontalPadding, vertical: AppDimens.verticalPadding),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primaryLight, AppColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Buen día,', style: TextStyle(color: AppColors.inputHint, fontSize: 14)),
                          SizedBox(height: 4),
                          Text('Bienvenido al panel', style: TextStyle(color: AppColors.textWhite, fontSize: 20, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(AppDimens.paddingSmall),
                      decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge)),
                      child: const Icon(Icons.local_hospital_rounded, color: AppColors.inputIcon, size: 28),
                    ),
                  ],
                ),
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingLarge, vertical: AppDimens.paddingMedium),
                child: LayoutBuilder(builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left column: stats + quick actions
                            SizedBox(
                              width: constraints.maxWidth * 0.45,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildStatsRow(),
                                  const SizedBox(height: 12),
                                  _buildQuickActions(),
                                  const SizedBox(height: 12),
                                  Expanded(child: _buildRecentList()),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),
                            // Right column: main list or calendar
                            Expanded(child: _buildAppointmentsOverview()),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildStatsRow(),
                            const SizedBox(height: 12),
                            _buildQuickActions(),
                            const SizedBox(height: 12),
                            Expanded(child: _buildAppointmentsOverview()),
                            const SizedBox(height: 12),
                            SizedBox(height: mq.size.height * 0.28, child: _buildRecentList()),
                          ],
                        );
                }),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Nueva cita'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _statCard('Pacientes', '1.254', Icons.people_outline)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('Citas', '36', Icons.calendar_month_outlined)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('Mensajes', '7', Icons.chat_bubble_outline)),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge), boxShadow: [BoxShadow(color: AppColors.overlayLight, blurRadius: AppDimens.shadowBlur)]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(AppDimens.borderRadiusMedium)),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppDimens.paddingMedium),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: AppColors.textBlack54)), const SizedBox(height: 6), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))]),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Agregar paciente'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusMedium))),
          ),
        ),
        const SizedBox(width: AppDimens.paddingSmall),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.calendar_today_outlined),
            label: const Text('Agendar'),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary), foregroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusMedium))),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentList() {
    final items = List.generate(6, (i) => 'Nueva cita con Paciente ${i + 1} - ${9 + i}:00');
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingMedium),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Actividad reciente', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppDimens.paddingSmall),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 8),
              itemBuilder: (context, index) => ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.12), child: Icon(Icons.event_note, color: AppColors.primary)),
                title: Text(items[index]),
                subtitle: Text('Hace ${10 - index} min'),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildAppointmentsOverview() {
    final appointments = List.generate(8, (i) => {'time': '${8 + i}:00', 'name': 'Paciente ${i + 1}'});
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Próximas citas', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, idx) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: Text(appointments[idx]['time']!, style: const TextStyle(fontWeight: FontWeight.w700))),
                title: Text(appointments[idx]['name']!),
                trailing: IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
