import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:careconnect/services/local_storage_service.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({Key? key}) : super(key: key);

  @override
  _DoctorScreenState createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;
  String _error = '';
  String _searchQuery = '';

  Future<String?> _getAuthToken() async {
    try {
      final token = await LocalStorageService.getAuthToken();
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
          print("_doctors%%%%%%%%%%%%%%%:$_doctors");
          print("doctorsData%%%%%%%%%%%%%%%: $doctorsData");

          setState(() {
            _doctors = doctorsData.map((doctor) {
              // Safely access nested user data with null checks
              final userData = doctor['user'] as Map<String, dynamic>?;
              final firstName = userData?['firstName']?.toString() ?? '';
              final lastName = userData?['lastName']?.toString() ?? '';

              return {
                'id': doctor['_id']?.toString() ?? '',
                'userId': userData?['_id']?.toString() ?? '',
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Our Doctors",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
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
                filled: true,
                fillColor: Colors.grey.shade50,
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
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 20),
                            if (_error.contains('login'))
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(context, '/login');
                                },
                                child: const Text('Go to Login'),
                              )
                            else
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isLoading = true;
                                    _error = '';
                                  });
                                  _fetchDoctors();
                                },
                                child: const Text('Retry'),
                              ),
                          ],
                        ),
                      )
                    : _filteredDoctors.isEmpty
                        ? const Center(child: Text('No doctors available'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredDoctors.length,
                            itemBuilder: (context, index) {
                              final doctor = _filteredDoctors[index];
                              return _buildDoctorCard(doctor);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.blue.shade50],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundImage: doctor['image'] != null && doctor['image'].isNotEmpty
                          ? NetworkImage(doctor['image'])
                          : null,
                      child: doctor['image'] == null || doctor['image'].isEmpty
                          ? const Icon(Icons.person, size: 35)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${doctor['name']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            doctor['specialty'],
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.location_on, doctor['hospital']),
                        const SizedBox(height: 4),
                        _buildInfoRow(Icons.work, '${doctor['experience']} years experience'),
                        const SizedBox(height: 4),
                        // _buildInfoRow(Icons.school, doctor['qualification']),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Colors.orange, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    "4.0",
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: doctor['availability'] ? Colors.green.shade100 : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: doctor['availability'] ? Colors.green : Colors.red,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    doctor['availability'] ? "Available" : "Unavailable",
                                    style: TextStyle(
                                      color: doctor['availability'] ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
} 