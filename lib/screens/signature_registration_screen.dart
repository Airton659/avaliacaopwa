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
import '../utils/password_helper.dart';

class SignatureRegistrationScreen extends StatefulWidget {
  final String userId;

  const SignatureRegistrationScreen({
    super.key,
    required this.userId,
  });

  @override
  State<SignatureRegistrationScreen> createState() => _SignatureRegistrationScreenState();
}

class _SignatureRegistrationScreenState extends State<SignatureRegistrationScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _passwordController = TextEditingController();
  
  Uint8List? _photoBytes;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _signatureController.dispose();
    _passwordController.dispose();
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

  Future<void> _salvarAssinaturaMestra() async {
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

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, confirme sua senha.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 0. Validar Senha
      final userDoc = await FirebaseFirestore.instance.collection('comissao').doc(widget.userId).get();
      if (!userDoc.exists) throw Exception('Usuário não encontrado.');
      
      final storedHash = userDoc.data()?['senha'] as String?;
      if (storedHash != null && !PasswordHelper.checkPassword(_passwordController.text, storedHash)) {
         throw Exception('Senha incorreta.');
      }

      // 1. Capturar Assinatura
      final signatureBytes = await _signatureController.toPngBytes();
      if (signatureBytes == null) throw Exception('Erro ao gerar imagem da assinatura');

      // 2. Capturar Metadados
      final metadata = await _getMetadata();

      // 3. Uploads
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Upload Assinatura
      final signatureRef = FirebaseStorage.instance
          .ref()
          .child('signatures/president_${widget.userId}_${timestamp}_signature.png');
      await signatureRef.putData(signatureBytes);
      final signatureUrl = await signatureRef.getDownloadURL();

      // Upload Foto
      final photoRef = FirebaseStorage.instance
          .ref()
          .child('signatures/president_${widget.userId}_${timestamp}_face.jpg');
      await photoRef.putData(_photoBytes!);
      final photoUrl = await photoRef.getDownloadURL();
      
      // 4. Salvar no Firestore
      metadata['photoUrl'] = photoUrl;
      metadata['registeredAt'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance.collection('comissao').doc(widget.userId).update({
        'signatureUrl': signatureUrl,
        'signatureMetadata': metadata,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assinatura Mestra registrada com sucesso!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Assinatura da Presidência'),
        backgroundColor: Colors.amber.shade700,
      ),
      body: _isProcessing 
        ? const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Registrando assinatura mestra...'),
              Text('Gerando evidências legais...', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    border: Border.all(color: Colors.amber.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.gavel, color: Colors.amber),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Atenção: Esta assinatura será utilizada oficialmente em todos os relatórios da comissão. O processo inclui captura de foto e dados do dispositivo para validade jurídica.',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // 1. Senha
                const Text('1. Confirmação de Identidade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirme sua senha atual',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                
                const SizedBox(height: 24),

                // 2. Foto
                const Text('2. Registro Fotográfico (Evidência)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _photoBytes != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(_photoBytes!, fit: BoxFit.cover),
                            ),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: FloatingActionButton.small(
                                onPressed: _tirarFoto,
                                backgroundColor: Colors.white,
                                child: const Icon(Icons.refresh, color: Colors.black),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _tirarFoto,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Capturar Rosto'),
                              ),
                            ],
                          ),
                        ),
                ),

                const SizedBox(height: 24),
                
                // 3. Assinatura
                const Text('3. Assinatura Digital', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Signature(
                      controller: _signatureController,
                      height: 200,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _signatureController.clear(),
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Limpar'),
                      style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: _salvarAssinaturaMestra,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                  ),
                  child: const Text(
                    'REGISTRAR ASSINATURA OFICIAL',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
