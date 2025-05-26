import 'package:flutter/material.dart';
import '../models/sport_recommendation.dart';

class SportsListView extends StatelessWidget {
  final List<SportRecommendation> sports;
  final bool isLoading;
  final String searchQuery;
  final Function(String) onSearch;
  final Function(SportRecommendation) onViewDetails;
  final Function(SportRecommendation) onEdit;
  final Function(String) onDelete;

  const SportsListView({
    super.key,
    required this.sports,
    required this.isLoading,
    required this.searchQuery,
    required this.onSearch,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search Sports',
              hintText: 'Search by title, category, or description',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: onSearch,
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : sports.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isEmpty
                                ? 'No sports available'
                                : 'No sports found matching "$searchQuery"',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          if (searchQuery.isEmpty)
                            ElevatedButton.icon(
                              onPressed: () => onEdit(SportRecommendation(
                                id: '',
                                title: '',
                                description: '',
                                category: '',
                                duration: 0,
                                difficulty: '',
                                youtubeLink: '',
                                imageUrl: '',
                              )),
                              icon: const Icon(Icons.add),
                              label: const Text('Add New Sport'),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: sports.length,
                      itemBuilder: (context, index) {
                        final sport = sports[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              radius: 24,
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
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  sport.category,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Row(
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
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () => onViewDetails(sport),
                                  tooltip: 'View Details',
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => onEdit(sport),
                                  tooltip: 'Edit Sport',
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => onDelete(sport.id),
                                  tooltip: 'Delete Sport',
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ],
                            ),
                            onTap: () => onViewDetails(sport),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
} 