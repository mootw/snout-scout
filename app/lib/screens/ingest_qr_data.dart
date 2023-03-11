import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_vision/qr_code_vision.dart';


class IngestQRDataPage extends StatefulWidget {
  const IngestQRDataPage({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<IngestQRDataPage> createState() => _IngestQRDataPageState();
}

class _IngestQRDataPageState extends State<IngestQRDataPage> {
  CameraController? controller;

  @override
  void initState() {
    super.initState();
    () async {
      if(widget.cameras.isEmpty) {
        return;
      }
      controller = CameraController(widget.cameras[0], ResolutionPreset.max);
      controller!.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      }).catchError((Object e) {
        if (e is CameraException) {
          switch (e.code) {
            case 'CameraAccessDenied':
              // Handle access errors here.
              break;
            default:
              // Handle other errors here.
              break;
          }
        }
      });
    }();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qrCode = QrCode();

    return Scaffold(
      appBar: AppBar(title: const Text('QR Code ingest')),
      body: controller?.value.isInitialized == false
          ? Text("No camera feed")
          : SizedBox(width: 200, height: 200, child: CameraPreview(controller!)),
    );
  }
}
