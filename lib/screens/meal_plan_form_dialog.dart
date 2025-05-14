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
      title: Text(isEditing ? 'Edit Plan' : 'Create New Plan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Plan Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            TextField(
              controller: targetCaloriesController,
              decoration: const InputDecoration(
                labelText: 'Target Calories (per day)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(startDate?.toString().split(' ')[0] ?? 'Not set'),
              trailing: const Icon(Icons.calendar_today),
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
            ),
            ListTile(
              title: const Text('End Date'),
              subtitle: Text(endDate?.toString().split(' ')[0] ?? 'Not set'),
              trailing: const Icon(Icons.calendar_today),
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
            ),
            const SizedBox(height: 16),
            const Text('Select Foods for this Plan:'),
            ...widget.availableFoods.map((food) => CheckboxListTile(
              title: Text(food.name),
              subtitle: Text('${food.calories} kcal • ${food.category}'),
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