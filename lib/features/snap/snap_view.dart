import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // --- ADDED: Instantiate the service ---
  final FilePickerService _filePickerService = FilePickerService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  // ... (didChangeAppLifecycleState remains the same) ...
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // App is backgrounded or hidden.
      // Dispose the controller to release the camera hardware completely.
      if (_controller != null) {
        _controller!.dispose();
        _controller = null;
        _initializeControllerFuture = null;
        // Set state to show loading spinner when we come back
        if (mounted) {
          setState(() {});
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      // App is foregrounded.
      // Re-initialize the camera if it's not already initializing.
      if (_controller == null && _initializeControllerFuture == null) {
        _initializeCamera(); // This will set the future and call setState
      }
    }
  }

  // ... (_initializeCamera remains the same) ...
  Future<void> _initializeCamera() async {
    // 1. Ensure 'cameras' list is populated
    try {
      if (cameras.isEmpty) {
        cameras = await availableCameras();
      }

      // 2. Select the first camera (usually the back camera)
      if (cameras.isNotEmpty) {
        final firstCamera = cameras.first;

        // Cleaned up: No need to dispose here, lifecycle handles it
        _controller = CameraController(
          firstCamera,
          // *** OPTIMIZATION: Use 'medium' for much faster preview startup ***
          ResolutionPreset.medium,
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
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose(); // Dispose one last time
    super.dispose();
  }

  // ... (_onTakePicturePressed remains the same) ...
  void _onTakePicturePressed() async {
    // ... (This function remains the same as before)
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isShutterPressed = true;
    });

    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();

      if (mounted) {
        NavigationManager.push(
          context,
          ProcessingReceiptScreen(imagePath: image.path),
          type: TransitionType.slideFromBottom, // A modal slide is nice here
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking picture: $e')),
        );
      }
    }

    // We might not come back here, but reset if we do
    if (mounted) {
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
    // ... (This function remains the same as before)
    HapticFeedback.lightImpact();
    if (_controller == null || !_controller!.value.isInitialized) return;

    final bool isFlashOn = _controller!.value.flashMode == FlashMode.torch;
    _controller!.setFlashMode(isFlashOn ? FlashMode.off : FlashMode.torch);
    setState(() {});
  }

  // --- UPDATED ---
  /// Shows the bottom sheet for picking a file or image.
  void _onFilePickerPressed() async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
      final PickedFileResult? result =
      await _filePickerService.pickImageFromGallery();

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
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
      final PickedFileResult? result =
      await _filePickerService.pickPdfFromFile();

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the flash icon
    final IconData flashIcon = _controller?.value.flashMode == FlashMode.torch
        ? Icons.flash_on
        : Icons.flash_off_outlined;

    return Scaffold(
      backgroundColor: Colors.black54,
      body: SafeArea(
        child: AnimatedOpacity(
          opacity: 1.0, // Always show the UI
          duration: const Duration(milliseconds: 300),
          child: Column(
            children: [
              // 1. Top Bar
              _buildTopBar(context, flashIcon),

              // 2. Viewfinder (The Camera Preview)
              _buildViewfinder(context),

              // 3. Bottom Bar
              _buildBottomBar(context), // --- UPDATED ---
            ],
          ),
        ),
      ),
    );
  }

  // ... (_buildTopBar remains the same) ...
  Widget _buildTopBar(BuildContext context, IconData flashIcon) {
    // ... (This function remains the same as before)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(flashIcon),
            color: Colors.white,
            iconSize: 32,
            onPressed: _toggleFlash,
          ),
        ],
      ),
    );
  }

  // ... (_buildViewfinder remains the same) ...
  Widget _buildViewfinder(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          // *** UPDATED: FutureBuilder now correctly handles re-initialization ***
          child: FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              // If the future is null (disposed) or waiting, show loading
              if (snapshot.connectionState != ConnectionState.done ||
                  _controller == null ||
                  !_controller!.value.isInitialized) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white));
              }

              // When done, show the preview
              return CameraPreview(_controller!);
            },
          ),
        ),
      ),
    );
  }

  // ... (_buildBottomBar remains the same) ...
  Widget _buildBottomBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Row(
        // Use spaceBetween to position the three items evenly
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Manual Entry Button
          IconButton(
            icon: const Icon(Icons.edit_note_outlined),
            color: Colors.white,
            iconSize: 32,
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
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.7), width: 3),
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: _isShutterPressed ? 58 : 62,
                  height: _isShutterPressed ? 58 : 62,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          // 3. File Picker Button (replaces the SizedBox)
          IconButton(
            icon: const Icon(Icons.attach_file_outlined),
            color: Colors.white,
            iconSize: 32,
            onPressed: _onFilePickerPressed,
          ),
        ],
      ),
    );
  }
}