import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPacienteScreen extends StatefulWidget {
  const AddPacienteScreen({super.key});

  @override
  State<AddPacienteScreen> createState() => _AddPacienteScreenState();
}

class _AddPacienteScreenState extends State<AddPacienteScreen> {
  final afiliacionController = TextEditingController();
  final celularController = TextEditingController();

  final List<String> servicios = [
    'Médico',
    'Enfermería',
    'Cuidado',
    'Kinesiología',
    'Psiquiatría',
    'Psicología',
    'Fonoaudiología',
    'Estimulación temprana'
  ];

  String? servicioSeleccionado;
  bool noIndicaTelefono = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>;
    final cuitEmpresa = args['cuitEmpresa']!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Añadir Paciente',
          style: TextStyle(color: Color(0xFF00A99D)),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF00A99D)),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAfiliacionField(),
              const SizedBox(height: 16),
              _buildCelularField(),
              _buildNoIndicaCheckbox(),
              const SizedBox(height: 16),
              _buildServicioDropdown(),
              const SizedBox(height: 36),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A99D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : () => _addPaciente(cuitEmpresa),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Agregar Paciente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAfiliacionField() {
    return TextField(
      controller: afiliacionController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Número de Afiliación',
        prefixIcon: Icon(Icons.credit_card, color: Color(0xFF00A99D)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        helperText: 'Ingresá los 12 números sin guiones ni espacios.',
      ),
    );
  }

  Widget _buildCelularField() {
    return TextField(
      controller: celularController,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(
        labelText: 'Celular',
        prefixIcon: Icon(Icons.phone, color: Color(0xFF00A99D)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      enabled: !noIndicaTelefono,
    );
  }

  Widget _buildNoIndicaCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: noIndicaTelefono,
          onChanged: (val) {
            setState(() {
              noIndicaTelefono = val ?? false;
              if (noIndicaTelefono) celularController.clear();
            });
          },
        ),
        const Text('No indica teléfono')
      ],
    );
  }

  Widget _buildServicioDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Tipo de servicio',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      value: servicioSeleccionado,
      items: servicios
          .map((servicio) => DropdownMenuItem(
                value: servicio,
                child: Text(servicio),
              ))
          .toList(),
      onChanged: (valor) {
        setState(() {
          servicioSeleccionado = valor;
        });
      },
    );
  }

  Future<void> _addPaciente(String cuitEmpresa) async {
    final numeroAfiliado = afiliacionController.text.trim();

    if (!RegExp(r'^\d{12}$').hasMatch(numeroAfiliado)) {
      _showMessage('El número de afiliado debe ser exactamente 12 números.');
      return;
    }

    if (!noIndicaTelefono && celularController.text.trim().isEmpty) {
      _showMessage('Ingresá un número de celular o seleccioná "No indica".');
      return;
    }

    if (servicioSeleccionado == null) {
      _showMessage('Seleccioná un tipo de servicio.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Usuario no autenticado.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('afiliados')
          .doc(numeroAfiliado)
          .get();

      if (!doc.exists) {
        _showMessage(
            'Número de afiliado no válido. Verificá e intentá de nuevo.');
        return;
      }

      final nombreAfiliado = doc['nombre'] ?? '---';
      final celular =
          noIndicaTelefono ? 'No indica' : celularController.text.trim();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('empresas')
          .doc(cuitEmpresa)
          .collection('pacientes')
          .doc(numeroAfiliado)
          .set({
        'nombre': nombreAfiliado,
        'afiliacion': numeroAfiliado,
        'servicio': servicioSeleccionado,
        'celular': celular,
      });

      if (!mounted) return;

      _showMessage('Paciente agregado exitosamente.');
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
