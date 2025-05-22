import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_screen.dart';
import 'package:careconnect/services/local_storage_service.dart';

class AvailablePatientsScreen extends StatefulWidget {
  const AvailablePatientsScreen({Key? key}) : super(key: key);

  @override
  State<AvailablePatientsScreen> createState() => _AvailablePatientsScreenState();
}

class _AvailablePatientsScreenState extends State<AvailablePatientsScreen> {
  List<Map<String, dynamic>> _patients = [];
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
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final token = await _getAuthToken();
      print('Token for request: ${token != null ? 'Token exists' : 'No token'}');
      
      if (token == null) {
        setState(() {
          _error = 'Please login to view available patients';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('https://careconnect-api-v2kw.onrender.com/api/patient/all'),
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
          final List<dynamic> patientsData = responseData['patients'] ?? [];
          
          setState(() {
            _patients = patientsData.map((patient) {
              final user = patient['user'] ?? {};
              return {
                'id': patient['_id']?.toString() ?? '',
                'name': '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim(),
                'email': user['email']?.toString() ?? '',
                'phone': user['phoneNumber']?.toString() ?? '',
                'image': user['image']?.toString() ?? '',
                'age': _calculateAge(user['dateOfBirth']),
                'gender': user['gender']?.toString() ?? 'Not specified',
                'bloodType': patient['bloodType']?.toString() ?? 'Not specified',
                'weight': patient['weight']?.toString() ?? 'Not specified',
                'height': patient['height']?.toString() ?? 'Not specified',
                'emergencyContact': patient['emergencyContact'] ?? {},
                'insurance': patient['insurance'] ?? {},
              };
            }).toList();
            _isLoading = false;
          });
        } catch (e) {
          setState(() {
            _error = 'Error parsing patient data: $e';
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
          _error = 'Failed to load patients. Status code: ${response.statusCode}';
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

  String _calculateAge(String? dateOfBirth) {
    if (dateOfBirth == null) return 'Not specified';
    try {
      final birthDate = DateTime.parse(dateOfBirth);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || 
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age.toString();
    } catch (e) {
      return 'Not specified';
    }
  }

  List<Map<String, dynamic>> get _filteredPatients {
    if (_searchQuery.isEmpty) return _patients;
    return _patients.where((patient) {
      final name = patient['name'].toString().toLowerCase();
      final email = patient['email'].toString().toLowerCase();
      final phone = patient['phone'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || 
             email.contains(query) || 
             phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Patients'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPatients,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone...',
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
                    : _filteredPatients.isEmpty
                        ? const Center(child: Text('No patients found'))
                        : ListView.builder(
                            itemCount: _filteredPatients.length,
                            itemBuilder: (context, index) {
                              final patient = _filteredPatients[index];
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
                                        builder: (context) => ChatScreen(
                                          doctor: patient,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundImage: patient['image'] != null
                                              ? NetworkImage(patient['image'])
                                              : null,
                                          child: patient['image'] == null
                                              ? const Icon(Icons.person, size: 30)
                                              : null,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                patient['name'],
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                patient['email'],
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                patient['phone'],
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.person,
                                                    color: Colors.blue,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  // Text(
                                                  //   '${patient['age']} years old',
                                                  //   style: const TextStyle(
                                                  //     color: Colors.grey,
                                                  //   ),
                                                  // ),
                                                  const SizedBox(width: 16),
                                                  const Icon(
                                                    Icons.bloodtype,
                                                    color: Colors.red,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    patient['bloodType'],
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