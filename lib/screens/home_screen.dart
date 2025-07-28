import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'empresa_screen.dart';
import 'add_empresa_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, String>> _userData;

  @override
  void initState() {
    super.initState();
    _userData = _fetchUserData();
  }

  Future<Map<String, String>> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      final nombre = userDoc['nombre'] ?? '';
      final apellido = userDoc['apellido'] ?? '';
      final dni = userDoc['dni'] ?? '';

      return {
        'nombre': '$nombre $apellido',
        'dni': dni,
      };
    } catch (e) {
      return {
        'nombre': 'Error',
        'dni': 'Error',
      };
    }
  }

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final empresasRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('empresas');

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFF00A99D)),
          tooltip: 'Cerrar sesión',
          onPressed: _cerrarSesion,
        ),
        title: Image.asset(
          'assets/images/logo-apross.png',
          height: 44,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bienvenido, prestador APROSS.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            FutureBuilder<Map<String, String>>(
              future: _userData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildUserCard(nombre: 'Cargando...', dni: '');
                }
                if (snapshot.hasError || snapshot.data == null || snapshot.data!['nombre'] == 'Error') {
                  return _buildUserCard(nombre: 'Error al cargar', dni: '');
                }

                final data = snapshot.data!;
                return _buildUserCard(nombre: data['nombre']!, dni: data['dni']!);
              },
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEmpresaScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add, color: Color(0xFF00A99D)),
                label: const Text(
                  'Añadir empresa',
                  style: TextStyle(
                    color: Color(0xFF00A99D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00A99D), width: 1.8),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Empresas cargadas:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: empresasRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No hay empresas. Añadí una.'));
                  }

                  final empresas = snapshot.data!.docs;

                  return ListView.separated(
                    itemCount: empresas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final empresa = empresas[index];
                      final nombre = empresa['nombre'];
                      final cuit = empresa['cuit'];

                      return Dismissible(
                        key: Key(cuit),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Eliminar empresa'),
                              content: Text(
                                  '¿Estás seguro de que querés eliminar la empresa "$nombre"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text(
                                    'Eliminar',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) async {
                          await empresasRef.doc(cuit).delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Empresa "$nombre" eliminada')),
                          );
                        },
                        child: Container(
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
                          child: ListTile(
                            title: Text(
                              nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text('CUIT: $cuit'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EmpresaScreen(
                                    nombreEmpresa: nombre,
                                    cuitEmpresa: cuit,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard({required String nombre, required String dni}) {
    return Container(
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
          const Text(
            'Nombre y Apellido',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            nombre,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Text(
            'DNI',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            dni,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
