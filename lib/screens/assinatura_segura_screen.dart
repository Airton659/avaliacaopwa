import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:signature/signature.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // for kIsWeb

class AssinaturaSeguraScreen extends StatefulWidget {
  final List<String> evaluationIds;
  final String userId;

  const AssinaturaSeguraScreen({
    super.key,
    required this.evaluationIds,
    required this.userId,
  });

  @override
  State<AssinaturaSeguraScreen> createState() => _AssinaturaSeguraScreenState();
}

class _AssinaturaSeguraScreenState extends State<AssinaturaSeguraScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  final ImagePicker _picker = ImagePicker();
  Uint8List? _photoBytes;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _tirarFoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 50,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _photoBytes = bytes;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao capturar foto: $e';
      });
    }
  }

  Future<Map<String, dynamic>> _getMetadata() async {
    final metadata = <String, dynamic>{
      'timestamp': FieldValue.serverTimestamp(),
    };

    // 1. Geolocalização
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
        final position = await Geolocator.getCurrentPosition();
        metadata['latitude'] = position.latitude;
        metadata['longitude'] = position.longitude;
      }
    } catch (e) {
      metadata['geo_error'] = e.toString();
    }

    // 2. IP Externo
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org?format=json'));
      if (response.statusCode == 200) {
        final body = response.body; 
        final ipStart = body.indexOf('"ip":"') + 6;
        final ipEnd = body.indexOf('"', ipStart);
        if (ipStart > 6 && ipEnd > ipStart) {
            metadata['ip'] = body.substring(ipStart, ipEnd);
        }
      }
    } catch (e) {
      metadata['ip_error'] = e.toString();
    }

    // 3. Device Info
    final deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      final webInfo = await deviceInfo.webBrowserInfo;
      metadata['device'] = '${webInfo.browserName} ${webInfo.appVersion} (${webInfo.userAgent})';
    } 

    return metadata;
  }

  Future<void> _finalizarAssinatura() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, assine no campo indicado.')),
      );
      return;
    }

    if (_photoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, tire uma foto para confirmar sua identidade.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 1. Capturar Assinatura
      final signatureBytes = await _signatureController.toPngBytes();
      if (signatureBytes == null) throw Exception('Erro ao gerar imagem da assinatura');

      // 2. Capturar Metadados (Foto já temos em _photoBytes)
      final metadata = await _getMetadata();

      // 4. Batch Process
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final signatureRef = FirebaseStorage.instance
          .ref()
          .child('signatures/${widget.userId}_${timestamp}_signature.png');
      await signatureRef.putData(signatureBytes);
      final signatureUrl = await signatureRef.getDownloadURL();

      final photoRef = FirebaseStorage.instance
          .ref()
          .child('signatures/${widget.userId}_${timestamp}_face.jpg');
      await photoRef.putData(_photoBytes!);
      final photoUrl = await photoRef.getDownloadURL();
      
      final batch = FirebaseFirestore.instance.batch();

      for (final evalId in widget.evaluationIds) {
        final docRef = FirebaseFirestore.instance.collection('evaluations').doc(evalId);
        batch.update(docRef, {
          'status': 'concluida',
          'signatureUrl': signatureUrl, // Assinatura Gestor
          'managerPhotoUrl': photoUrl,
          'managerSignatureMetadata': metadata,
          'managerSignedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avaliações assinadas com sucesso!')),
        );
        Navigator.pop(context, true); // Retorna true para atualizar lista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao finalizar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assinatura Segura do Gestor')),
      body: _isProcessing 
        ? const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processando assinatura segura...'),
            ],
          ))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Você está assinando ${widget.evaluationIds.length} avaliação(ões).',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Câmera / Foto
                const Text('1. Confirmação Visual (Foto)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    color: Colors.grey.shade100,
                  ),
                  child: _photoBytes != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(_photoBytes!, fit: BoxFit.cover),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: FloatingActionButton(
                                mini: true,
                                onPressed: _tirarFoto,
                                child: const Icon(Icons.refresh),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _tirarFoto,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Tirar Foto de Rosto'),
                              ),
                              if (_errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                                )
                            ],
                          ),
                        ),
                ),
                
                const SizedBox(height: 20),
                
                // Assinatura Canvas
                const Text('2. Assinatura Digital', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                  child: Signature(
                    controller: _signatureController,
                    height: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _signatureController.clear(),
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpar Assinatura'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], foregroundColor: Colors.black),
                ),

                const SizedBox(height: 30),
                
                ElevatedButton(
                  onPressed: _finalizarAssinatura,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'CONFIRMAR E FINALIZAR',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
