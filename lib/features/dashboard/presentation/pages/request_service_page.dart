import 'package:flutter/material.dart';
import 'specialist_list_page.dart';

class RequestServicePage extends StatelessWidget {
  const RequestServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Servicio'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Elige cómo deseas solicitar el servicio:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _serviceCard(
              context,
              icon: Icons.video_call,
              title: 'Teleconsulta',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SpecialistListPage(service: 'telemedicina'),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _serviceCard(
              context,
              icon: Icons.local_hospital,
              title: 'Consultorio',
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SpecialistListPage(service: 'consultorio'),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _serviceCard(
              context,
              icon: Icons.home,
              title: 'Domicilio',
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SpecialistListPage(service: 'domicilio'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

  }

  Widget _serviceCard(BuildContext context, {required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    String legend = '';
    if (title == 'Chat con especialista') {
      legend = 'Envía mensajes y recibe orientación rápida de un pediatra.';
    } else if (title == 'Teleconsulta') {
      legend = 'Solicita una videollamada para atención médica remota.';
    } else if (title == 'Contactar especialista') {
      legend = 'Busca y contacta a pediatras registrados en la plataforma.';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
          decoration: BoxDecoration(
            color: color.withOpacity(0.09),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.35), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: color.withOpacity(0.22),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: color,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                legend,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: color.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
