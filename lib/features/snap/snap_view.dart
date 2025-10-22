import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'add_expense.dart';

// A global variable to hold all available cameras
List<CameraDescription> cameras = [];

class SnapView extends StatefulWidget {
  const SnapView({super.key});

  @override
  State<SnapView> createState() => _SnapViewState();
}

class _SnapViewState extends State<SnapView> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // 1. Ensure 'cameras' list is populated
    try {
      if (cameras.isEmpty) {
        cameras = await availableCameras();
      }

      // 2. Select the first camera (usually the back camera)
      if (cameras.isNotEmpty) {
        final firstCamera = cameras.first;

        _controller = CameraController(
          firstCamera,
          ResolutionPreset.high, // Use a high resolution
          enableAudio: false, // We don't need audio for receipts
        );

        // 3. Initialize the controller
        _initializeControllerFuture = _controller!.initialize();

        // 4. Rebuild the widget once initialized
        if (mounted) {
          setState(() {});
        }
      } else {
        // Handle case where no cameras are available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras found on this device.')),
          );
        }
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller?.dispose();
    super.dispose();
  }

  void _onTakePicturePressed() async {
    try {
      // Ensure that the camera is initialized.
      await _initializeControllerFuture;

      // Attempt to take a picture and get the file `XFile` where it was saved.
      final image = await _controller!.takePicture();

      // If the picture was taken, you can navigate to a preview screen
      // or start the OCR process.
      // For now, let's just show a snackbar.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Picture saved to ${image.path}')),
        );
        // Example navigation:
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (context) => PreviewScreen(imagePath: image.path),
        // ));
      }
    } catch (e) {
      // If an error occurs, log the error to the console.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking picture: $e')),
        );
      }
    }
  }

  void _onManualEntryPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseManuallyScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // If the Future is complete, display the preview.
                if (_controller == null || !_controller!.value.isInitialized) {
                  return const Center(child: Text('Error: Camera not initialized.'));
                }
                // Use CameraPreview to display the camera feed.
                return Center(
                  child: CameraPreview(_controller!),
                );
              } else {
                // Otherwise, display a loading indicator.
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
            },
          ),

          // UI Overlay
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar (for safety area, could be an AppBar)
              Container(
                height: MediaQuery.of(context).padding.top,
                color: Colors.black.withOpacity(0.3),
              ),

              // Bottom Control Bar
              Container(
                height: 140,
                color: Colors.black.withOpacity(0.3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Manual Entry Button
                    InkWell(
                      onTap: _onManualEntryPressed,
                      borderRadius: BorderRadius.circular(30),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_note, color: Colors.white, size: 28),
                          SizedBox(height: 4),
                          Text(
                            'Manual Entry',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    // Shutter Button
                    InkWell(
                      onTap: _onTakePicturePressed,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                        ),
                      ),
                    ),

                    // Gallery/Flash (Placeholder)
                    InkWell(
                      onTap: () {
                        // Toggle flash or open gallery
                        bool isFlashOn = _controller?.value.flashMode == FlashMode.torch;
                        _controller?.setFlashMode(isFlashOn ? FlashMode.off : FlashMode.torch);
                        setState(() {}); // Update UI
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              _controller?.value.flashMode == FlashMode.torch
                                  ? Icons.flash_on
                                  : Icons.flash_off,
                              color: Colors.white,
                              size: 28
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Flash',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
