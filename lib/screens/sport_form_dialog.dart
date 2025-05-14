import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/sport_recommendation.dart';
import 'dart:io';

class SportFormDialog extends StatefulWidget {
  final SportRecommendation? sport;

  const SportFormDialog({super.key, this.sport});

  @override
  State<SportFormDialog> createState() => _SportFormDialogState();
}

class _SportFormDialogState extends State<SportFormDialog> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final categoryController = TextEditingController();
  final durationController = TextEditingController();
  final difficultyController = TextEditingController();
  final youtubeLinkController = TextEditingController();
  String? imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.sport != null) {
      titleController.text = widget.sport!.title;
      descriptionController.text = widget.sport!.description;
      categoryController.text = widget.sport!.category;
      durationController.text = widget.sport!.duration.toString();
      difficultyController.text = widget.sport!.difficulty;
      youtubeLinkController.text = widget.sport!.youtubeLink;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    durationController.dispose();
    difficultyController.dispose();
    youtubeLinkController.dispose();
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
    final isEditing = widget.sport != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Sport' : 'Add New Sport'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: durationController,
              decoration: const InputDecoration(labelText: 'Duration (minutes)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: difficultyController,
              decoration: const InputDecoration(labelText: 'Difficulty'),
            ),
            TextField(
              controller: youtubeLinkController,
              decoration: const InputDecoration(labelText: 'YouTube Link'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ],
            ),
            if (imagePath != null || widget.sport?.imageUrl.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Image.file(
                  File(imagePath ?? widget.sport!.imageUrl),
                  height: 100,
                  fit: BoxFit.cover,
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
            final newSport = SportRecommendation(
              id: widget.sport?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              title: titleController.text,
              description: descriptionController.text,
              category: categoryController.text,
              duration: int.tryParse(durationController.text) ?? 0,
              difficulty: difficultyController.text,
              youtubeLink: youtubeLinkController.text,
              imageUrl: imagePath ?? widget.sport?.imageUrl ?? '',
            );
            Navigator.pop(context, newSport);
          },
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
} 