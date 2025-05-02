import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../models/meal_plan.dart';
import '../database_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'food_form_dialog.dart';
import 'meal_plan_form_dialog.dart';

class FoodCrudScreen extends StatefulWidget {
  const FoodCrudScreen({super.key});

  @override
  State<FoodCrudScreen> createState() => _FoodCrudScreenState();
}

class _FoodCrudScreenState extends State<FoodCrudScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<FoodItem> _foods = [];
  List<FoodItem> _filteredFoods = [];
  List<MealPlan> _plans = [];
  bool _isLoading = true;
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: 0,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final foods = await _dbHelper.getAllFoods();
      final plans = await _dbHelper.getAllMealPlans();
      setState(() {
        _foods = foods;
        _filteredFoods = foods;
        _plans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    }
  }

  void _filterFoods(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredFoods = _foods;
      } else {
        _filteredFoods = _foods.where((food) {
          return food.name.toLowerCase().contains(query.toLowerCase()) ||
              food.category.toLowerCase().contains(query.toLowerCase()) ||
              food.description.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _showFoodForm([FoodItem? food]) async {
    final result = await showDialog<FoodItem>(
      context: context,
      builder: (context) => FoodFormDialog(food: food),
    );

    if (result != null) {
      try {
        if (food != null) {
          await _dbHelper.updateFood(result);
        } else {
          await _dbHelper.createFood(result);
        }
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(food != null ? 'Food updated successfully' : 'Food added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showFoodDetails(FoodItem food) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(food.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (food.imageUrl.isNotEmpty)
                Image.network(
                  food.imageUrl,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 16),
              Text(
                food.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text('Category: ${food.category}'),
              Text('Calories: ${food.calories} kcal'),
              const SizedBox(height: 8),
              const Text('Ingredients:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...food.ingredients.map((ingredient) => Text('• $ingredient')),
              if (food.recipeUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(food.recipeUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not launch recipe link')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.menu_book),
                  label: const Text('View Recipe'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFood(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Food'),
        content: const Text('Are you sure you want to delete this food item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbHelper.deleteFood(id);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Food deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showMealPlanForm([MealPlan? plan]) async {
    final result = await showDialog<MealPlan>(
      context: context,
      builder: (context) => MealPlanFormDialog(
        plan: plan,
        availableFoods: _foods,
      ),
    );

    if (result != null) {
      try {
        if (plan != null) {
          await _dbHelper.updateMealPlan(result);
        } else {
          await _dbHelper.createMealPlan(result);
        }
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(plan != null ? 'Plan updated successfully' : 'Plan created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _togglePlanComplete(MealPlan plan) async {
    final updatedPlan = MealPlan(
      id: plan.id,
      title: plan.title,
      description: plan.description,
      foodIds: plan.foodIds,
      startDate: plan.startDate,
      endDate: plan.endDate,
      targetCalories: plan.targetCalories,
      isCompleted: !plan.isCompleted,
    );

    try {
      await _dbHelper.updateMealPlan(updatedPlan);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food & Meal Planning'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Food Items'),
            Tab(text: 'Meal Plans'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFoodListView(),
          _buildMealPlansView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showFoodForm();
          } else {
            _showMealPlanForm();
          }
        },
        tooltip: _tabController.index == 0 ? 'Add New Food' : 'Create New Plan',
        child: Icon(_tabController.index == 0 ? Icons.add : Icons.add_task),
      ),
    );
  }

  Widget _buildFoodListView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search Foods',
              hintText: 'Search by name, category, or description',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _filterFoods,
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredFoods.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No foods available. Tap + to add new foods.'
                            : 'No foods found matching "$_searchQuery"',
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredFoods.length,
                      itemBuilder: (context, index) {
                        final food = _filteredFoods[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(food.imageUrl),
                              child: food.imageUrl.isEmpty
                                  ? const Icon(Icons.restaurant)
                                  : null,
                            ),
                            title: Text(food.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(food.category),
                                Text(
                                  '${food.calories} kcal',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () => _showFoodDetails(food),
                                  tooltip: 'View Details',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showFoodForm(food),
                                  tooltip: 'Edit Food',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteFood(food.id),
                                  tooltip: 'Delete Food',
                                ),
                              ],
                            ),
                            onTap: () => _showFoodDetails(food),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildMealPlansView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_plans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No meal plans yet.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showMealPlanForm(),
              child: const Text('Create Your First Plan'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _plans.length,
      itemBuilder: (context, index) {
        final plan = _plans[index];
        final planFoods = _foods
            .where((food) => plan.foodIds.contains(food.id))
            .toList();
        final totalCalories = planFoods.fold(
            0, (sum, food) => sum + food.calories);

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ExpansionTile(
            title: Text(plan.title),
            subtitle: Text(
              '${plan.startDate.toString().split(' ')[0]} - ${plan.endDate.toString().split(' ')[0]}',
            ),
            leading: CircleAvatar(
              backgroundColor: plan.isCompleted
                  ? Colors.green
                  : Theme.of(context).primaryColor,
              child: Icon(
                plan.isCompleted
                    ? Icons.check
                    : Icons.restaurant_menu,
                color: Colors.white,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Target: ${plan.targetCalories} calories per day',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Current Plan: $totalCalories calories per day',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Included Foods:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...planFoods.map((food) => ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(food.imageUrl),
                            child: food.imageUrl.isEmpty
                                ? const Icon(Icons.restaurant)
                                : null,
                          ),
                          title: Text(food.name),
                          subtitle: Text('${food.calories} kcal'),
                        )),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => _showMealPlanForm(plan),
                          child: const Text('Edit Plan'),
                        ),
                        ElevatedButton(
                          onPressed: () => _togglePlanComplete(plan),
                          child: Text(plan.isCompleted
                              ? 'Mark as In Progress'
                              : 'Mark as Completed'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 