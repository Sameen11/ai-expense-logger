import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyBMhOkiDWeUwQYDklqhhy9Cx1y4TNVn7Qo';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  
  // Receipt data model for structured output
  static const Map<String, dynamic> _receiptSchema = {
    "type": "object",
    "properties": {
      "merchant_name": {
        "type": "string",
        "description": "Name of the store/merchant from the receipt"
      },
      "total_amount": {
        "type": "number",
        "description": "Total amount paid (numeric value only, no currency symbols)"
      },
      "date": {
        "type": "string",
        "description": "Date of purchase in YYYY-MM-DD format"
      },
      "category": {
        "type": "string",
        "enum": [
          "Meals & Dining",
          "Travel",
          "Shopping",
          "Entertainment",
          "Groceries",
          "Healthcare",
          "Education",
          "Utilities",
          "Gas & Fuel",
          "Software",
          "Other"
        ],
        "description": "Category that best fits this expense"
      },
      "items": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string",
              "description": "Item name"
            },
            "price": {
              "type": "number",
              "description": "Item price"
            }
          }
        },
        "description": "List of items purchased (if clearly visible)"
      },
      "payment_method": {
        "type": "string",
        "enum": ["Cash", "Credit Card", "Debit Card", "Digital Payment", "Other"],
        "description": "Payment method used"
      },
      "tax_amount": {
        "type": "number",
        "description": "Tax amount if visible on receipt"
      },
      "confidence": {
        "type": "number",
        "minimum": 0,
        "maximum": 1,
        "description": "Confidence level of the extraction (0.0 to 1.0)"
      }
    },
    "required": ["merchant_name", "total_amount", "category", "confidence"]
  };

  /// Process receipt image and extract structured data
  static Future<ReceiptData?> processReceiptImage(String imagePath) async {
    try {
      // Read image file
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file not found: $imagePath');
      }

      final Uint8List imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      // Prepare the request
      final String url = '$_baseUrl/gemini-2.5-flash:generateContent?key=$_apiKey';
      
      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text": """
Analyze this receipt image and extract the following information accurately:

1. Merchant/Store name
2. Total amount (numeric value only)
3. Date of purchase
4. Most appropriate category from the provided list
5. Individual items (if clearly visible)
6. Payment method (if mentioned)
7. Tax amount (if visible)
8. Your confidence level in the extraction

Please be very careful with:
- Numbers: Extract only the final total amount, not subtotals
- Date: Use YYYY-MM-DD format
- Category: Choose the most appropriate one from the enum list
- Confidence: Be honest about how clear the receipt is

If any information is not clearly visible or readable, omit it from the response rather than guessing.
"""
              },
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "response_mime_type": "application/json",
          "response_schema": _receiptSchema
        }
      };

      // Make API call
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['candidates'] != null && 
            responseData['candidates'].isNotEmpty) {
          
          final String jsonText = responseData['candidates'][0]['content']['parts'][0]['text'];
          final Map<String, dynamic> extractedData = json.decode(jsonText);
          
          return ReceiptData.fromJson(extractedData);
        } else {
          throw Exception('No candidates in API response');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception('API Error: ${response.statusCode} - ${errorData['error']['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error processing receipt: $e');
      return null;
    }
  }

  /// Process PDF receipt (for future use)
  static Future<ReceiptData?> processReceiptPDF(String pdfPath) async {
    try {
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        throw Exception('PDF file not found: $pdfPath');
      }

      final Uint8List pdfBytes = await pdfFile.readAsBytes();
      final String base64Pdf = base64Encode(pdfBytes);

      final String url = '$_baseUrl/gemini-2.5-flash:generateContent?key=$_apiKey';
      
      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text": """
Analyze this PDF receipt and extract the expense information accurately.
Focus on finding the merchant name, total amount, date, and categorizing the expense appropriately.
"""
              },
              {
                "inline_data": {
                  "mime_type": "application/pdf",
                  "data": base64Pdf
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "response_mime_type": "application/json",
          "response_schema": _receiptSchema
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['candidates'] != null && 
            responseData['candidates'].isNotEmpty) {
          
          final String jsonText = responseData['candidates'][0]['content']['parts'][0]['text'];
          final Map<String, dynamic> extractedData = json.decode(jsonText);
          
          return ReceiptData.fromJson(extractedData);
        }
      }
      
      throw Exception('Failed to process PDF: ${response.statusCode}');
    } catch (e) {
      print('Error processing PDF receipt: $e');
      return null;
    }
  }
}

/// Model class for receipt data
class ReceiptData {
  final String merchantName;
  final double totalAmount;
  final String? date;
  final String category;
  final List<ReceiptItem>? items;
  final String? paymentMethod;
  final double? taxAmount;
  final double confidence;

  ReceiptData({
    required this.merchantName,
    required this.totalAmount,
    this.date,
    required this.category,
    this.items,
    this.paymentMethod,
    this.taxAmount,
    required this.confidence,
  });

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      merchantName: json['merchant_name'] ?? 'Unknown Merchant',
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      date: json['date'],
      category: json['category'] ?? 'Other',
      items: json['items'] != null 
          ? (json['items'] as List).map((item) => ReceiptItem.fromJson(item)).toList()
          : null,
      paymentMethod: json['payment_method'],
      taxAmount: json['tax_amount']?.toDouble(),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchant_name': merchantName,
      'total_amount': totalAmount,
      'date': date,
      'category': category,
      'items': items?.map((item) => item.toJson()).toList(),
      'payment_method': paymentMethod,
      'tax_amount': taxAmount,
      'confidence': confidence,
    };
  }

  @override
  String toString() {
    return 'ReceiptData(merchant: $merchantName, amount: $totalAmount, category: $category, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}

/// Model class for individual receipt items
class ReceiptItem {
  final String name;
  final double price;

  ReceiptItem({
    required this.name,
    required this.price,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }
}
