import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final matriculaController = TextEditingController();
  final dniController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  String capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registro de Profesional',
          style: TextStyle(color: Color(0xFF00A99D)),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF00A99D)),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  controller: emailController,
                  label: 'Email',
                  icon: Icons.email,
                  validator: (v) {
                    if (v!.isEmpty) return 'Ingrese su email';
                    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(v)) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
  controller: nombreController,
  label: 'Nombre',
  icon: Icons.person,
  validator: (v) => v!.isEmpty ? 'Ingrese su nombre' : null,
  onChanged: (value) {
    final capitalized = capitalize(value);
    if (value != capitalized) {
      nombreController.value = TextEditingValue(
        text: capitalized,
        selection: TextSelection.collapsed(offset: capitalized.length),
      );
    }
  },
),

                const SizedBox(height: 16),
                _buildTextField(
  controller: apellidoController,
  label: 'Apellido',
  icon: Icons.person_outline,
  validator: (v) => v!.isEmpty ? 'Ingrese su apellido' : null,
  onChanged: (value) {
    final capitalized = capitalize(value);
    if (value != capitalized) {
      apellidoController.value = TextEditingValue(
        text: capitalized,
        selection: TextSelection.collapsed(offset: capitalized.length),
      );
    }
  },
),

                const SizedBox(height: 16),
                _buildTextField(
  controller: matriculaController,
  label: 'Matrícula',
  icon: Icons.badge,
  keyboardType: TextInputType.number,
  validator: (v) {
    if (v == null || v.isEmpty) return 'Ingrese matrícula';
    if (!RegExp(r'^\d{4,8}$').hasMatch(v)) return 'Debe tener entre 4 y 8 números';
    return null;
  },
),
const SizedBox(height: 4),
const Text(
  'Si no cuenta con una, ingrese 0000',
  style: TextStyle(fontSize: 12, color: Colors.grey),
),
const SizedBox(height: 12),

                _buildTextField(
                  controller: dniController,
                  label: 'Número de DNI',
                  icon: Icons.perm_identity,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v!.isEmpty) return 'Ingrese DNI';
                    if (v.length < 7 || v.length > 8) return 'DNI inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF00A99D)),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF00A99D),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v!.isEmpty) return 'Ingrese contraseña';
                    if (v.length < 8) return 'Mínimo 8 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF00A99D)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: (v) {
                    if (v != passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
const Text(
  'Por favor, verificá que todos los datos sean correctos antes de registrarte.',
  style: TextStyle(fontSize: 13, color: Colors.grey),
  textAlign: TextAlign.center,
),
const SizedBox(height: 16),
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
  onPressed: _isLoading ? null : _register,
  child: _isLoading
      ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
      : const Text('Registrar'),
),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
  void Function(String)? onChanged, // 👈 AÑADIDO
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF00A99D)),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    validator: validator,
    onChanged: onChanged, // 👈 IMPLEMENTADO
  );
}


  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final nombre = capitalize(nombreController.text.trim());
final apellido = capitalize(apellidoController.text.trim());

await FirebaseFirestore.instance
    .collection('users')
    .doc(userCredential.user!.uid)
    .set({
  'email': emailController.text.trim(),
  'nombre': nombre,
  'apellido': apellido,
  'matricula': matriculaController.text.trim(),
  'dni': dniController.text.trim(),
});


      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro exitoso')),
      );
      Navigator.pop(context);
    } catch (e) {
  if (!mounted) return;

  String mensaje = 'Ocurrió un error inesperado';

  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'email-already-in-use':
        mensaje = 'Este email ya está registrado.';
        break;
      case 'invalid-email':
        mensaje = 'El email ingresado no es válido.';
        break;
      case 'weak-password':
        mensaje = 'La contraseña es muy débil (mínimo 8 caracteres).';
        break;
      case 'operation-not-allowed':
        mensaje = 'Registro deshabilitado. Contacte al administrador.';
        break;
      default:
        mensaje = e.message ?? 'Error desconocido';
    }
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(mensaje)),
  );
}
 finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
