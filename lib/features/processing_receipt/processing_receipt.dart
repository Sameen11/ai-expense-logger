import 'dart:io';
import 'package:flutter/material.dart';
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
          await Future.delayed(const Duration(milliseconds: 800)); // Analyzing image
        } else if (i == 1) {
          await Future.delayed(const Duration(milliseconds: 1000)); // Extracting text
        } else if (i == 2) {
          // This is where the actual API call happens
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // Call Gemini API
      final ReceiptData? receiptData = await GeminiService.processReceiptImage(widget.imagePath);
      
      if (mounted) {
        setState(() {
          _processingStep = _steps.length;
        });
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (receiptData != null && mounted) {
        // Navigate to manual entry screen with extracted data
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AddExpenseManuallyScreen(
              extractedData: (
                receiptData.merchantName,
                receiptData.totalAmount,
                receiptData.category,
                receiptData.date,
                receiptData.paymentMethod ?? 'Credit Card',
                receiptData.confidence,
              ),
            ),
          ),
        );
      } else {
        // Handle error case
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _errorMessage = 'Failed to process receipt. Please try again or enter details manually.';
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
      MaterialPageRoute(
        builder: (context) => const AddExpenseManuallyScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: FileImage(File(widget.imagePath)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              if (_isProcessing) ...[
                // 2. Loading Spinner
                const CircularProgressIndicator(),
                const SizedBox(height: 20),

                // 3. Title
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Processing with AI...',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('🤖', style: TextStyle(fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Using Google Gemini AI to extract data',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),

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
                  color: Colors.red[400],
                ),
                const SizedBox(height: 20),
                Text(
                  'Processing Failed',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
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
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _skipToManualEntry,
                      icon: const Icon(Icons.edit),
                      label: const Text('Manual Entry'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
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
    Widget icon;
    Color color = Colors.grey[600]!;

    switch (state) {
      case _StepState.done:
        icon = const Icon(Icons.check_circle, color: Colors.green, size: 20);
        color = Colors.black; // Make text darker when done
        break;
      case _StepState.processing:
        icon = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        );
        color = Colors.blue[700]!;
        break;
      case _StepState.pending:
        icon = Icon(Icons.circle_outlined, color: Colors.grey[400], size: 20);
        color = Colors.grey[400]!;
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
            style: TextStyle(
              fontSize: 16,
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