import 'dart:io';
import 'package:flutter/material.dart';
// import '../../common/colors.dart';
import '../snap/add_expense.dart';
import '../../services/gemini_service.dart';

import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';

class ProcessingReceiptScreen extends StatefulWidget {
  final String imagePath;
  const ProcessingReceiptScreen({super.key, required this.imagePath});

  @override
  State<ProcessingReceiptScreen> createState() =>
      _ProcessingReceiptScreenState();
}

class _ProcessingReceiptScreenState extends State<ProcessingReceiptScreen>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = true;
  String? _errorMessage;
  int _processingStep = 0;
  late AnimationController _scannerController;

  final List<String> _steps = [
    'Analyzing Image Check...',
    'Extracting Text Data...',
    'Categorizing with AI...',
  ];

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Start processing after check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processReceiptWithGemini();
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _processReceiptWithGemini() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _processingStep = 0;
    });

    try {
      // Step 1: Analyzing image
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() => _processingStep = 1);

      // Step 2: Extracting text data
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() => _processingStep = 2);

      // Step 3: Processing with AI (Actual API call)
      // Fetch available categories
      if (!mounted) return;
      final categoryProvider = context.read<CategoryProvider>();
      // categories must be a list of strings
      final categories = categoryProvider
          .getAllCategories()
          .map((e) => e.name)
          .toList();

      final ReceiptData? receiptData = await GeminiService.processReceiptImage(
        widget.imagePath,
        validCategories: categories,
      );

      if (!mounted) return;

      if (receiptData != null) {
        // Step 4: Structuring results
        setState(() => _processingStep = 3);
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        // Navigate to AddExpenseScreen with extracted data
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AddExpenseManuallyScreen(receiptData: receiptData),
          ),
        );
      } else {
        throw Exception('Failed to extract data from receipt.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _retryProcessing() {
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
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. The Captured Image with Scanner Effect
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 300,
                    width: double.infinity,
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
                  if (_isProcessing)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedBuilder(
                          animation: _scannerController,
                          builder: (context, child) {
                            return FractionallySizedBox(
                              heightFactor: 0.1, // Height of the scanner beam
                              alignment: Alignment(
                                0,
                                _scannerController.value * 2 - 1,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      theme.colorScheme.primary.withOpacity(0),
                                      theme.colorScheme.primary.withOpacity(
                                        0.5,
                                      ),
                                      theme.colorScheme.primary.withOpacity(0),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.5),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 30),

              if (_isProcessing) ...[
                // 3. Title (Removed spinner as scanner is enough)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'AI Scanning...',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('✨', style: TextStyle(fontSize: 22)),
                  ],
                ),

                // ... rest of the UI
                const SizedBox(height: 8),
                Text(
                  'Using AI to extract data',
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
