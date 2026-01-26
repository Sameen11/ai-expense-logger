class CategoryStats {
  final String categoryName;
  final String emoji;
  final double totalAmount;
  final double percentage;
  final int transactionCount;
  final double averageSpend;
  final String topMerchant;

  CategoryStats({
    required this.categoryName,
    required this.emoji,
    required this.totalAmount,
    required this.percentage,
    required this.transactionCount,
    required this.averageSpend,
    required this.topMerchant,
  });
}
