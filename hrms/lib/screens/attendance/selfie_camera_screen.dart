import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../config/app_colors.dart';

/// Selfie-only camera screen. Uses front camera only; no camera switch.
/// Pops with [File] on success, null on cancel/error.
class SelfieCameraScreen extends StatefulWidget {
  const SelfieCameraScreen({super.key});

  @override
  State<SelfieCameraScreen> createState() => _SelfieCameraScreenState();
}

class _SelfieCameraScreenState extends State<SelfieCameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      final front = _cameras.where((c) => c.lensDirection == CameraLensDirection.front).toList();
      if (front.isEmpty) {
        setState(() {
          _error = 'Front camera not found.';
          _isInitialized = true;
        });
        return;
      }
      final frontCamera = front.first;
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _error = 'Could not open camera. Please try again.';
      });
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final XFile file = await _controller!.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(File(file.path));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCapturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capture failed. Please try again.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Take selfie'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: !_isInitialized
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('OK', style: TextStyle(color: AppColors.primary)),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_controller!),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 32,
                        child: Center(
                          child: Material(
                            color: Colors.white.withOpacity(0.3),
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: _isCapturing ? null : _capture,
                              customBorder: const CircleBorder(),
                              child: const SizedBox(width: 72, height: 72, child: Icon(Icons.camera_alt, size: 40, color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
