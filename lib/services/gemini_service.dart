import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyCdbMFrg2hUD1SwMfWZLuk8ZUBAC057QZU';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  
  // Comprehensive receipt data model with all possible fields
  static const Map<String, dynamic> _receiptSchema = {
    "type": "object",
    "properties": {
      "merchant_name": {
        "type": "string",
        "description": "Full name of the store/restaurant/merchant"
      },
      "title": {
        "type": "string",
        "description": "Receipt title or heading if present"
      },
      "date": {
        "type": "string",
        "description": "Date of purchase in YYYY-MM-DD format"
      },
      "time": {
        "type": "string",
        "description": "Time of purchase in HH:MM format if visible"
      },
      "items": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string",
              "description": "Item name/description"
            },
            "quantity": {
              "type": "number",
              "description": "Quantity of item (default 1 if not visible)"
            },
            "unit_price": {
              "type": "number",
              "description": "Price per unit/item"
            },
            "total_price": {
              "type": "number",
              "description": "Total price for this item (quantity × unit_price)"
            }
          },
          "required": ["name", "total_price"]
        },
        "description": "Complete list of all items with individual prices"
      },
      "subtotal": {
        "type": "number",
        "description": "Subtotal amount before tax/discount"
      },
      "discount": {
        "type": "number",
        "description": "Discount amount if any (0 if no discount)"
      },
      "discount_percentage": {
        "type": "number",
        "description": "Discount percentage if mentioned"
      },
      "tax_amount": {
        "type": "number",
        "description": "Tax amount (0 if not visible)"
      },
      "tax_rate": {
        "type": "number",
        "description": "Tax rate percentage if visible"
      },
      "service_charge": {
        "type": "number",
        "description": "Service charge if any"
      },
      "tip": {
        "type": "number",
        "description": "Tip amount if mentioned"
      },
      "total_amount": {
        "type": "number",
        "description": "Final total amount paid (numeric value only)"
      },
      "payment_method": {
        "type": "string",
        "enum": ["Cash", "Credit Card", "Debit Card", "Digital Payment", "UPI", "Other"],
        "description": "Payment method used"
      },
      "category": {
        "type": "string",
        "enum": [
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
          "Other"
        ],
        "description": "Category that best matches this expense. IMPORTANT: Use specific categories - Food & Drinks for restaurants/cafes, Transport for petrol/gas stations, Bills & Utilities for bank/utility payments, Health for medical/pharmacy. Only use 'Other' if truly unclear."
      },
      "currency": {
        "type": "string",
        "description": "Currency code detected from receipt (USD, PKR, EUR, GBP, INR, CNY, JPY, etc.). Default to USD if not visible."
      },
      "invoice_number": {
        "type": "string",
        "description": "Invoice/Receipt number if visible"
      },
      "split_receipts": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "merchant_name": {"type": "string"},
            "category": {"type": "string"},
            "items": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "name": {"type": "string"},
                  "total_price": {"type": "number"}
                }
              }
            },
            "subtotal": {"type": "number"},
            "total_amount": {
              "type": "number",
              "description": "Final total for this split INCLUDING its share of tax, tip, and fees"
            }
          }
        },
        "description": "Array of separate receipts if multiple merchants/categories found in one image"
      },
      "confidence": {
        "type": "number",
        "minimum": 0,
        "maximum": 1,
        "description": "Confidence level of the extraction (0.0 to 1.0)"
      }
    },
    "required": ["merchant_name", "total_amount", "items", "confidence"]
  };

  /// Process receipt image and extract comprehensive structured data
  static Future<ReceiptData?> processReceiptImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file not found: $imagePath');
      }

      final Uint8List imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      final String url = '$_baseUrl/gemini-2.5-flash:generateContent?key=$_apiKey';
      
      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text": """
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
- If you see "£" → currency: "GBP"
- If you see "₹" or "INR" → currency: "INR"
- If unclear, default to "USD"

CATEGORY SELECTION (VERY IMPORTANT - BE SPECIFIC):
- Restaurants, cafes, food delivery → "Food & Drinks"
- Supermarkets, grocery stores → "Groceries"
- Petrol pumps, gas stations, fuel → "Transport"
- Uber, taxi, bus, train tickets → "Transport"
- Clothing, electronics, general shopping → "Shopping"
- Netflix, Spotify, software subscriptions → "Subscriptions"
- Electricity, water, gas bills, bank charges → "Bills & Utilities"
- Doctor, pharmacy, hospital → "Health"
- Movies, games, events → "Entertainment"
- Hotels, flights, vacation → "Travel"
- Gym, office supplies → "Business"
- Only use "Other" if truly unclear

DETAILED ITEMS EXTRACTION:
- List EVERY item individually with its name
- Extract individual price for EACH item
- Include quantity if visible (default to 1)
- Calculate total_price = quantity × unit_price

SPLIT RECEIPT DETECTION:
If you see multiple merchants (e.g., restaurant + petrol pump on same receipt):
- Create separate entries in split_receipts array
- Each split should have: merchant_name, category, items[], subtotal, and total_amount
- Assign CORRECT category to each split (petrol → Transport, food → Food & Drinks, ATM → Bills & Utilities)
- CRITICAL: Calculate "total_amount" for each split by adding its share of Tax/Tip/Service Charge.

EXAMPLE for Restaurant:
{
  "merchant_name": "Pizza Hut",
  "title": "Order Receipt",
  "date": "2024-01-15",
  "time": "18:30",
  "currency": "USD",
  "items": [
    {"name": "Margherita Pizza", "quantity": 1, "unit_price": 499, "total_price": 499},
    {"name": "Coca Cola", "quantity": 2, "unit_price": 60, "total_price": 120}
  ],
  "subtotal": 619,
  "discount": 50,
  "discount_percentage": 8.08,
  "tax_amount": 111.42,
  "tax_rate": 18,
  "service_charge": 30,
  "total_amount": 710.42,
  "payment_method": "Credit Card",
  "category": "Food & Drinks",
  "invoice_number": "INV-12345"
}

EXAMPLE for Petrol Station:
{
  "merchant_name": "Shell Gas Station",
  "date": "2024-01-15",
  "currency": "USD",
  "items": [
    {"name": "Diesel", "quantity": 20, "unit_price": 1.50, "total_price": 30.00}
  ],
  "total_amount": 30.00,
  "category": "Transport",
  "invoice_number": "12345"
}

EXAMPLE for SPLIT RECEIPT (Petrol + ATM + Food on same image):
{
  "merchant_name": "Combined Receipt",
  "date": "2024-01-15",
  "currency": "USD",
  "total_amount": 180.00,
  "category": "Other",
  "items": [],
  "split_receipts": [
    {
      "merchant_name": "Shell Petrol Pump",
      "category": "Transport",
      "items": [
        {"name": "Petrol", "total_price": 50.00}
      ],
      "subtotal": 50.00,
      "total_amount": 55.00
    },
    {
      "merchant_name": "ATM Withdrawal Fee",
      "category": "Bills & Utilities",
      "items": [
        {"name": "ATM Fee", "total_price": 5.00}
      ],
      "subtotal": 5.00,
      "total_amount": 5.00
    },
    {
      "merchant_name": "McDonald's",
      "category": "Food & Drinks",
      "items": [
        {"name": "Big Mac Meal", "total_price": 10.00},
        {"name": "Fries", "total_price": 3.00}
      ],
      "subtotal": 13.00,
      "total_amount": 15.00
    }
  ],
  "confidence": 0.9
}

Be VERY careful with:
1. Category selection - be specific, avoid "Other" unless truly unclear
2. For split receipts - assign CORRECT category to EACH split (petrol=Transport, ATM=Bills & Utilities, food=Food & Drinks)
3. Currency detection - look for symbols and codes
4. Numbers - extract exactly as written on receipt
If any field is not visible, set it to null or 0 as appropriate.
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
          // Clean up JSON if wrapped in markdown
          final String cleanedJson = jsonText.replaceAll('```json', '').replaceAll('```', '').trim();
          final Map<String, dynamic> extractedData = json.decode(cleanedJson);
          
          return ReceiptData.fromJson(extractedData);
        } else {
          throw Exception('No candidates in API response');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception('API Error: ${response.statusCode} - ${errorData['error']?['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error processing receipt: $e');
      return null;
    }
  }

  /// Process PDF receipt
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
Analyze this PDF receipt and extract ALL details:
- Merchant name, title, date, time
- EVERY item with individual prices
- Subtotal, discount, tax, service charge, tip
- Final total amount
- Payment method
- Invoice number if visible
- Split receipts if multiple merchants present

Extract with maximum detail and accuracy.
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
          final String cleanedJson = jsonText.replaceAll('```json', '').replaceAll('```', '').trim();
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
          ? (json['items'] as List).map((item) => ReceiptItem.fromJson(item)).toList()
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
          ? (json['split_receipts'] as List).map((sr) => SplitReceipt.fromJson(sr)).toList()
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

  bool get hasSplitReceipts => splitReceipts != null && splitReceipts!.isNotEmpty;
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
          ? (json['items'] as List).map((item) => ReceiptItem.fromJson(item)).toList()
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