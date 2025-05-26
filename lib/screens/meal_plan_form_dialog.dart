import 'package:flutter/material.dart';
import '../models/meal_plan.dart';
import '../models/food_item.dart';

class MealPlanFormDialog extends StatefulWidget {
  final MealPlan? plan;
  final List<FoodItem> availableFoods;

  const MealPlanFormDialog({
    super.key,
    this.plan,
    required this.availableFoods,
  });

  @override
  State<MealPlanFormDialog> createState() => _MealPlanFormDialogState();
}

class _MealPlanFormDialogState extends State<MealPlanFormDialog> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final targetCaloriesController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  List<String> selectedFoodIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.plan != null) {
      titleController.text = widget.plan!.title;
      descriptionController.text = widget.plan!.description;
      targetCaloriesController.text = widget.plan!.targetCalories.toString();
      startDate = widget.plan!.startDate;
      endDate = widget.plan!.endDate;
      selectedFoodIds = List.from(widget.plan!.foodIds);
    } else {
      targetCaloriesController.text = '2000';
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    targetCaloriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.plan != null;

    return AlertDialog(
      title: Text(
        isEditing ? 'Edit Meal Plan' : 'Create New Meal Plan',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Plan Title',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: targetCaloriesController,
              decoration: const InputDecoration(
                labelText: 'Target Calories (per day)',
                prefixIcon: Icon(Icons.local_fire_department),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Text(
              'Plan Duration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: startDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => startDate = date);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Date'),
                        Text(
                          startDate?.toString().split(' ')[0] ?? 'Not set',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: startDate == null ? Colors.grey : null,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: endDate ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => endDate = date);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Date'),
                        Text(
                          endDate?.toString().split(' ')[0] ?? 'Not set',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: endDate == null ? Colors.grey : null,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Foods',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ...widget.availableFoods.map((food) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    title: Text(
                      food.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    subtitle: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${food.calories} cal',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.category,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          food.category,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    value: selectedFoodIds.contains(food.id),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedFoodIds.add(food.id);
                        } else {
                          selectedFoodIds.remove(food.id);
                        }
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (startDate == null || endDate == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select start and end dates')),
              );
              return;
            }
            final newPlan = MealPlan(
              id: widget.plan?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              title: titleController.text,
              description: descriptionController.text,
              foodIds: selectedFoodIds,
              startDate: startDate!,
              endDate: endDate!,
              targetCalories: int.tryParse(targetCaloriesController.text) ?? 2000,
            );
            Navigator.pop(context, newPlan);
          },
          child: Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }
} 