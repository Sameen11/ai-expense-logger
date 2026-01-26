import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// import '../../common/colors.dart';
import '../../models/expense.dart';
import '../../navigation/nav_manager.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/data_picker_dialog.dart';
import '../../widgets/expense_list_item.dart';
import '../snap/add_expense.dart';
import '../snap/snap_view.dart';
import '../insights/insights_view.dart';
import '../settings/settings_view.dart';
import '../../widgets/staggered_list.dart'; // Import StaggeredSlideUp
import 'package:flutter/services.dart'; // Import HapticFeedback

class ExpensesView extends StatefulWidget {
  const ExpensesView({super.key});

  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView> {
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectMonth(BuildContext context) async {
    final provider = context.read<ExpenseProvider>();
    final initialDate = provider.selectedMonth;

    final pickedDate = await showCustomDatePicker(
      context: context,
      initialDate: initialDate,
    );

    if (pickedDate != null) {
      provider.updateSelectedMonth(DateTime(pickedDate.year, pickedDate.month));
    }
  }

  Widget _buildSearchField() {
    final theme = Theme.of(context);
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search merchant, amount...',
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
        ),
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      onChanged: (query) => setState(() => _searchQuery = query),
    );
  }

  String _selectedCategory = 'All';

  // ... existing code ...

  Widget _buildCategoryFilter() {
    final theme = Theme.of(context);
    final provider = context.watch<ExpenseProvider>();
    final expenses = provider.expensesForSelectedMonth;

    // Get unique categories from actual expenses in the current month
    // Plus "All" at the beginning
    final categories = [
      'All',
      ...expenses.map((e) => e.category).toSet().toList()..sort(),
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedCategory = selected ? cat : 'All';
              });
            },
            selectedColor: theme.colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: theme.cardColor,
            side: isSelected
                ? BorderSide(color: theme.colorScheme.primary, width: 1)
                : BorderSide(color: theme.dividerColor.withOpacity(0.1)),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // --- Logic for Filtering and Grouping ---
        final List<Expense> filteredExpenses = _getFilteredExpenses(provider);

        // Create a flat list of mixed types (String for headers, Expense for items)
        final List<dynamic> flatList = _buildFlatList(filteredExpenses);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            title: _isSearching
                ? _buildSearchField()
                : _buildTitle(context, provider.selectedMonth),
            actions: [
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.close : Icons.search,
                  size: 28,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () {
                  setState(() {
                    if (_isSearching) {
                      _isSearching = false;
                      _searchQuery = '';
                      _searchController.clear();
                    } else {
                      _isSearching = true;
                    }
                  });
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(
                50.0,
              ), // Increased height for filter
              child: Column(
                children: [
                  if (!_isSearching) _buildCategoryFilter(),
                  Container(
                    color: theme.dividerColor.withOpacity(0.1),
                    height: 1.0,
                  ),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              // Removed Quick Actions Row as requested

              // The main List
              Expanded(
                child: filteredExpenses.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          bottom: 100,
                          top: 10,
                        ), // Add top padding
                        itemCount: flatList.length,
                        itemBuilder: (context, index) {
                          final item = flatList[index];
                          return StaggeredSlideUp(
                            index: index,
                            child: item is String
                                ? _DateHeader(title: item)
                                : ExpenseListItem(expense: item as Expense),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: "add_expense_fab",
            onPressed: () => NavigationManager.push(
              context,
              const AddExpenseManuallyScreen(),
              type: TransitionType.platform,
            ),
            backgroundColor: theme.colorScheme.primary,
            child: Icon(
              Icons.add,
              color: theme.colorScheme.onPrimary,
              size: 30,
            ),
          ),
        );
      },
    );
  }

  // Helper to build the combined list of headers and expenses
  List<dynamic> _buildFlatList(List<Expense> filtered) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    final List<Expense> today = filtered
        .where((e) => _isSameDay(e.createdAt.toDate(), now))
        .toList();
    final List<Expense> yest = filtered
        .where((e) => _isSameDay(e.createdAt.toDate(), yesterday))
        .toList();
    final List<Expense> older = filtered.where((e) {
      final date = e.createdAt.toDate();
      return date.isBefore(yesterday) && !_isSameDay(date, yesterday);
    }).toList();

    List<dynamic> items = [];
    if (today.isNotEmpty) {
      items.add("Today");
      items.addAll(today);
    }
    if (yest.isNotEmpty) {
      items.add("Yesterday");
      items.addAll(yest);
    }
    if (older.isNotEmpty) {
      items.add("Prior Transactions");
      items.addAll(older);
    }
    return items;
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? theme.cardColor
                  : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 60,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isSearching ? "No results found." : "No expenses yet.",
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap '+' to add your first expense!",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context, DateTime selectedMonth) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _selectMonth(context),
      borderRadius: BorderRadius.circular(12), // Ripple effect constraint
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('MMMM yyyy and more').format(selectedMonth),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: theme.colorScheme.onSurface,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Expense> _getFilteredExpenses(ExpenseProvider provider) {
    final expenses = provider.expensesForSelectedMonth;

    // 1. Filter by Search
    List<Expense> result = expenses;
    if (_isSearching && _searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where(
            (e) =>
                e.merchant.toLowerCase().contains(query) ||
                e.category.toLowerCase().contains(query),
          )
          .toList();
    }

    // 2. Filter by Category Chip
    if (_selectedCategory != 'All') {
      result = result.where((e) => e.category == _selectedCategory).toList();
    }

    return result;
  }
}

// Updated DateHeader
class _DateHeader extends StatelessWidget {
  final String title;
  const _DateHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
