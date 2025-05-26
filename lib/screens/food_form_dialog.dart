import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/food_item.dart';
import 'dart:io';

class FoodFormDialog extends StatefulWidget {
  final FoodItem? food;

  const FoodFormDialog({super.key, this.food});

  @override
  State<FoodFormDialog> createState() => _FoodFormDialogState();
}

class _FoodFormDialogState extends State<FoodFormDialog> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final categoryController = TextEditingController();
  final caloriesController = TextEditingController();
  final ingredientsController = TextEditingController();
  final recipeUrlController = TextEditingController();
  String? imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.food != null) {
      nameController.text = widget.food!.name;
      descriptionController.text = widget.food!.description;
      categoryController.text = widget.food!.category;
      caloriesController.text = widget.food!.calories.toString();
      ingredientsController.text = widget.food!.ingredients.join(', ');
      recipeUrlController.text = widget.food!.recipeUrl;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    caloriesController.dispose();
    ingredientsController.dispose();
    recipeUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => imagePath = pickedFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.food != null;

    return AlertDialog(
      title: Text(
        isEditing ? 'Edit Food' : 'Add New Food',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.restaurant),
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
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories',
                prefixIcon: Icon(Icons.local_fire_department),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ingredientsController,
              decoration: const InputDecoration(
                labelText: 'Ingredients (comma-separated)',
                prefixIcon: Icon(Icons.list),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: recipeUrlController,
              decoration: const InputDecoration(
                labelText: 'Recipe URL',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Add Image',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            if (imagePath != null || widget.food?.imageUrl.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(imagePath ?? widget.food!.imageUrl),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
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
            final newFood = FoodItem(
              id: widget.food?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              name: nameController.text,
              description: descriptionController.text,
              category: categoryController.text,
              calories: int.tryParse(caloriesController.text) ?? 0,
              ingredients: ingredientsController.text.split(',').map((e) => e.trim()).toList(),
              recipeUrl: recipeUrlController.text,
              imageUrl: imagePath ?? widget.food?.imageUrl ?? '',
            );
            Navigator.pop(context, newFood);
          },
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
} 