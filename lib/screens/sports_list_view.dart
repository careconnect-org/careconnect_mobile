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
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search Sports',
              hintText: 'Search by title, category, or description',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: onSearch,
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : sports.isEmpty
                  ? Center(
                      child: Text(
                        searchQuery.isEmpty
                            ? 'No sports available. Tap + to add new sports.'
                            : 'No sports found matching "$searchQuery"',
                      ),
                    )
                  : ListView.builder(
                      itemCount: sports.length,
                      itemBuilder: (context, index) {
                        final sport = sports[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(sport.imageUrl),
                              child: sport.imageUrl.isEmpty
                                  ? const Icon(Icons.sports)
                                  : null,
                            ),
                            title: Text(sport.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sport.category),
                                Text(
                                  '${sport.duration} min • ${sport.difficulty}',
                                  style: Theme.of(context).textTheme.bodySmall,
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
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => onEdit(sport),
                                  tooltip: 'Edit Sport',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => onDelete(sport.id),
                                  tooltip: 'Delete Sport',
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