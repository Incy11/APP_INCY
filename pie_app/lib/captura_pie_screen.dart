import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

enum FootSide { left, right }

class CapturaPieScreen extends StatefulWidget {
  const CapturaPieScreen({super.key});

  @override
  State<CapturaPieScreen> createState() => _CapturaPieScreenState();
}

class _CapturaPieScreenState extends State<CapturaPieScreen> {
  CameraController? _controller;
  FootSide selectedFoot = FootSide.left;
  bool isLoading = true;
  bool pieDetectado = false;
  int cuentaRegresiva = 0;
  bool tomandoFoto = false;

  late ObjectDetector _objectDetector;

  @override
  void initState() {
    super.initState();
    _inicializarDetector();
    inicializarCamara();
  }

  void _inicializarDetector() {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: false,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<void> inicializarCamara() async {
    final cameras = await availableCameras();

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _controller!.initialize();

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    // Analizar cada frame de la cámara
    _controller!.startImageStream((CameraImage image) async {
      if (tomandoFoto) return;
      await _analizarImagen(image);
    });
  }

  Future<void> _analizarImagen(CameraImage image) async {
    try {
      final inputImage = _convertirImagen(image);
      if (inputImage == null) return;

      final objects = await _objectDetector.processImage(inputImage);

      // Buscar si hay algo detectado en el centro de la pantalla
      bool hayObjeto = objects.isNotEmpty;

      if (hayObjeto && !pieDetectado && !tomandoFoto) {
        setState(() {
          pieDetectado = true;
        });
        await _iniciarCuentaRegresiva();
      } else if (!hayObjeto) {
        setState(() {
          pieDetectado = false;
          cuentaRegresiva = 0;
        });
      }
    } catch (e) {
      debugPrint('Error al analizar: $e');
    }
  }

  InputImage? _convertirImagen(CameraImage image) {
    final camera = _controller!.description;
    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Future<void> _iniciarCuentaRegresiva() async {
    for (int i = 3; i >= 1; i--) {
      if (!mounted || !pieDetectado) return;
      setState(() {
        cuentaRegresiva = i;
      });
      await Future.delayed(const Duration(seconds: 1));
    }
    if (pieDetectado && mounted) {
      await tomarFoto();
    }
  }

  Future<void> tomarFoto() async {
    if (tomandoFoto) return;
    setState(() {
      tomandoFoto = true;
      cuentaRegresiva = 0;
    });

    try {
      await _controller!.stopImageStream();
      final image = await _controller!.takePicture();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewFotoScreen(
            imagePath: image.path,
            footSide: selectedFoot,
          ),
        ),
      ).then((_) async {
        // Al regresar, reiniciar la cámara
        setState(() {
          tomandoFoto = false;
          pieDetectado = false;
          cuentaRegresiva = 0;
        });
        await _controller!.startImageStream((CameraImage image) async {
          if (tomandoFoto) return;
          await _analizarImagen(image);
        });
      });
    } catch (e) {
      debugPrint('Error al tomar foto: $e');
      setState(() {
        tomandoFoto = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _objectDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colorPrincipal = Color(0xFF6A93BE);

    if (isLoading || _controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Cámara de fondo
          SizedBox.expand(
            child: CameraPreview(_controller!),
          ),

          // 2. Silueta del pie — cambia a verde cuando detecta
          Positioned(
            top: 100,
            bottom: 120,
            left: -80,
            right: -80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    pieDetectado
                        ? Colors.green.withOpacity(0.35)
                        : Colors.blue.withOpacity(0.25),
                    BlendMode.srcATop,
                  ),
                  child: Image.asset(
                    selectedFoot == FootSide.left
                        ? 'assets/pie_izq.png'
                        : 'assets/pie_der.png',
                    fit: BoxFit.contain,
                    color: pieDetectado ? Colors.green : Colors.white,
                    colorBlendMode: BlendMode.modulate,
                  ),
                ),
                Image.asset(
                  selectedFoot == FootSide.left
                      ? 'assets/pie_izq.png'
                      : 'assets/pie_der.png',
                  fit: BoxFit.contain,
                  color: pieDetectado ? Colors.green : Colors.white,
                  colorBlendMode: BlendMode.modulate,
                ),
              ],
            ),
          ),

          // 3. Cuenta regresiva en el centro
          if (cuentaRegresiva > 0)
            Center(
              child: Text(
                '$cuentaRegresiva',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 100,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 20, color: Colors.black)],
                ),
              ),
            ),

          // 4. Textos arriba
          Positioned(
            top: 45,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Text(
                  selectedFoot == FootSide.left
                      ? 'Pie izquierdo'
                      : 'Pie derecho',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pieDetectado
                      ? '¡Pie detectado! Mantén quieto...'
                      : 'Coloca el pie dentro del marco',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: pieDetectado ? Colors.greenAccent : Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                ),
              ],
            ),
          ),

          // 5. Botones izquierdo / derecho
          Positioned(
            bottom: 110,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedFoot = FootSide.left;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrincipal,
                    ),
                    child: const Text('Izquierdo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedFoot = FootSide.right;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrincipal,
                    ),
                    child: const Text('Derecho'),
                  ),
                ),
              ],
            ),
          ),

          // 6. Botón tomar foto manual
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: tomandoFoto ? null : tomarFoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tomar foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrincipal,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PreviewFotoScreen extends StatelessWidget {
  final String imagePath;
  final FootSide footSide;

  const PreviewFotoScreen({
    super.key,
    required this.imagePath,
    required this.footSide,
  });

  @override
  Widget build(BuildContext context) {
    final footText =
        footSide == FootSide.left ? 'Pie izquierdo' : 'Pie derecho';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisión de imagen'),
        backgroundColor: const Color(0xFF6A93BE),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Expanded(
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              footText,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Verifica que la imagen sea clara, que el pie esté completo, centrado y sin sombras fuertes.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const QualityChecklist(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Repetir foto'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Foto aceptada para historial'),
                        ),
                      );
                    },
                    child: const Text('Usar foto'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QualityChecklist extends StatelessWidget {
  const QualityChecklist({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      'Se observa todo el pie',
      'La imagen no está borrosa',
      'No hay sombras fuertes',
      'El fondo es claro',
      'El pie está centrado',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF6A93BE),
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(item)),
            ],
          ),
        );
      }).toList(),
    );
  }
}