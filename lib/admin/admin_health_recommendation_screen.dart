import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/health_recommendation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminHealthRecommendationScreen extends StatefulWidget {
  @override
  _AdminHealthRecommendationScreenState createState() => _AdminHealthRecommendationScreenState();
}

class _AdminHealthRecommendationScreenState extends State<AdminHealthRecommendationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'diet';
  final List<String> _categories = ['diet', 'exercise', 'medication', 'lifestyle'];
  List<HealthRecommendation> _recommendations = [];
  List<Map<String, dynamic>> _patients = [];
  Map<String, dynamic>? _selectedPatient;
  bool _isLoading = true;
  bool _showForm = false;
  bool _isEditMode = false;
  int? _editingRecommendationId;

  // Set your API base URL here
  final String _apiBaseUrl = 'https://careconnect-api-v2kw.onrender.com'; 

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token'); // Use your actual key here
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/patient/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final patients = List<Map<String, dynamic>>.from(data['patients']);
        // Fetch recommendations from SQLite
        final db = DatabaseHelper.instance;
        final List<Map<String, dynamic>> recommendationMaps = await db.getRecommendations(null);
        setState(() {
          _patients = patients;
          _recommendations = recommendationMaps.map((map) => HealthRecommendation.fromMap(map)).toList();
          _isLoading = false;
        });
      } else {
        print('Failed to load patients: ${response.statusCode}');
        print('Response body: ${response.body}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _submitRecommendation() async {
    if (_formKey.currentState!.validate()) {
      if (_isEditMode && _editingRecommendationId != null) {
        // Update existing recommendation
        final updatedRecommendation = HealthRecommendation(
          id: _editingRecommendationId,
          title: _titleController.text,
          description: _descriptionController.text,
          category: _selectedCategory,
          createdAt: DateTime.now(),
          patientId: _selectedPatient?['_id'],
        );
        await DatabaseHelper.instance.updateRecommendation(updatedRecommendation.toMap());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recommendation updated for ${_selectedPatient?['user']?['firstName'] ?? 'user'}')),
          );
        }
      } else {
        // Add new recommendation
        final recommendation = HealthRecommendation(
          title: _titleController.text,
          description: _descriptionController.text,
          category: _selectedCategory,
          createdAt: DateTime.now(),
          patientId: _selectedPatient?['_id'],
        );
        await DatabaseHelper.instance.insertRecommendation(recommendation.toMap());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recommendation added for ${_selectedPatient?['user']?['firstName'] ?? 'user'}')),
          );
        }
      }
      _clearForm();
      _loadData();
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _selectedPatient = null;
    _selectedCategory = 'diet';
    _isEditMode = false;
    _editingRecommendationId = null;
    setState(() => _showForm = false);
  }

  void _editRecommendation(HealthRecommendation recommendation) {
    setState(() {
      _isEditMode = true;
      _showForm = true;
      _editingRecommendationId = recommendation.id;
      _titleController.text = recommendation.title;
      _descriptionController.text = recommendation.description;
      _selectedCategory = recommendation.category;
      
      // Find the patient or set to null if not found
      try {
        _selectedPatient = _patients.firstWhere(
          (p) => p['_id'] == recommendation.patientId,
        );
      } catch (e) {
        _selectedPatient = null;
      }
    });
  }

  Future<void> _deleteRecommendation(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Recommendation'),
        content: Text('Are you sure you want to delete this recommendation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteRecommendation(id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Health Recommendations', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildPatientList(),
    );
  }

  Widget _buildPatientList() {
    if (_patients.isEmpty) {
      return Center(child: Text('No patients found'));
    }
    return ListView.builder(
      itemCount: _patients.length,
      itemBuilder: (context, index) {
        final patient = _patients[index];
        final user = patient['user'];
        return Card(
          child: ListTile(
            leading: user != null && user['image'] != null
                ? CircleAvatar(backgroundImage: NetworkImage(user['image']))
                : const CircleAvatar(child: Icon(Icons.person)),
            title: Text('${user?['firstName'] ?? ''} ${user?['lastName'] ?? ''}'),
            subtitle: Text(user?['email'] ?? ''),
            onTap: () => _showRecommendationFormForPatient(patient),
          ),
        );
      },
    );
  }

  void _showRecommendationFormForPatient(Map<String, dynamic> patient) {
    setState(() {
      _selectedPatient = patient;
      _showForm = true;
      _isEditMode = false;
      _editingRecommendationId = null;
      _titleController.clear();
      _descriptionController.clear();
      _selectedCategory = 'diet';
    });
    // Show the form as a modal or navigate to a new page if you prefer
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: _buildForm(),
      ),
    ).whenComplete(() {
      setState(() {
        _showForm = false;
        _selectedPatient = null;
      });
    });
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            _buildPatientSelector(),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category.capitalize()),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitRecommendation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Add Recommendation'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Patient (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final selected = await showDialog<Map<String, dynamic>>(
              context: context,
              builder: (context) => PatientPickerDialog(patients: _patients, selected: _selectedPatient),
            );
            if (selected != null) {
              setState(() {
                _selectedPatient = selected;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _selectedPatient != null && _selectedPatient!['user']?['image'] != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(_selectedPatient!['user']['image']),
                        radius: 16,
                      )
                    : const CircleAvatar(radius: 16, child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedPatient != null
                        ? '${_selectedPatient!['user']['firstName']} ${_selectedPatient!['user']['lastName']} (${_selectedPatient!['user']['email']})'
                        : 'General Recommendation',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsList() {
    if (_recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 50, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No recommendations yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = _recommendations[index];
        return Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(recommendation.category),
                color: Colors.blue[700],
              ),
            ),
            title: Text(
              recommendation.title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recommendation.description),
                SizedBox(height: 4),
                Text(
                  'Category: ${recommendation.category}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (recommendation.patientId != null)
                  Text(
                    'Patient ID: ${recommendation.patientId}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                Text(
                  'Date: ${recommendation.createdAt.toString().split(' ')[0]}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _editRecommendation(recommendation),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteRecommendation(recommendation.id!),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'diet':
        return Icons.restaurant;
      case 'exercise':
        return Icons.directions_run;
      case 'medication':
        return Icons.medical_services;
      case 'lifestyle':
        return Icons.self_improvement;
      default:
        return Icons.info;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

class PatientApiService {
  final String baseUrl;

  PatientApiService({required this.baseUrl});

  Future<List<Map<String, dynamic>>> fetchAllPatients() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/patient/all'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer YOUR_TOKEN', // <-- Make sure this is set!
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['patients']);
    } else {
      throw Exception('Failed to load patients');
    }
  }
}

class PatientPickerDialog extends StatelessWidget {
  final List<Map<String, dynamic>> patients;
  final Map<String, dynamic>? selected;

  const PatientPickerDialog({required this.patients, this.selected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: patients.length,
          itemBuilder: (context, index) {
            final patient = patients[index];
            final user = patient['user'];
            return ListTile(
              leading: user != null && user['image'] != null
                  ? CircleAvatar(backgroundImage: NetworkImage(user['image']))
                  : const CircleAvatar(child: Icon(Icons.person)),
              title: Text('${user?['firstName'] ?? ''} ${user?['lastName'] ?? ''}'),
              subtitle: Text(user?['email'] ?? ''),
              selected: selected?['_id'] == patient['_id'],
              onTap: () => Navigator.pop(context, patient),
            );
          },
        ),
      ),
    );
  }
} 