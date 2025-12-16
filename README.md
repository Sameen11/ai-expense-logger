# AI Expense Logger

A powerful, AI-powered expense tracking mobile application built with Flutter. Automatically extract expense data from receipts using Google Gemini AI, track expenses across multiple currencies, and generate detailed reports.

## 📱 Features

### 1. **AI-Powered Receipt Scanning**
- **Camera Capture**: Take photos of receipts directly in the app
- **Gallery Selection**: Choose receipt images from your device gallery
- **PDF Support**: Upload and process PDF receipts
- **Automatic Data Extraction**: 
  - Merchant name
  - Transaction date and time
  - Total amount and currency
  - Individual items with quantities and prices
  - Tax, tip, discount amounts
  - Invoice numbers
  - Payment method detection

### 2. **Expense Management**
- **Manual Entry**: Add expenses manually with full control
- **Receipt Date vs Added Date**: 
  - Receipt Date: Original transaction date from receipt
  - Added Date: When you added the expense to the app
- **Multi-Currency Support**: 
  - Support for 50+ currencies (USD, EUR, GBP, PKR, INR, etc.)
  - Currency symbols displayed correctly
  - Separate reports for each currency
- **Category Management**: 
  - Pre-defined categories (Food, Travel, Shopping, etc.)
  - Category icons and emojis
  - Category-based filtering and analytics

### 3. **Detailed Receipt Breakdown**
- **Itemized Lists**: View all items from receipts
- **Quantity Support**: Shows quantities (e.g., "2x Coffee")
- **Financial Breakdown**:
  - Subtotal
  - Tax amount
  - Tip amount
  - Discount amount
  - Final total
- **Additional Information**:
  - Invoice numbers
  - Payment methods
  - Notes and comments

### 4. **Expense Tracking & Organization**
- **Date-Based Filtering**: 
  - Filter by month/year
  - View expenses by "Added On" date (when added to app)
  - Group by Today, Yesterday, Older
- **Search Functionality**: 
  - Real-time search across:
    - Merchant names
    - Amounts
    - Categories
    - Item names
    - Notes
    - Invoice numbers
- **Expense Details**: 
  - View complete expense information
  - Edit expense records
  - Delete expenses

### 5. **Insights & Analytics**
- **Total Spending**: 
  - Monthly spending overview
  - Currency-specific totals
  - Daily average calculation
- **Spending by Category**: 
  - Pie chart visualization
  - Category-wise breakdown
  - Percentage distribution
- **Top Merchants**: 
  - Top merchants by receipt count
  - Top merchants by total amount spent
  - Per-currency merchant rankings
- **Currency Reports**: 
  - Select currency from dropdown
  - View reports for specific currencies
  - Separate analytics per currency

### 6. **Data Export**
- **Multiple Formats**: 
  - PDF (detailed reports with formatting)
  - CSV (spreadsheet compatible)
  - Excel (XLSX format)
- **Export Features**: 
  - Month-specific exports
  - Complete expense details
  - Receipt breakdown included
  - Currency symbols/codes
  - Share via device sharing

### 7. **User Authentication**
- **Secure Login**: Firebase Authentication
- **Email/Password**: Standard authentication
- **Account Management**: 
  - Profile editing
  - Password reset
  - Account deletion

### 8. **Cloud Sync**
- **Firebase Integration**: 
  - Automatic data synchronization
  - Multi-device access
  - Secure cloud storage
- **Offline Support**: 
  - Data cached locally
  - Syncs when online

### 9. **User Interface**
- **Modern Design**: 
  - Clean, intuitive interface
  - Material Design principles
  - Smooth animations
- **Responsive Layout**: 
  - Works on various screen sizes
  - Optimized for mobile devices
- **Dark/Light Theme**: Theme support

## 🛠️ Technical Stack

### Framework & Language
- **Flutter**: Cross-platform mobile framework
- **Dart**: Programming language (SDK ^3.8.1)

### State Management
- **Provider**: State management pattern
- **ChangeNotifier**: Reactive state updates

### Backend Services
- **Firebase Core**: Firebase initialization
- **Firebase Authentication**: User authentication
- **Cloud Firestore**: NoSQL database for expense data
- **Firebase Storage**: Receipt image storage

### AI & Processing
- **Google Gemini API**: Receipt image analysis and data extraction
- **HTTP**: API communication

### Camera & Media
- **Camera**: Live camera preview and photo capture
- **Image Picker**: Gallery image selection
- **File Picker**: PDF file selection

### Data Export
- **PDF**: PDF report generation
- **CSV**: CSV file generation
- **Excel**: Excel file generation
- **Share Plus**: File sharing functionality
- **Open File**: File opening support

### UI Components
- **FL Chart**: Charts and graphs (pie charts)
- **Google Nav Bar**: Navigation bar
- **Table Calendar**: Calendar widget
- **Intl**: Internationalization and formatting

### Utilities
- **Path Provider**: File system paths
- **Shared Preferences**: Local data storage
- **Go Router**: Navigation routing

## 📋 Permissions Required

### 1. Camera Permission
- **Purpose**: Capture receipt photos
- **When Used**: When user taps camera button
- **Required For**: Receipt scanning feature

### 2. Storage/File Access Permission
- **Purpose**: 
  - Access gallery images
  - Save exported reports
  - Share files
- **When Used**: 
  - Selecting images from gallery
  - Exporting reports
  - Sharing files

### 3. Internet Permission
- **Purpose**: 
  - Sync data with Firebase
  - Process receipts with AI
  - User authentication
- **Required For**: Core app functionality

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ^3.8.1 or higher
- Android Studio / Xcode
- Firebase project setup
- Google Gemini API key

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ai-expense-logger
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Add `google-services.json` (Android) to `android/app/`
   - Add `GoogleService-Info.plist` (iOS) to `ios/Runner/`
   - Configure Firebase in `main.dart`

4. **API Configuration**
   - Add Google Gemini API key in `lib/services/gemini_service.dart`
   - Update API key: `_apiKey = 'YOUR_API_KEY'`

5. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── core/                 # Core utilities
│   ├── app_routes.dart  # Route definitions
│   └── sizer.dart       # Responsive design
├── features/            # Feature modules
│   ├── authentication/  # Login, signup, auth
│   ├── expenses/        # Expense list, details
│   ├── insights/        # Analytics and charts
│   ├── snap/            # Camera and receipt capture
│   ├── settings/        # Settings screen
│   └── ...
├── models/              # Data models
│   ├── expense.dart    # Expense model
│   ├── category.dart   # Category model
│   └── user_model.dart # User model
├── providers/           # State management
│   ├── expense_provider.dart
│   └── category_provider.dart
├── services/            # Business logic
│   ├── gemini_service.dart      # AI receipt processing
│   ├── export_service.dart      # Report generation
│   ├── expense_service.dart     # Firestore operations
│   └── auth_service.dart        # Authentication
├── utils/               # Utilities
│   ├── currency_utils.dart       # Currency handling
│   └── globle_methods.dart      # Helper methods
└── widgets/            # Reusable widgets
    ├── data_picker_dialog.dart
    ├── export_bottom_sheet.dart
    └── ...
```

## 🔧 Configuration

### Firebase Setup
1. Create a Firebase project
2. Enable Authentication (Email/Password)
3. Create Firestore database
4. Enable Storage
5. Add configuration files to project

### Gemini API Setup
1. Get API key from Google AI Studio
2. Update `_apiKey` in `lib/services/gemini_service.dart`
3. Ensure API has access to Gemini models

### Currency Configuration
- Supported currencies defined in `lib/utils/currency_utils.dart`
- Add new currencies by updating the `currencySymbols` map

## 📊 Data Model

### Expense Model
```dart
{
  id: String,
  merchant: String,
  amount: double,
  date: DateTime,           // Receipt date
  createdAt: Timestamp,     // Added date
  category: String,
  currency: String,
  items: List<Map>,         // Receipt items
  subtotal: double,
  tax: double,
  tip: double,
  discount: double,
  invoiceNumber: String,
  notes: String,
  paymentMethod: String
}
```

## 🎨 UI/UX Features

- **Material Design**: Modern, clean interface
- **Smooth Animations**: Transitions and feedback
- **Responsive Layout**: Works on all screen sizes
- **Color Scheme**: Consistent color palette
- **Typography**: Poppins font family
- **Icons**: Material and custom icons

## 🔒 Security

- **Encrypted Data**: All data encrypted in transit and at rest
- **Secure Authentication**: Firebase Authentication
- **User Isolation**: Users can only access their own data
- **API Security**: Secure API key handling
- **Permission Management**: Minimal required permissions

## 📱 Supported Platforms

- **Android**: Minimum SDK 21 (Android 5.0)
- **iOS**: iOS 12.0 or higher (planned)

## 🐛 Known Issues

- Camera may require restart on some devices
- Large PDF exports may take time (limited to 1000 expenses)
- Euro symbol uses currency code in PDF exports (font compatibility)

## 🔮 Future Enhancements

- [ ] Offline mode with local database
- [ ] Receipt image compression
- [ ] Custom category creation
- [ ] Budget tracking and alerts
- [ ] Recurring expense support
- [ ] Multi-language support
- [ ] Receipt OCR improvements
- [ ] Export templates customization
- [ ] Data backup and restore
- [ ] Receipt image viewer

## 📄 License

This project is proprietary software. All rights reserved.

## 👥 Support

For support, email support@aiexpenselogger.com or use the in-app Help & Support section.

## 🙏 Acknowledgments

- **Google Firebase**: Backend services
- **Google Gemini AI**: Receipt processing
- **Flutter Team**: Framework and tools
- **Open Source Community**: Various packages and libraries

---

**Version**: 1.0.0  
**Last Updated**: December 2024

**Made with ❤️ using Flutter**
