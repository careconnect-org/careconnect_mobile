import 'package:flutter/material.dart';
import 'package:careconnect/chatdetailscreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({super.key});

  @override
  State<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  List<Map<String, dynamic>> doctors = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> fetchDoctors() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        setState(() {
          error = 'Please login to view doctors';
          isLoading = false;
        });
        return;
      }

      print('Fetching doctors from API...');
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
          
          if (doctorsData.isEmpty) {
            setState(() {
              error = 'No doctors found';
              isLoading = false;
            });
            return;
          }

          setState(() {
            doctors = doctorsData.map((doctor) {
              final user = doctor['user'];
              final firstName = user != null ? user['firstName'] ?? '' : '';
              final lastName = user != null ? user['lastName'] ?? '' : '';
              final availableSlots = doctor['availableSlots'] as List?;
              final firstSlot = availableSlots != null && availableSlots.isNotEmpty ? availableSlots[0] : null;
              final from = firstSlot?['from'] ?? '9:00 AM';
              final to = firstSlot?['to'] ?? '5:00 PM';
              return {
                'name': '$firstName $lastName',
                'specialty': doctor['specialization'] ?? 'General Practitioner',
                'rating': 4.0, 
                'available': true, 
                'workingHours': '$from - $to',
                'image': user != null ? user['image'] ?? 'https://i.pravatar.cc/150?img=1' : 'https://i.pravatar.cc/150?img=1',
                'hospital': doctor['hospital'] ?? 'Not specified',
                'experience': doctor['yearsOfExperience'] ?? 0,
                'licenseNumber': doctor['licenseNumber'] ?? '',
              };
            }).toList();
            isLoading = false;
          });
        } catch (e) {
          print('Error parsing response: $e');
          setState(() {
            error = 'Error parsing doctor data: $e';
            isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          error = 'Session expired. Please login again.';
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load doctors. Status code: ${response.statusCode}\nResponse: ${response.body}';
          isLoading = false;
        });
      }
    } on TimeoutException {
      setState(() {
        error = 'Request timed out. Please check your internet connection and try again.';
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching doctors: $e');
      setState(() {
        error = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
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
            onPressed: () {
              setState(() {
                isLoading = true;
                error = '';
              });
              fetchDoctors();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 20),
                      if (error.contains('login'))
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to login screen
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: const Text('Go to Login'),
                        )
                      else
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                              error = '';
                            });
                            fetchDoctors();
                          },
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
                )
              : doctors.isEmpty
                  ? const Center(child: Text('No doctors available'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: doctors.length,
                      itemBuilder: (context, index) {
                        final doctor = doctors[index];
                        return _buildDoctorCard(context, doctor);
                      },
                    ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, Map<String, dynamic> doctor) {
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
                  // Doctor's Image
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundImage: NetworkImage(doctor['image']),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Doctor's Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor['name'],
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
                        _buildInfoRow(Icons.access_time, doctor['workingHours']),
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
                                    "${doctor['rating']}",
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
                                color: doctor['available'] ? Colors.green.shade100 : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: doctor['available'] ? Colors.green : Colors.red,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    doctor['available'] ? "Online" : "Offline",
                                    style: TextStyle(
                                      color: doctor['available'] ? Colors.green : Colors.red,
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
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              // Chat Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(doctor: doctor),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text(
                    "Start Chat",
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for info rows
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
