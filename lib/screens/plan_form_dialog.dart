import 'package:flutter/material.dart';
import '../models/fitness_plan.dart';
import '../models/sport_recommendation.dart';

class PlanFormDialog extends StatefulWidget {
  final FitnessPlan? plan;
  final List<SportRecommendation> availableSports;

  const PlanFormDialog({
    super.key,
    this.plan,
    required this.availableSports,
  });

  @override
  State<PlanFormDialog> createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends State<PlanFormDialog> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final targetDurationController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  List<String> selectedSportIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.plan != null) {
      titleController.text = widget.plan!.title;
      descriptionController.text = widget.plan!.description;
      targetDurationController.text = widget.plan!.targetDuration.toString();
      startDate = widget.plan!.startDate;
      endDate = widget.plan!.endDate;
      selectedSportIds = List.from(widget.plan!.sportIds);
    } else {
      targetDurationController.text = '150';
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    targetDurationController.dispose();
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
              controller: targetDurationController,
              decoration: const InputDecoration(
                labelText: 'Target Duration (minutes per week)',
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
            const Text('Select Sports for this Plan:'),
            ...widget.availableSports.map((sport) => CheckboxListTile(
              title: Text(sport.title),
              subtitle: Text('${sport.duration} min • ${sport.difficulty}'),
              value: selectedSportIds.contains(sport.id),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    selectedSportIds.add(sport.id);
                  } else {
                    selectedSportIds.remove(sport.id);
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
            final newPlan = FitnessPlan(
              id: widget.plan?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              title: titleController.text,
              description: descriptionController.text,
              sportIds: selectedSportIds,
              startDate: startDate!,
              endDate: endDate!,
              targetDuration: int.tryParse(targetDurationController.text) ?? 150,
            );
            Navigator.pop(context, newPlan);
          },
          child: Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }
} 