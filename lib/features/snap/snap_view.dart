import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../navigation/nav_manager.dart';
import '../../services/file_pick_service.dart';
import '../processing_receipt/processing_receipt.dart';
import 'add_expense.dart';
import 'widget/file_picker_sheet.dart';

// A global variable to hold all available cameras
List<CameraDescription> cameras = [];

class SnapView extends StatefulWidget {
  const SnapView({super.key});

  @override
  State<SnapView> createState() => _SnapViewState();
}

class _SnapViewState extends State<SnapView> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isShutterPressed = false; // State for shutter animation
  bool _isDisposing = false; // Flag to prevent operations during disposal
  bool _isPermissionDenied = false;

  // --- ADDED: Instantiate the service ---
  final FilePickerService _filePickerService = FilePickerService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _disposeCamera() async {
    if (_isDisposing || _controller == null) return;
    _isDisposing = true;
    final controller = _controller;
    _controller = null;
    _initializeControllerFuture = null;

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (controller != null && controller.value.isInitialized) {
        await controller.dispose().timeout(const Duration(seconds: 1));
      }
    } catch (e) {
      debugPrint('Camera disposal error: $e');
    } finally {
      _isDisposing = false;
      if (mounted) setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_isDisposing) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      if (_controller == null &&
          _initializeControllerFuture == null &&
          !_isDisposing) {
        _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (_initializeControllerFuture != null || !mounted || _isDisposing) return;

    try {
      if (cameras.isEmpty) {
        cameras = await availableCameras();
      }

      if (cameras.isNotEmpty && mounted) {
        final firstCamera = cameras.first;

        if (_controller != null) {
          await _disposeCamera();
          await Future.delayed(const Duration(milliseconds: 200));
        }

        _controller = CameraController(
          firstCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        _initializeControllerFuture = _controller!
            .initialize()
            .then((_) {
              if (mounted) {
                setState(() {
                  _isPermissionDenied = false; // Reset on success
                });
              }
            })
            .catchError((e) {
              if (e is CameraException) {
                switch (e.code) {
                  case 'CameraAccessDenied':
                    if (mounted) setState(() => _isPermissionDenied = true);
                    break;
                  default:
                    // _showErrorSnackBar('Camera error: ${e.description}');
                    break;
                }
              }
              _controller = null;
              _initializeControllerFuture = null;
            });
      }
    } catch (e) {
      // _showErrorSnackBar('Error: $e');
      _controller = null;
      _initializeControllerFuture = null;
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposing = true;
    if (_controller != null) {
      _controller!.dispose();
    }
    super.dispose();
  }

  // ... (_onTakePicturePressed remains the same) ...
  void _onTakePicturePressed() async {
    if (_isDisposing || _controller == null) return;

    try {
      if (!_controller!.value.isInitialized) return;
    } catch (e) {
      return; // Controller is in bad state
    }

    if (mounted && !_isDisposing) {
      setState(() {
        _isShutterPressed = true;
      });
    }

    try {
      await _initializeControllerFuture;

      if (_isDisposing || _controller == null) return;

      final image = await _controller!.takePicture();

      if (mounted && !_isDisposing) {
        NavigationManager.push(
          context,
          ProcessingReceiptScreen(imagePath: image.path),
          type: TransitionType.slideFromBottom,
        );
      }
    } catch (e) {
      // if (mounted && !_isDisposing) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Error taking picture: $e')),
      //   );
      // }
    }

    // We might not come back here, but reset if we do
    if (mounted && !_isDisposing) {
      setState(() {
        _isShutterPressed = false;
      });
    }
  }

  // ... (_onManualEntryPressed remains the same) ...
  void _onManualEntryPressed() async {
    // ... (This function remains the same as before)
    HapticFeedback.lightImpact();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.85,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: AddExpenseManuallyScreen(),
          );
        },
      ),
    );
  }

  // ... (_toggleFlash remains the same) ...
  void _toggleFlash() {
    HapticFeedback.lightImpact();
    if (_isDisposing || _controller == null) return;

    try {
      if (!_controller!.value.isInitialized) return;
      final bool isFlashOn = _controller!.value.flashMode == FlashMode.torch;
      _controller!.setFlashMode(isFlashOn ? FlashMode.off : FlashMode.torch);
      if (mounted && !_isDisposing) {
        setState(() {});
      }
    } catch (e) {
      // Ignore errors - controller might be disposing
    }
  }

  // --- UPDATED ---
  /// Shows the bottom sheet for picking a file or image.
  void _onFilePickerPressed() async {
    HapticFeedback.lightImpact();
    // Capture theme context before async gap
    final theme = Theme.of(context);

    await showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FilePickerBottomSheet(
          onPickImage: _pickImageFromGallery,
          onPickFile: _pickFile,
        );
      },
    );
  }

  // --- UPDATED: Now uses the service ---
  /// Uses image_picker to select an image from the gallery.
  Future<void> _pickImageFromGallery() async {
    // 1. Close the bottom sheet
    Navigator.of(context).pop();

    try {
      // Call the service
      final PickedFileResult? result = await _filePickerService
          .pickImageFromGallery();

      if (result != null && mounted) {
        // 2. Navigate to the processing screen with the file path
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProcessingReceiptScreen(imagePath: result.file.path),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  // --- UPDATED: Now uses the service ---
  /// Uses file_picker to select a PDF.
  Future<void> _pickFile() async {
    // 1. Close the bottom sheet
    Navigator.of(context).pop();

    try {
      // Call the service
      final PickedFileResult? result = await _filePickerService
          .pickPdfFromFile();

      if (result != null && mounted) {
        // ---
        // TODO: Handle the PDF file path.
        // You might have a different processing screen for PDFs.
        // For now, we'll just show a success message.
        // ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected PDF: ${result.name}'),
            backgroundColor: Colors.green,
          ),
        );
        // Example:
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (context) => ProcessingPdfScreen(pdfPath: result.file.path),
        // ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Widget _buildViewfinder(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: _isPermissionDenied
              ? _buildPermissionDeniedView() // Show permission denied UI
              : FutureBuilder<void>(
                  future: _initializeControllerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done ||
                        _controller == null ||
                        !_controller!.value.isInitialized) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
                    return CameraPreview(_controller!);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Container(
      color: Colors.grey[900], // Keep it dark for camera feel
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.no_photography_outlined,
            color: Colors.white54,
            size: 64,
          ),
          const SizedBox(height: 24),
          const Text(
            'Camera Access Denied',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'We need camera access to scan your receipts. Please enable it in your device settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                openAppSettings(), // Requires permission_handler package
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    IconData flashIcon = Icons.flash_off_outlined;
    if (!_isDisposing &&
        _controller != null &&
        _controller!.value.isInitialized) {
      flashIcon = _controller!.value.flashMode == FlashMode.torch
          ? Icons.flash_on
          : Icons.flash_off_outlined;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, flashIcon),
            _buildViewfinder(context),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  // ... (_buildTopBar remains the same) ...
  Widget _buildTopBar(BuildContext context, IconData flashIcon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(flashIcon),
            color: Colors.white,
            iconSize: 32,
            onPressed: _isPermissionDenied ? null : _toggleFlash,
          ),
        ],
      ),
    );
  }

  // ... (_buildBottomBar remains the same) ...
  Widget _buildBottomBar(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 24.0,
            ),
            color: Colors.black.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Manual Entry Button
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded),
                  color: Colors.white,
                  iconSize: 28,
                  onPressed: _onManualEntryPressed,
                ),
                // 2. Shutter Button
                InkWell(
                  onTapDown: (_) {
                    HapticFeedback.lightImpact();
                    setState(() => _isShutterPressed = true);
                  },
                  onTapUp: (_) => _onTakePicturePressed(),
                  onTapCancel: () => setState(() => _isShutterPressed = false),
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: _isShutterPressed ? 60 : 68,
                        height: _isShutterPressed ? 60 : 68,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                // 3. File Picker Button
                IconButton(
                  icon: const Icon(
                    Icons.photo_library_rounded,
                  ), // Improved icon
                  color: Colors.white,
                  iconSize: 28,
                  onPressed: _onFilePickerPressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
