import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MyFavoriteDoctorScreen extends StatefulWidget {
  @override
  _MyFavoriteDoctorScreenState createState() => _MyFavoriteDoctorScreenState();
}

class _MyFavoriteDoctorScreenState extends State<MyFavoriteDoctorScreen> {
  List<Map<String, dynamic>> doctors = [];
  bool isLoading = true;
  String error = '';
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    fetchFavoriteDoctors();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> fetchFavoriteDoctors() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        setState(() {
          error = 'Please login to view favorite doctors';
          isLoading = false;
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

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final List<dynamic> doctorsData = responseData['doctors'] ?? [];
          
          setState(() {
            doctors = doctorsData.map((doctor) => {
              'name': '${doctor['user']['firstName']} ${doctor['user']['lastName']}',
              'specialty': '${doctor['specialization']} | ${doctor['hospital']}',
              'rating': '4.5', // Default rating
              'reviews': '1,000', // Default reviews
              'image': doctor['user']['image'] ?? 'https://i.pravatar.cc/150?img=1',
              'hospital': doctor['hospital'] ?? 'Not specified',
              'experience': doctor['yearsOfExperience'] ?? 0,
              'licenseNumber': doctor['licenseNumber'] ?? '',
              'id': doctor['_id'],
            }).toList();
            isLoading = false;
          });
        } catch (e) {
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
          error = 'Failed to load doctors. Status code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  void _showRemoveDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Favorites?'),
        content: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(doctors[index]['image']),
              radius: 30,
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctors[index]['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  doctors[index]['specialty'],
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                doctors.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Yes, Remove'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get filteredDoctors {
    if (selectedFilter == 'All') {
      return doctors;
    }
    return doctors.where((doctor) => 
      doctor['specialty'].toLowerCase().contains(selectedFilter.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Favorite Doctors', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
                error = '';
              });
              fetchFavoriteDoctors();
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
                            fetchFavoriteDoctors();
                          },
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _buildFilterChip('All', selectedFilter == 'All'),
                          _buildFilterChip('Cardiologist', selectedFilter == 'Cardiologist'),
                          _buildFilterChip('Neurologist', selectedFilter == 'Neurologist'),
                          _buildFilterChip('Dermatologist', selectedFilter == 'Dermatologist'),
                        ],
                      ),
                    ),
                    if (filteredDoctors.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'No doctors found in this category',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredDoctors.length,
                          itemBuilder: (context, index) {
                            final doctor = filteredDoctors[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(doctor['image']),
                                radius: 30,
                              ),
                              title: Text(
                                doctor['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(doctor['specialty']),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.yellow, size: 16),
                                      const SizedBox(width: 4),
                                      Text('${doctor['rating']} (${doctor['reviews']} reviews)'),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.favorite, color: Colors.blue),
                                onPressed: () => _showRemoveDialog(index),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedFilter = label;
          });
        },
        child: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.blue,
          side: const BorderSide(color: Colors.blue),
        ),
      ),
    );
  }
}
