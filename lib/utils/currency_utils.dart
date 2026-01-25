class CurrencyUtils {
  /// Map of currency codes to their symbols - Comprehensive list
  static const Map<String, String> currencySymbols = {
    // Major Currencies
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CNY': '¥',
    
    // South Asian
    'PKR': 'Rs',
    'INR': '₹',
    'BDT': '৳',
    'LKR': 'Rs',
    'NPR': 'Rs',
    'AFN': '؋',
    
    // Middle East & Gulf
    'AED': 'د.إ',
    'SAR': '﷼',
    'QAR': '﷼',
    'KWD': 'د.ك',
    'OMR': '﷼',
    'BHD': 'د.ب',
    'JOD': 'د.ا',
    'ILS': '₪',
    'EGP': '£',
    'IRR': '﷼',
    'IQD': 'ع.د',
    
    // Turkish & Central Asian
    'TRY': '₺',
    'KZT': '₸',
    'UZS': 'сум',
    'TJS': 'ЅМ',
    'TMT': 'm',
    'AZN': '₼',
    'AMD': '֏',
    'GEL': '₾',
    
    // Southeast Asian
    'SGD': 'S\$',
    'MYR': 'RM',
    'THB': '฿',
    'IDR': 'Rp',
    'PHP': '₱',
    'VND': '₫',
    'MMK': 'K',
    'LAK': '₭',
    'KHR': '៛',
    
    // East Asian
    'KRW': '₩',
    'TWD': 'NT\$',
    'HKD': 'HK\$',
    'MOP': 'MOP\$',
    
    // European
    'CHF': 'CHF',
    'SEK': 'kr',
    'NOK': 'kr',
    'DKK': 'kr',
    'PLN': 'zł',
    'CZK': 'Kč',
    'HUF': 'Ft',
    'RON': 'lei',
    'BGN': 'лв',
    'HRK': 'kn',
    'RUB': '₽',
    'UAH': '₴',
    
    // Americas
    'CAD': 'C\$',
    'MXN': '\$',
    'BRL': 'R\$',
    'ARS': '\$',
    'CLP': '\$',
    'COP': '\$',
    'PEN': 'S/',
    
    // Oceania
    'AUD': 'A\$',
    'NZD': 'NZ\$',
    'FJD': 'FJ\$',
    
    // African
    'ZAR': 'R',
    'NGN': '₦',
    'KES': 'KSh',
    'ETB': 'Br',
    'GHS': '₵',
    'MAD': 'د.م.',
    'TND': 'د.ت',
    'DZD': 'د.ج',
  };

  /// Get currency symbol from currency code
  /// Returns $ as default if currency code not found
  static String getCurrencySymbol(String currencyCode) {
    final symbol = currencySymbols[currencyCode] ?? '\$';
    // Ensure Euro symbol is properly encoded (U+20AC)
    if (currencyCode == 'EUR' && symbol != '€') {
      return '€'; // Explicitly return Euro symbol
    }
    return symbol;
  }

  /// Format amount with currency symbol
  static String formatAmount(double amount, String currencyCode, {bool forPdf = false}) {
    if (forPdf) {
      // For PDF export, use currency code instead of symbols to avoid font issues
      return '${amount.toStringAsFixed(2)} $currencyCode';
    }
    final symbol = getCurrencySymbol(currencyCode);
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Format amount with currency symbol (short version without decimals)
  static String formatAmountShort(double amount, String currencyCode, {bool forPdf = false}) {
    if (forPdf) {
      if (amount >= 1000) {
        return '${(amount / 1000).toStringAsFixed(1)}k $currencyCode';
      }
      return '${amount.toStringAsFixed(0)} $currencyCode';
    }
    final symbol = getCurrencySymbol(currencyCode);
    if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '$symbol${amount.toStringAsFixed(0)}';
  }
}


