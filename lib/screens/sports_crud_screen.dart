import 'package:flutter/material.dart';
import '../models/sport_recommendation.dart';
import '../models/fitness_plan.dart';
import '../database_helper.dart';
import 'sports_list_view.dart';
import 'plans_list_view.dart';
import 'sport_form_dialog.dart';
import 'plan_form_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SportsCrudScreen extends StatefulWidget {
  const SportsCrudScreen({super.key});

  @override
  State<SportsCrudScreen> createState() => _SportsCrudScreenState();
}

class _SportsCrudScreenState extends State<SportsCrudScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<SportRecommendation> _sports = [];
  List<SportRecommendation> _filteredSports = [];
  List<FitnessPlan> _plans = [];
  bool _isLoading = true;
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: 0,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final sports = await _dbHelper.getAllSports();
      final plans = await _dbHelper.getAllPlans();
      setState(() {
        _sports = sports;
        _filteredSports = sports;
        _plans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    }
  }

  void _filterSports(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSports = _sports;
      } else {
        _filteredSports = _sports.where((sport) {
          return sport.title.toLowerCase().contains(query.toLowerCase()) ||
              sport.category.toLowerCase().contains(query.toLowerCase()) ||
              sport.description.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _showSportForm([SportRecommendation? sport]) async {
    final result = await showDialog<SportRecommendation>(
      context: context,
      builder: (context) => SportFormDialog(sport: sport),
    );

    if (result != null) {
      try {
        if (sport != null) {
          await _dbHelper.updateSport(result);
        } else {
          await _dbHelper.createSport(result);
        }
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(sport != null ? 'Sport updated successfully' : 'Sport added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showSportDetails(SportRecommendation sport) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sport.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sport.imageUrl.isNotEmpty)
                Image.network(
                  sport.imageUrl,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 16),
              Text(
                sport.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text('Category: ${sport.category}'),
              Text('Duration: ${sport.duration} minutes'),
              Text('Difficulty: ${sport.difficulty}'),
              if (sport.youtubeLink.isNotEmpty) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(sport.youtubeLink);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not launch YouTube link')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Watch on YouTube'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSport(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sport'),
        content: const Text('Are you sure you want to delete this sport?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbHelper.deleteSport(id);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sport deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showPlanForm([FitnessPlan? plan]) async {
    final result = await showDialog<FitnessPlan>(
      context: context,
      builder: (context) => PlanFormDialog(
        plan: plan,
        availableSports: _sports,
      ),
    );

    if (result != null) {
      try {
        if (plan != null) {
          await _dbHelper.updatePlan(result);
        } else {
          await _dbHelper.createPlan(result);
        }
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(plan != null ? 'Plan updated successfully' : 'Plan created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _togglePlanComplete(FitnessPlan plan) async {
    final updatedPlan = FitnessPlan(
      id: plan.id,
      title: plan.title,
      description: plan.description,
      sportIds: plan.sportIds,
      startDate: plan.startDate,
      endDate: plan.endDate,
      targetDuration: plan.targetDuration,
      isCompleted: !plan.isCompleted,
    );

    try {
      await _dbHelper.updatePlan(updatedPlan);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Planning'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sports'),
            Tab(text: 'My Plans'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SportsListView(
            sports: _filteredSports,
            isLoading: _isLoading,
            searchQuery: _searchQuery,
            onSearch: _filterSports,
            onViewDetails: _showSportDetails,
            onEdit: _showSportForm,
            onDelete: _deleteSport,
          ),
          PlansListView(
            plans: _plans,
            sports: _sports,
            isLoading: _isLoading,
            onCreatePlan: () => _showPlanForm(),
            onEditPlan: _showPlanForm,
            onToggleComplete: _togglePlanComplete,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showSportForm();
          } else {
            _showPlanForm();
          }
        },
        tooltip: _tabController.index == 0 ? 'Add New Sport' : 'Create New Plan',
        child: Icon(_tabController.index == 0 ? Icons.add : Icons.add_task),
      ),
    );
  }
} 