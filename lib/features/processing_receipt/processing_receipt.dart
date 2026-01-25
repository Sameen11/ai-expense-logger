import 'dart:io';
import 'package:flutter/material.dart';
// import '../../common/colors.dart';
import '../snap/add_expense.dart';
import '../../services/gemini_service.dart';

class ProcessingReceiptScreen extends StatefulWidget {
  final String imagePath;
  const ProcessingReceiptScreen({super.key, required this.imagePath});

  @override
  State<ProcessingReceiptScreen> createState() =>
      _ProcessingReceiptScreenState();
}

class _ProcessingReceiptScreenState extends State<ProcessingReceiptScreen> {
  int _processingStep = 0;
  final List<String> _steps = [
    'Analyzing image...',
    'Extracting text data...',
    'Processing with AI...',
    'Structuring results...',
  ];

  String? _errorMessage;
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _processReceiptWithGemini();
  }

  Future<void> _processReceiptWithGemini() async {
    try {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      // Animate through the steps with real processing
      for (int i = 0; i < _steps.length; i++) {
        if (mounted) {
          setState(() {
            _processingStep = i;
          });
        }

        // Add realistic delays for each step
        if (i == 0) {
          await Future.delayed(
            const Duration(milliseconds: 800),
          ); // Analyzing image
        } else if (i == 1) {
          await Future.delayed(
            const Duration(milliseconds: 1000),
          ); // Extracting text
        } else if (i == 2) {
          // This is where the actual API call happens
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // Call Gemini API
      final ReceiptData? receiptData = await GeminiService.processReceiptImage(
        widget.imagePath,
      );

      if (mounted) {
        setState(() {
          _processingStep = _steps.length;
        });
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (receiptData != null && mounted) {
        // Navigate to manual entry screen with full ReceiptData
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AddExpenseManuallyScreen(receiptData: receiptData),
          ),
        );
      } else {
        // Handle error case
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _errorMessage =
                'Failed to process receipt. Please try again or enter details manually.';
          });
        }
      }
    } catch (e) {
      print('Error processing receipt: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  void _retryProcessing() {
    setState(() {
      _processingStep = 0;
      _errorMessage = null;
      _isProcessing = true;
    });
    _processReceiptWithGemini();
  }

  void _skipToManualEntry() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseManuallyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        // Hide the back button while processing
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. The Captured Image
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: FileImage(File(widget.imagePath)),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              if (_isProcessing) ...[
                // 2. Loading Spinner
                CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                  strokeWidth: 2.5,
                ),
                const SizedBox(height: 10),

                // 3. Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Processing with AI...',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('🤖', style: TextStyle(fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Using Google Gemini AI to extract data',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 30),

                // 4. Animated Checklist
                SizedBox(
                  height: 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(_steps.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _buildStepRow(
                          text: _steps[index],
                          state: index < _processingStep
                              ? _StepState.done
                              : index == _processingStep
                              ? _StepState.processing
                              : _StepState.pending,
                        ),
                      );
                    }),
                  ),
                ),
              ] else if (_errorMessage != null) ...[
                // Error state
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 20),
                Text(
                  'Processing Failed',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 30),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _retryProcessing,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _skipToManualEntry,
                      icon: const Icon(Icons.edit),
                      label: const Text('Manual Entry'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(color: theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for each processing step
  Widget _buildStepRow({required String text, required _StepState state}) {
    final theme = Theme.of(context);
    Widget icon;
    Color color = theme.colorScheme.onSurfaceVariant;

    switch (state) {
      case _StepState.done:
        icon = const Icon(Icons.check_circle, color: Colors.green, size: 20);
        color = theme.colorScheme.onSurface; // Make text darker when done
        break;
      case _StepState.processing:
        icon = SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: theme.colorScheme.primary,
          ),
        );
        color = theme.colorScheme.primary;
        break;
      case _StepState.pending:
        icon = Icon(
          Icons.circle_outlined,
          color: theme.disabledColor,
          size: 20,
        );
        color = theme.disabledColor;
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Row(
        key: ValueKey(state), // Key for the animation
        children: [
          icon,
          const SizedBox(width: 12),
          Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: state == _StepState.processing
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// Enum to manage the state of each step
enum _StepState { pending, processing, done }
