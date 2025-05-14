import 'package:flutter/material.dart';
import '../models/fitness_plan.dart';
import '../models/sport_recommendation.dart';

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
            const Text('No fitness plans yet.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onCreatePlan,
              child: const Text('Create Your First Plan'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        final planSports = sports
            .where((sport) => plan.sportIds.contains(sport.id))
            .toList();
        final totalDuration = planSports.fold(
            0, (sum, sport) => sum + sport.duration);

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
                    : Icons.fitness_center,
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
                      'Target: ${plan.targetDuration} minutes per week',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Current Plan: $totalDuration minutes per week',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Included Sports:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...planSports.map((sport) => ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(sport.imageUrl),
                            child: sport.imageUrl.isEmpty
                                ? const Icon(Icons.sports)
                                : null,
                          ),
                          title: Text(sport.title),
                          subtitle: Text(
                              '${sport.duration} min • ${sport.difficulty}'),
                        )),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => onEditPlan(plan),
                          child: const Text('Edit Plan'),
                        ),
                        ElevatedButton(
                          onPressed: () => onToggleComplete(plan),
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