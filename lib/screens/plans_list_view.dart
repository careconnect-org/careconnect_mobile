import 'package:flutter/material.dart';
import '../models/fitness_plan.dart';
import '../models/sport_recommendation.dart';
import '../theme/app_theme.dart';

class PlansListView extends StatelessWidget {
  final List<FitnessPlan> plans;
  final List<SportRecommendation> sports;
  final bool isLoading;
  final Function() onCreatePlan;
  final Function(FitnessPlan) onEditPlan;
  final Function(FitnessPlan) onToggleComplete;

  const PlansListView({
    super.key,
    required this.plans,
    required this.sports,
    required this.isLoading,
    required this.onCreatePlan,
    required this.onEditPlan,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (plans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No fitness plans yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onCreatePlan,
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Plan'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        final planSports = sports
            .where((sport) => plan.sportIds.contains(sport.id))
            .toList();
        final totalDuration = planSports.fold(
            0, (sum, sport) => sum + sport.duration);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: plan.isCompleted
                  ? AppTheme.successColor
                  : Theme.of(context).colorScheme.primary,
              child: Icon(
                plan.isCompleted ? Icons.check : Icons.fitness_center,
                color: Colors.white,
              ),
            ),
            title: Text(
              plan.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            subtitle: Text(
              '${plan.startDate.toString().split(' ')[0]} - ${plan.endDate.toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodyMedium,
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
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Target: ${plan.targetDuration} minutes per week',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Current Plan: $totalDuration minutes per week',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Included Sports:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...planSports.map((sport) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              backgroundImage: sport.imageUrl.isNotEmpty
                                  ? NetworkImage(sport.imageUrl)
                                  : null,
                              child: sport.imageUrl.isEmpty
                                  ? Icon(
                                      Icons.sports,
                                      color: Theme.of(context).colorScheme.primary,
                                    )
                                  : null,
                            ),
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
                          ),
                        )),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => onEditPlan(plan),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Plan'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => onToggleComplete(plan),
                          icon: Icon(plan.isCompleted ? Icons.refresh : Icons.check),
                          label: Text(plan.isCompleted ? 'Mark as In Progress' : 'Mark as Completed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: plan.isCompleted
                                ? AppTheme.warningColor
                                : AppTheme.successColor,
                          ),
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