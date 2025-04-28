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
            doctors = doctorsData.map((doctor) => {
              'name': '${doctor['user']['firstName']} ${doctor['user']['lastName']}',
              'specialty': doctor['specialization'] ?? 'General Practitioner',
              'rating': 4.0, 
              'available': true, 
              'workingHours': '${doctor['availableSlots']?[0]['from'] ?? '9:00 AM'} - ${doctor['availableSlots']?[0]['to'] ?? '5:00 PM'}',
              'image': doctor['user']['image'] ?? 'https://i.pravatar.cc/150?img=1',
              'hospital': doctor['hospital'] ?? 'Not specified',
              'experience': doctor['yearsOfExperience'] ?? 0,
              'licenseNumber': doctor['licenseNumber'] ?? '',
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
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(doctor['image']),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        doctor['specialty'],
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        doctor['hospital'],
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        '${doctor['experience']} years of experience',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        doctor['workingHours'],
                        style: const TextStyle(fontSize: 12),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.orange, size: 16),
                          Text("${doctor['rating']}"),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.circle,
                            color: doctor['available'] ? Colors.green : Colors.red,
                            size: 10,
                          ),
                          Text(
                            doctor['available'] ? " Online" : " Offline",
                            style: TextStyle(
                              color: doctor['available']
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(doctor: doctor),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Chat"),
                  style: TextButton.styleFrom(foregroundColor: Colors.teal),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
