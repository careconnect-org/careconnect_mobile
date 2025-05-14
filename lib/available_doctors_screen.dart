import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvailableDoctorsScreen extends StatefulWidget {
  const AvailableDoctorsScreen({Key? key}) : super(key: key);

  @override
  State<AvailableDoctorsScreen> createState() => _AvailableDoctorsScreenState();
}

class _AvailableDoctorsScreenState extends State<AvailableDoctorsScreen> {
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;
  String _error = '';
  String _searchQuery = '';

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print('Retrieved token: ${token != null ? 'Token exists' : 'No token found'}');
      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final token = await _getAuthToken();
      print('Token for request: ${token != null ? 'Token exists' : 'No token'}');
      
      if (token == null) {
        setState(() {
          _error = 'Please login to view available doctors';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('https://careconnect-api-v2kw.onrender.com/api/doctor/all'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final List<dynamic> doctorsData = responseData['doctors'] ?? [];
          
          setState(() {
            _doctors = doctorsData.map((doctor) {
              // Safely access nested user data with null checks
              final userData = doctor['user'] as Map<String, dynamic>?;
              final firstName = userData?['firstName']?.toString() ?? '';
              final lastName = userData?['lastName']?.toString() ?? '';
              
              return {
                'id': doctor['_id']?.toString() ?? '',
                'name': '$firstName $lastName'.trim(),
                'specialty': doctor['specialization']?.toString() ?? 'General',
                'image': userData?['image']?.toString() ?? '',
                'email': userData?['email']?.toString() ?? '',
                'phone': userData?['phone']?.toString() ?? '',
                'experience': doctor['yearsOfExperience']?.toString() ?? '0',
                'qualification': doctor['qualification']?.toString() ?? '',
                'availability': doctor['availability'] ?? true,
                'hospital': doctor['hospital']?.toString() ?? 'Not specified',
                'licenseNumber': doctor['licenseNumber']?.toString() ?? '',
              };
            }).toList();
            _isLoading = false;
          });
        } catch (e) {
          setState(() {
            _error = 'Error parsing doctor data: $e';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _error = 'Session expired. Please login again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load doctors. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredDoctors {
    if (_searchQuery.isEmpty) return _doctors;
    return _doctors.where((doctor) {
      final name = doctor['name'].toString().toLowerCase();
      final specialty = doctor['specialty'].toString().toLowerCase();
      final qualification = doctor['qualification'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || 
             specialty.contains(query) || 
             qualification.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Doctors'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDoctors,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, specialty, or qualification...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(child: Text(_error))
                    : _filteredDoctors.isEmpty
                        ? const Center(child: Text('No doctors found'))
                        : ListView.builder(
                            itemCount: _filteredDoctors.length,
                            itemBuilder: (context, index) {
                              final doctor = _filteredDoctors[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(doctor: doctor),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundImage: doctor['image'] != null
                                              ? NetworkImage(doctor['image'])
                                              : null,
                                          child: doctor['image'] == null
                                              ? const Icon(Icons.person, size: 30)
                                              : null,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                doctor['name'],
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                doctor['specialty'],
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                doctor['qualification'],
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${doctor['experience']} years experience',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.message,
                                          color: Colors.blue,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
} 