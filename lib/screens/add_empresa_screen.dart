import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEmpresaScreen extends StatefulWidget {
  const AddEmpresaScreen({super.key});

  @override
  State<AddEmpresaScreen> createState() => _AddEmpresaScreenState();
}

class _AddEmpresaScreenState extends State<AddEmpresaScreen> {
  final cuitController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Añadir Empresa',
          style: TextStyle(color: Color(0xFF00A99D)),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF00A99D)),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: cuitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CUIT de la Empresa',
                prefixIcon: Icon(Icons.numbers, color: Color(0xFF00A99D)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
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
              onPressed: _isLoading ? null : _addEmpresa,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Agregar Empresa'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addEmpresa() async {
    final cuit = cuitController.text.trim();

    if (cuit.isEmpty) {
      _showMessage('Completá el CUIT');
      return;
    }

    if (!RegExp(r'^\d{11}$').hasMatch(cuit)) {
      _showMessage('El CUIT debe tener 11 dígitos numéricos');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage('Usuario no autenticado');
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('empresasvalidas')
          .doc(cuit)
          .get();

      if (!doc.exists) {
        _showMessage('CUIT no válido. Ingrese un CUIT autorizado.');
        return;
      }

      final nombre = doc['nombre'];

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('empresas')
          .doc(cuit)
          .set({
        'nombre': nombre,
        'cuit': cuit,
      });

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
