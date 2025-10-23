import 'dart:io';
import 'package:flutter/material.dart';
import '../snap/add_expense.dart';

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
    'Extracting vendor...',
    'Finding amount...',
    'Categorizing...',
  ];

  @override
  void initState() {
    super.initState();
    _simulateProcessing();
  }

  Future<void> _simulateProcessing() async {
    // Animate through the steps
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(Duration(milliseconds: 1200 + (i * 200)));
      if (mounted) {
        setState(() {
          _processingStep = i + 1;
        });
      }
    }

    // Wait a final moment
    await Future.delayed(const Duration(milliseconds: 500));

    // --- MOCK DATA ---
    // In a real app, this data would come from your OCR/AI model
    const String merchant = 'Starbucks';
    const double amount = 15.47;
    const String category = 'Meals & Dining';
    // -----------------

    if (mounted) {
      // Navigate to the manual entry screen and PRE-FILL the data
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AddExpenseManuallyScreen(
            extractedData: (merchant, amount, category),
          ),
        ),
      );
    }
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

              // 2. Loading Spinner
              const CircularProgressIndicator(),
              const SizedBox(height: 20),

              // 3. Title
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Reading receipt...',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('✨', style: TextStyle(fontSize: 22)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'This usually takes 2-3 seconds',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),

              // 4. Animated Checklist
              // Use a fixed height to prevent layout jumps
              SizedBox(
                height: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(_steps.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: _buildStepRow(
                        text: _steps[index],
                        // Determine the state of the step
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