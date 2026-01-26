import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../common/remote_values.dart';

class GeminiService {
  static final String _apiKey = RemoteConfig.apiKey;
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // Comprehensive receipt data model with all possible fields
  // Dynamic schema generator
  static Map<String, dynamic> _getReceiptSchema(List<String> categories) {
    return {
      "type": "object",
      "properties": {
        "merchant_name": {
          "type": "string",
          "description": "Full name of the store/restaurant/merchant",
        },
        "title": {
          "type": "string",
          "description": "Receipt title or heading if present",
        },
        "date": {
          "type": "string",
          "description": "Date of purchase in YYYY-MM-DD format",
        },
        "time": {
          "type": "string",
          "description": "Time of purchase in HH:MM format if visible",
        },
        "items": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "name": {
                "type": "string",
                "description": "Item name/description",
              },
              "quantity": {
                "type": "number",
                "description": "Quantity of item (default 1 if not visible)",
              },
              "unit_price": {
                "type": "number",
                "description": "Price per unit/item",
              },
              "total_price": {
                "type": "number",
                "description":
                    "Total price for this item (quantity × unit_price)",
              },
            },
            "required": ["name", "total_price"],
          },
          "description": "Complete list of all items with individual prices",
        },
        "subtotal": {
          "type": "number",
          "description": "Subtotal amount before tax/discount",
        },
        "discount": {
          "type": "number",
          "description": "Discount amount if any (0 if no discount)",
        },
        "discount_percentage": {
          "type": "number",
          "description": "Discount percentage if mentioned",
        },
        "tax_amount": {
          "type": "number",
          "description": "Tax amount (0 if not visible)",
        },
        "tax_rate": {
          "type": "number",
          "description": "Tax rate percentage if visible",
        },
        "service_charge": {
          "type": "number",
          "description": "Service charge if any",
        },
        "tip": {"type": "number", "description": "Tip amount if mentioned"},
        "total_amount": {
          "type": "number",
          "description": "Final total amount paid (numeric value only)",
        },
        "payment_method": {
          "type": "string",
          "enum": [
            "Cash",
            "Credit Card",
            "Debit Card",
            "Digital Payment",
            "UPI",
            "Other",
          ],
          "description": "Payment method used",
        },
        "category": {
          "type": "string",
          "enum": categories,
          "description":
              "Category that best matches this expense. Choose strictly from the provided list.",
        },
        "currency": {
          "type": "string",
          "description":
              "Currency code detected from receipt (USD, PKR, EUR, GBP, INR, CNY, JPY, etc.). Default to USD if not visible.",
        },
        "invoice_number": {
          "type": "string",
          "description": "Invoice/Receipt number if visible",
        },
        "split_receipts": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "merchant_name": {"type": "string"},
              // We also restrict split category to the same enum
              "category": {"type": "string", "enum": categories},
              "items": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "name": {"type": "string"},
                    "total_price": {"type": "number"},
                  },
                },
              },
              "subtotal": {"type": "number"},
              "total_amount": {
                "type": "number",
                "description":
                    "Final total for this split INCLUDING its share of tax, tip, and fees",
              },
            },
          },
          "description":
              "Array of separate receipts if multiple merchants/categories found in one image",
        },
        "confidence": {
          "type": "number",
          "minimum": 0,
          "maximum": 1,
          "description": "Confidence level of the extraction (0.0 to 1.0)",
        },
      },
      "required": ["merchant_name", "total_amount", "items", "confidence"],
    };
  }

  /// Process receipt image and extract comprehensive structured data
  static Future<ReceiptData?> processReceiptImage(
    String imagePath, {
    List<String>? validCategories,
  }) async {
    try {
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file not found: $imagePath');
      }

      final Uint8List imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      final String url =
          '$_baseUrl/gemini-2.5-flash:generateContent?key=$_apiKey';

      // Default categories if none provided
      final categories =
          validCategories ??
          [
            "Food & Drinks",
            "Groceries",
            "Transport",
            "Shopping",
            "Subscriptions",
            "Bills & Utilities",
            "Salary",
            "Business",
            "Investments",
            "Health",
            "Entertainment",
            "Travel",
            "Other",
          ];

      final categoryListString = categories.map((c) => '- "$c"').join('\n');

      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text":
                    """
Analyze this receipt/image thoroughly and extract EVERY SINGLE DETAIL visible:

CRITICAL REQUIREMENTS:
1. Extract ALL items individually with their separate prices
2. Extract merchant/store name, date, time if visible
3. Extract title/heading if present at top
4. Extract subtotal, discount (amount & %), tax, service charge, tip separately
5. Extract final total amount
6. Extract invoice/receipt number if visible
7. Extract currency from receipt (look for currency symbols like \$, ₹, €, £, ¥, etc.)
8. If receipt contains multiple merchants/categories (split receipt), separate them into split_receipts array
9. Extract payment method (Cash, Card, UPI, etc.)

CURRENCY DETECTION:
- Look for currency symbols: \$ (USD), ₹ (INR/PKR), € (EUR), £ (GBP), ¥ (CNY/JPY), etc.
- If you see "Rs" or "PKR" → currency: "PKR"
- If you see "\$" → currency: "USD"
- If you see "€" → currency: "EUR"
- If unclear, default to "USD"

CATEGORY SELECTION (VERY IMPORTANT):
Match the expense to one of the following valid categories:
$categoryListString
- Only use "Other" if truly unclear or no other category fits.

DETAILED ITEMS EXTRACTION:
- List EVERY item individually with its name
- Extract individual price for EACH item
- Calculate total_price = quantity × unit_price

SPLIT RECEIPT DETECTION:
If you see multiple merchants (e.g., restaurant + petrol pump on same receipt):
- Create separate entries in split_receipts array
- Assign CORRECT category to each split from the valid list above
""",
              },
              {
                "inline_data": {"mime_type": "image/jpeg", "data": base64Image},
              },
            ],
          },
        ],
        "generationConfig": {
          "response_mime_type": "application/json",
          "response_schema": _getReceiptSchema(categories),
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty) {
          final String jsonText =
              responseData['candidates'][0]['content']['parts'][0]['text'];
          // Clean up JSON if wrapped in markdown
          final String cleanedJson = jsonText
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          final Map<String, dynamic> extractedData = json.decode(cleanedJson);

          return ReceiptData.fromJson(extractedData);
        } else {
          throw Exception('No candidates in API response');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          'API Error: ${response.statusCode} - ${errorData['error']?['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('Error processing receipt: $e');
      return null;
    }
  }

  /// Process PDF receipt
  static Future<ReceiptData?> processReceiptPDF(
    String pdfPath, {
    List<String>? validCategories,
  }) async {
    try {
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        throw Exception('PDF file not found: $pdfPath');
      }

      final Uint8List pdfBytes = await pdfFile.readAsBytes();
      final String base64Pdf = base64Encode(pdfBytes);

      final String url =
          '$_baseUrl/gemini-2.5-flash:generateContent?key=$_apiKey';

      // Default categories if none provided
      final categories =
          validCategories ??
          [
            "Food & Drinks",
            "Groceries",
            "Transport",
            "Shopping",
            "Subscriptions",
            "Bills & Utilities",
            "Salary",
            "Business",
            "Investments",
            "Health",
            "Entertainment",
            "Travel",
            "Other",
          ];
      final categoryListString = categories.map((c) => '- "$c"').join('\n');

      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text":
                    """
Analyze this PDF receipt and extract ALL details:
- Merchant name, title, date, time
- EVERY item with individual prices
- Subtotal, discount, tax, service charge, tip
- Final total amount
- Payment method
- Invoice number if visible
- Split receipts if multiple merchants present

CATEGORY SELECTION:
Match the expense to one of the following valid categories:
$categoryListString

Extract with maximum detail and accuracy.
""",
              },
              {
                "inline_data": {
                  "mime_type": "application/pdf",
                  "data": base64Pdf,
                },
              },
            ],
          },
        ],
        "generationConfig": {
          "response_mime_type": "application/json",
          "response_schema": _getReceiptSchema(categories),
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty) {
          final String jsonText =
              responseData['candidates'][0]['content']['parts'][0]['text'];
          final String cleanedJson = jsonText
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          final Map<String, dynamic> extractedData = json.decode(cleanedJson);

          return ReceiptData.fromJson(extractedData);
        }
      }

      throw Exception('Failed to process PDF: ${response.statusCode}');
    } catch (e) {
      print('Error processing PDF receipt: $e');
      return null;
    }
  }

  /// Generate spending insights and tips using Gemini
  static Future<Map<String, dynamic>?> generateSpendingInsights(
    List<dynamic> expenses,
    double budget,
    String currency,
  ) async {
    try {
      // 1. Prepare data summary for the prompt
      // We limit to top 20 expensive items to avoid token limits, or summarize by category
      double totalSpent = 0;
      final Map<String, double> categoryTotals = {};

      for (var e in expenses) {
        // Handle both Expense object and raw maps if needed, currently assuming Expense objects from provider
        final amount = e.amount as double;
        final category = e.category as String;

        totalSpent += amount;
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }

      final String currencySymbol = currency; // Simplified

      final summaryBuffer = StringBuffer();
      summaryBuffer.writeln("Total Spent: $totalSpent $currencySymbol");
      summaryBuffer.writeln("Budget: $budget $currencySymbol");
      summaryBuffer.writeln("Category Breakdown:");
      categoryTotals.forEach((key, value) {
        summaryBuffer.writeln("- $key: $value $currencySymbol");
      });

      // 2. Construct Prompt
      final String prompt =
          """
You are a financial analyst. Analyze this monthly spending data:

$summaryBuffer

Provide a JSON response with the following 3 fields:
1. "analysis": A 1-sentence specific insight about the spending trend or biggest expense category. Be friendly but direct.
2. "tip": A 1-sentence actionable tip to save money based on these specific categories.
3. "score": A score from 1-10 (integer) rating their financial health/budget adherence.

Example JSON format:
{
  "analysis": "Your food spending is 40% of your total, which is high.",
  "tip": "Try cooking at home more often to reduce food costs.",
  "score": 6
}
""";

      final String url =
          '$_baseUrl/gemini-2.5-flash:generateContent?key=$_apiKey';

      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ],
          },
        ],
        "generationConfig": {"response_mime_type": "application/json"},
      };

      // 3. Call API
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty) {
          final String jsonText =
              responseData['candidates'][0]['content']['parts'][0]['text'];
          final String cleanedJson = jsonText
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          return json.decode(cleanedJson);
        }
      }
      return null;
    } catch (e) {
      print('Error generating insights: $e');
      return null;
    }
  }
}

/// Enhanced receipt data model with all fields
class ReceiptData {
  final String merchantName;
  final String? title;
  final String? date;
  final String? time;
  final List<ReceiptItem> items;
  final double? subtotal;
  final double? discount;
  final double? discountPercentage;
  final double? taxAmount;
  final double? taxRate;
  final double? serviceCharge;
  final double? tip;
  final double totalAmount;
  final String? paymentMethod;
  final String category;
  final String? invoiceNumber;
  final String? currency; // Currency code (USD, PKR, EUR, etc.)
  final List<SplitReceipt>? splitReceipts;
  final double confidence;

  ReceiptData({
    required this.merchantName,
    this.title,
    this.date,
    this.time,
    required this.items,
    this.subtotal,
    this.discount,
    this.discountPercentage,
    this.taxAmount,
    this.taxRate,
    this.serviceCharge,
    this.tip,
    required this.totalAmount,
    this.paymentMethod,
    required this.category,
    this.invoiceNumber,
    this.currency,
    this.splitReceipts,
    required this.confidence,
  });

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      merchantName: json['merchant_name'] ?? 'Unknown Merchant',
      title: json['title'],
      date: json['date'],
      time: json['time'],
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => ReceiptItem.fromJson(item))
                .toList()
          : [],
      subtotal: json['subtotal']?.toDouble(),
      discount: json['discount']?.toDouble() ?? 0.0,
      discountPercentage: json['discount_percentage']?.toDouble(),
      taxAmount: json['tax_amount']?.toDouble() ?? 0.0,
      taxRate: json['tax_rate']?.toDouble(),
      serviceCharge: json['service_charge']?.toDouble() ?? 0.0,
      tip: json['tip']?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      paymentMethod: json['payment_method'],
      category: json['category'] ?? 'Other',
      invoiceNumber: json['invoice_number'],
      currency: json['currency'] ?? 'USD', // Default to USD if not detected
      splitReceipts: json['split_receipts'] != null
          ? (json['split_receipts'] as List)
                .map((sr) => SplitReceipt.fromJson(sr))
                .toList()
          : null,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchant_name': merchantName,
      'title': title,
      'date': date,
      'time': time,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'discount_percentage': discountPercentage,
      'tax_amount': taxAmount,
      'tax_rate': taxRate,
      'service_charge': serviceCharge,
      'tip': tip,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'category': category,
      'invoice_number': invoiceNumber,
      'currency': currency,
      'split_receipts': splitReceipts?.map((sr) => sr.toJson()).toList(),
      'confidence': confidence,
    };
  }

  bool get hasSplitReceipts =>
      splitReceipts != null && splitReceipts!.isNotEmpty;
}

/// Enhanced receipt item with quantity and unit price
class ReceiptItem {
  final String name;
  final double quantity;
  final double? unitPrice;
  final double totalPrice;

  ReceiptItem({
    required this.name,
    this.quantity = 1.0,
    this.unitPrice,
    required this.totalPrice,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name'] ?? '',
      quantity: (json['quantity'] ?? 1.0).toDouble(),
      unitPrice: json['unit_price']?.toDouble(),
      totalPrice: (json['total_price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }
}

/// Split receipt for multiple merchants
class SplitReceipt {
  final String merchantName;
  final String category;
  final List<ReceiptItem> items;
  final double subtotal;
  final double totalAmount;

  SplitReceipt({
    required this.merchantName,
    required this.category,
    required this.items,
    required this.subtotal,
    required this.totalAmount,
  });

  factory SplitReceipt.fromJson(Map<String, dynamic> json) {
    final sub = (json['subtotal'] ?? 0.0).toDouble();
    return SplitReceipt(
      merchantName: json['merchant_name'] ?? 'Unknown',
      category: json['category'] ?? 'Other',
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => ReceiptItem.fromJson(item))
                .toList()
          : [],
      subtotal: sub,
      totalAmount: (json['total_amount'] ?? sub).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchant_name': merchantName,
      'category': category,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'total_amount': totalAmount,
    };
  }
}
