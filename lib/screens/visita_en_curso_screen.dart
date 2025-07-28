import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'finalizar_visita_screen.dart';

class VisitaEnCursoScreen extends StatefulWidget {
  final String nombreAfiliado;
  final String numeroAfiliacion;
  final String cuitEmpresa;
  final String nombreEmpresa;

  const VisitaEnCursoScreen({
    super.key,
    required this.nombreAfiliado,
    required this.numeroAfiliacion,
    required this.cuitEmpresa,
    required this.nombreEmpresa,
  });

  @override
  State<VisitaEnCursoScreen> createState() => _VisitaEnCursoScreenState();
}

class _VisitaEnCursoScreenState extends State<VisitaEnCursoScreen> {
  late Timer _timer;
  int _seconds = 0;
  late DateTime _inicio;
  String _ubicacion = 'Obteniendo ubicación…';
  late String _idVisita;

  late Map<String, dynamic> _datosVisitaCompleta;

  @override
  void initState() {
    super.initState();

    _idVisita = DateTime.now().millisecondsSinceEpoch.toString();

    _verificarVisitaEnCurso();
  }

  Future<void> _verificarVisitaEnCurso() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: usuario no autenticado')),
      );
      Navigator.of(context).pop();
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('visitas')
        .where('estado', isEqualTo: 'en curso')
        .orderBy('fechaComienzo', descending: true)
        .limit(1)
        .get();

    if (doc.docs.isNotEmpty) {
      final data = doc.docs.first.data();
      _idVisita = data['idVisita'];
      _inicio = DateTime.parse(data['fechaComienzo']);
      setState(() {
        _ubicacion = data['ubicacionInicio'];
      });
    } else {
      _inicio = DateTime.now();
      final ok = await _obtenerUbicacion();
      if (ok) {
        await _guardarVisitaEnCurso();
      } else {
        _mostrarDialogoErrorUbicacion();
        return;
      }
    }

    // 🔷 Ahora sí: iniciamos el Timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _seconds = DateTime.now().difference(_inicio).inSeconds;
      });
    });

    debugPrint("✅ Visita en curso detectada/iniciada. _inicio=$_inicio");
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<bool> _obtenerUbicacion() async {
    try {
      debugPrint("🌍 solicitando ubicación…");

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _ubicacion = 'GPS desactivado. Actívalo para registrar la visita.');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _ubicacion = 'Permiso de ubicación denegado.');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _ubicacion =
            'Permiso de ubicación denegado permanentemente. Ve a Ajustes para habilitarlo.');
        return false;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout al obtener la ubicación');
        },
      );

      setState(() {
        _ubicacion =
            'Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)}';
      });

      debugPrint("📍 ubicación obtenida: $_ubicacion");
      return true;
    } catch (e) {
      debugPrint('🔥 Error al obtener ubicación: $e');

      // fallback para pruebas:
      setState(() => _ubicacion = 'Lat: -34.6037, Lng: -58.3816 (mock)');
      return true;
    }
  }

  void _mostrarDialogoErrorUbicacion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Ubicación no disponible'),
        content: Text(_ubicacion.isNotEmpty ? _ubicacion : 'No se pudo obtener la ubicación.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarVisitaEnCurso() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: usuario no autenticado')),
      );
      return;
    }

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      final dni = userDoc['dni'] ?? '';
      final matricula = userDoc['matricula'] ?? '';
      final email = userDoc['email'] ?? '';
      final nombre = userDoc['nombre'] ?? '';
      final apellido = userDoc['apellido'] ?? '';

      final nombreResponsable = '$nombre $apellido';

      final pacienteDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('empresas')
          .doc(widget.cuitEmpresa)
          .collection('pacientes')
          .doc(widget.numeroAfiliacion)
          .get();

      final celularAfiliado = pacienteDoc['celular'] ?? '';
      final tipoServicio = pacienteDoc['servicio'] ?? '';

      final data = {
        'idVisita': _idVisita,
        'estado': 'en curso',
        'fechaComienzo': _inicio.toIso8601String(),
        'nombreAfiliado': widget.nombreAfiliado,
        'numeroAfiliacion': widget.numeroAfiliacion,
        'celularAfiliado': celularAfiliado,
        'ubicacionInicio': _ubicacion,
        'dniResponsable': dni,
        'nombreResponsable': nombreResponsable,
        'matriculaResponsable': matricula,
        'emailResponsable': email,
        'tipoServicioPrestador': tipoServicio,
        'cuitEmpresaPrestadora': widget.cuitEmpresa,
        'nombreEmpresaPrestadora': widget.nombreEmpresa,
      };

      _datosVisitaCompleta = data;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('visitas')
          .doc(_idVisita)
          .set(data);

      await FirebaseFirestore.instance
          .collection('visitas_globales')
          .doc(_idVisita)
          .set({
        ...data,
        'uidProfesional': user.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visita iniciada correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar la visita: $e')),
      );
    }
  }

  Future<void> _finalizarVisita() async {
    final fin = DateTime.now();
    final duracion = _formatTime(_seconds);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _datosVisitaCompleta.addAll({
      'fechaFin': fin.toIso8601String(),
      'duracion': duracion,
      'estado': 'finalizada',
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('visitas')
          .doc(_idVisita)
          .set(_datosVisitaCompleta, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('visitas_globales')
          .doc(_idVisita)
          .set(_datosVisitaCompleta, SetOptions(merge: true));

      _timer.cancel();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FinalizarVisitaScreen(
            datosVisita: _datosVisitaCompleta,
          ),
        ),
      );
    } catch (e) {
      _timer.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al finalizar la visita: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 12),
            Container(
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
                  Text(
                    widget.nombreAfiliado,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'N° de afiliación: ${widget.numeroAfiliacion}',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _ubicacion,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Tiempo transcurrido:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              _formatTime(_seconds),
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _finalizarVisita,
              icon: const Icon(Icons.stop_circle, size: 28),
              label: const Text('Finalizar visita'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A99D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


