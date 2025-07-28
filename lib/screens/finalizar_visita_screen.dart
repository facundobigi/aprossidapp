import 'package:flutter/material.dart';
import 'home_screen.dart';

class FinalizarVisitaScreen extends StatelessWidget {
  final Map<String, dynamic> datosVisita;

  const FinalizarVisitaScreen({super.key, required this.datosVisita});

  @override
  Widget build(BuildContext context) {
    final inicio = datosVisita['fechaComienzo'] ?? '---';
    final fin = datosVisita['fechaFin'] ?? '---';
    final duracion = datosVisita['duracion'] ?? '---';
    final ubicacion = datosVisita['ubicacionInicio'] ?? '---';

    final nombreAfiliado = datosVisita['nombreAfiliado'] ?? '---';
    final numeroAfiliacion = datosVisita['numeroAfiliacion'] ?? '---';
    final celularAfiliado = datosVisita['celularAfiliado'] ?? '---';

    final nombreResponsable = datosVisita['nombreResponsable'] ?? '---';
    final dniResponsable = datosVisita['dniResponsable'] ?? '---';
    final matriculaResponsable = datosVisita['matriculaResponsable'] ?? '---';
    final emailResponsable = datosVisita['emailResponsable'] ?? '---';

    final tipoServicio = datosVisita['tipoServicioPrestador'] ?? '---';
    final nombreEmpresa = datosVisita['nombreEmpresaPrestadora'] ?? '---';
    final cuitEmpresa = datosVisita['cuitEmpresaPrestadora'] ?? '---';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF00A99D)),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Visita finalizada con éxito',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('📄 Información del paciente'),
                      _infoRow('Afiliado', nombreAfiliado),
                      _infoRow('Afiliación', numeroAfiliacion),
                      _infoRow('Celular', celularAfiliado),
                      const SizedBox(height: 12),

                      _sectionTitle('📄 Datos de la visita'),
                      _infoRow('Inicio', inicio),
                      _infoRow('Fin', fin),
                      _infoRow('Duración', duracion),
                      _infoRow('Ubicación', ubicacion),
                      const SizedBox(height: 12),

                      _sectionTitle('📄 Responsable'),
                      _infoRow('Nombre', nombreResponsable),
                      _infoRow('DNI', dniResponsable),
                      _infoRow('Matrícula', matriculaResponsable),
                      _infoRow('Email', emailResponsable),
                      const SizedBox(height: 12),

                      _sectionTitle('📄 Empresa y servicio'),
                      _infoRow('Empresa', nombreEmpresa),
                      _infoRow('CUIT', cuitEmpresa),
                      _infoRow('Tipo de servicio', tipoServicio),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A99D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Volver al inicio'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
