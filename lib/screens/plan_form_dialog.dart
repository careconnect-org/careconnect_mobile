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
      title: Text(
        isEditing ? 'Edit Plan' : 'Create New Plan',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Plan Title',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: targetDurationController,
                      decoration: const InputDecoration(
                        labelText: 'Target Duration (minutes per week)',
                        prefixIcon: Icon(Icons.timer),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan Duration',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Start Date'),
                      subtitle: Text(
                        startDate?.toString().split(' ')[0] ?? 'Not set',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                      ),
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
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('End Date'),
                      subtitle: Text(
                        endDate?.toString().split(' ')[0] ?? 'Not set',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                      ),
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Sports for this Plan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ...widget.availableSports.map((sport) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: CheckboxListTile(
                            title: Text(
                              sport.title,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            subtitle: Row(
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${sport.duration} min',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.fitness_center,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  sport.difficulty,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
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
                          ),
                        )),
                  ],
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
        ElevatedButton.icon(
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
          icon: Icon(isEditing ? Icons.save : Icons.add),
          label: Text(isEditing ? 'Update' : 'Create'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
} 