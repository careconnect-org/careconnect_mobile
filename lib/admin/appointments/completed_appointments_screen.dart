import 'package:careconnect/admin/appointments/appointment_form.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'appointment_utils.dart';
import 'appointment_detail_screen.dart';
import 'package:careconnect/services/local_storage_service.dart';

/// Utility to fetch and cache usernames by user ID
class UserFetcher {
  static final Map<String, String> _usernameCache = {};
  static List<Map<String, dynamic>>? _doctorsCache;
  static DateTime? _lastFetchTime;

  static Future<void> _fetchDoctors(String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://careconnect-api-v2kw.onrender.com/api/doctor/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('doctors')) {
          _doctorsCache = List<Map<String, dynamic>>.from(data['doctors']);
          _lastFetchTime = DateTime.now();
          
          // Pre-populate username cache
          for (var doctor in _doctorsCache!) {
            if (doctor['user'] != null && doctor['user'] is Map) {
              final userId = doctor['user']['_id'];
              final username = doctor['user']['username'] ?? 
                             doctor['user']['firstName'] ?? 
                             'Unknown';
              _usernameCache[userId] = username;
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching doctors: $e');
    }
  }

  static Future<String> getUsername(String userId, String token) async {
    // Refresh cache if it's older than 5 minutes or doesn't exist
    if (_doctorsCache == null || 
        _lastFetchTime == null || 
        DateTime.now().difference(_lastFetchTime!).inMinutes > 5) {
      await _fetchDoctors(token);
    }

    // Check cache first
    if (_usernameCache.containsKey(userId)) {
      return _usernameCache[userId]!;
    }

    // If not in cache, try to find in doctors list
    if (_doctorsCache != null) {
      for (var doctor in _doctorsCache!) {
        if (doctor['user'] != null && 
            doctor['user'] is Map && 
            doctor['user']['_id'] == userId) {
          final username = doctor['user']['username'] ?? 
                         doctor['user']['firstName'] ?? 
                         'Unknown';
          _usernameCache[userId] = username;
          return username;
        }
      }
    }

    return 'Unknown';
  }
}

/// Widget to show doctor's username (even if only an ID is provided)
class DoctorUsernameText extends StatelessWidget {
  final dynamic doctor;
  final String token;

  const DoctorUsernameText({super.key, required this.doctor, required this.token});

  @override
  Widget build(BuildContext context) {
    if (doctor is Map) {
      if (doctor['user'] is Map && doctor['user']['username'] != null) {
        final username = doctor['user']['username'];
        final specialization = doctor['specialization'] ?? '';
        return Text('Dr. $username${specialization.isNotEmpty ? " - $specialization" : ""}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            overflow: TextOverflow.ellipsis);
      } else if (doctor['user'] is String) {
        // doctor['user'] is an ID
        return _UsernameFuture(userId: doctor['user'], specialization: doctor['specialization'], token: token);
      } else if (doctor['username'] != null) {
        // Direct username in doctor object
        final username = doctor['username'];
        final specialization = doctor['specialization'] ?? '';
        return Text('Dr. $username${specialization.isNotEmpty ? " - $specialization" : ""}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            overflow: TextOverflow.ellipsis);
      }
    } else if (doctor is String) {
      // doctor is just an ID
      return _UsernameFuture(userId: doctor, specialization: null, token: token);
    }
    return const Text('Dr. Unknown',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18));
  }
}

class _UsernameFuture extends StatelessWidget {
  final String userId;
  final String? specialization;
  final String token;

  const _UsernameFuture({required this.userId, required this.specialization, required this.token});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: UserFetcher.getUsername(userId, token),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Dr. ...',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18));
        }
        if (snapshot.hasError) {
          return const Text('Dr. Unknown',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18));
        }
        final username = snapshot.data ?? 'Unknown';
        return Text(
            'Dr. $username${(specialization != null && specialization!.isNotEmpty) ? " - $specialization" : ""}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            overflow: TextOverflow.ellipsis);
      },
    );
  }
}

class CompletedAppointmentsScreen extends StatefulWidget {
  const CompletedAppointmentsScreen({super.key});

  @override
  State<CompletedAppointmentsScreen> createState() =>
      _CompletedAppointmentsScreenState();
}

class _CompletedAppointmentsScreenState
    extends State<CompletedAppointmentsScreen> {
  List<Map<String, dynamic>> completedAppointments = [];
  bool isLoading = true;
  String? selectedDoctor;
  String? selectedType;
  DateTime? selectedDate;
  List<String> doctorsList = [];
  final List<String> typeOptions = [
    'All',
    'Video Call',
    'Voice Call',
    'Messaging'
  ];

  @override
  void initState() {
    super.initState();
    fetchUpcomingAppointments();
  }

  Future<void> fetchUpcomingAppointments() async {
    setState(() {
      isLoading = true;
    });

    final token = await LocalStorageService.getAuthToken();
    if (token == null) return;

    try {
      // Get all appointments
      final response = await http.get(
        Uri.parse('https://careconnect-api-v2kw.onrender.com/api/appointment/all'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> allAppointments = [];

        // Handle different response formats (both Map and List)
        if (responseData is List) {
          // If the response is already a list
          allAppointments = responseData;
        } else if (responseData is Map && responseData.containsKey('appointments')) {
          // If the response is a map with an 'appointments' key
          allAppointments = responseData['appointments'] as List<dynamic>;
        } else if (responseData is Map && responseData.containsKey('data')) {
          // If the response is a map with a 'data' key
          allAppointments = responseData['data'] as List<dynamic>;
        } else if (responseData is Map) {
          // If the response is a map but doesn't have standard keys, try to find a list
          for (var value in responseData.values) {
            if (value is List) {
              allAppointments = value;
              break;
            }
          }

          // If we still couldn't find a list, create a single-item list with the map
          if (allAppointments.isEmpty && responseData.containsKey('_id')) {
            allAppointments = [responseData];
          }
        }

        // Filter for completed appointments
        completedAppointments = allAppointments
            .where((appointment) => appointment['status'] == 'Completed')
            .cast<Map<String, dynamic>>()
            .toList();

        // Extract unique doctor names, handling nested objects
        Set<String> doctors = {};
        for (var appt in completedAppointments) {
          if (appt['doctor'] != null) {
            String doctorName = '';
            if (appt['doctor'] is Map) {
              // Handle nested doctor object
              var doctorObj = appt['doctor'];
              if (doctorObj.containsKey('user')) {
                if (doctorObj['user'] is Map) {
                  String firstName = doctorObj['user']['firstName'] ?? '';
                  String lastName = doctorObj['user']['lastName'] ?? '';
                  doctorName = '$firstName $lastName'.trim();
                } else if (doctorObj['user'] is String) {
                  doctorName = doctorObj['user'];
                }
              }
              // Add specialization if available
              if (doctorObj.containsKey('specialization')) {
                String specialization = doctorObj['specialization'];
                if (doctorName.isNotEmpty) {
                  doctorName = 'Dr. $doctorName - $specialization';
                } else {
                  doctorName = 'Dr. Unknown - $specialization';
                }
              }
            } else {
              // Handle simple string
              doctorName = appt['doctor'].toString();
            }

            if (doctorName.isNotEmpty) {
              doctors.add(doctorName);
            }
          }
        }
        doctorsList = ['All', ...doctors.toList()];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to load appointments: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error fetching completed appointments: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> filterAppointments() async {
    setState(() {
      isLoading = true;
    });

    final token = await LocalStorageService.getAuthToken();
    if (token == null) return;

    // Create filter parameters
    Map<String, dynamic> filterParams = {
      'status': 'Upcoming,Pending' // Multiple statuses
    };

    if (selectedDoctor != null && selectedDoctor != 'All') {
      filterParams['doctor'] = selectedDoctor;
    }
    if (selectedType != null && selectedType != 'All') {
      filterParams['type'] = selectedType;
    }
    if (selectedDate != null) {
      filterParams['date'] = DateFormat('yyyy-MM-dd').format(selectedDate!);
    }

    try {
      final Uri uri = Uri.parse(
              'https://careconnect-api-v2kw.onrender.com/api/appointment/filter')
          .replace(
              queryParameters: filterParams
                  .map((key, value) => MapEntry(key, value.toString())));

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> filteredAppointments = [];

        // Handle different response formats (both Map and List)
        if (responseData is List) {
          // If the response is already a list
          filteredAppointments = responseData;
        } else if (responseData is Map &&
            responseData.containsKey('appointments')) {
          // If the response is a map with an 'appointments' key
          filteredAppointments = responseData['appointments'] as List<dynamic>;
        } else if (responseData is Map && responseData.containsKey('data')) {
          // If the response is a map with a 'data' key
          filteredAppointments = responseData['data'] as List<dynamic>;
        } else if (responseData is Map) {
          // If the response is a map but doesn't have standard keys, try to find a list
          for (var value in responseData.values) {
            if (value is List) {
              filteredAppointments = value;
              break;
            }
          }

          // If we still couldn't find a list, create a single-item list with the map
          if (filteredAppointments.isEmpty && responseData.containsKey('_id')) {
            filteredAppointments = [responseData];
          }
        }

        setState(() {
          completedAppointments =
              filteredAppointments.cast<Map<String, dynamic>>().toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to filter appointments')),
        );
      }
    } catch (e) {
      print('################## Filter error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Upcoming Appointments'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Doctor dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Doctor',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedDoctor,
                      items: doctorsList.map((String doctor) {
                        return DropdownMenuItem<String>(
                          value: doctor,
                          child: Text(doctor),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedDoctor = value;
                        });
                      },
                      hint: const Text('Select Doctor'),
                    ),
                    const SizedBox(height: 15),

                    // Type dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedType,
                      items: typeOptions.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedType = value;
                        });
                      },
                      hint: const Text('Select Type'),
                    ),
                    const SizedBox(height: 15),

                    // Date field
                    InkWell(
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedDate != null
                                  ? DateFormat('yyyy-MM-dd')
                                      .format(selectedDate!)
                                  : 'Select Date',
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                // Clear filters button
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedDoctor = null;
                      selectedType = null;
                      selectedDate = null;
                    });
                  },
                  child: const Text('Clear Filters'),
                ),
                // Apply button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    filterAppointments();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Function to get doctor name from appointment
  String _getDoctorName(Map<String, dynamic> appointment) {
    if (appointment['doctor'] is Map) {
      var doctor = appointment['doctor'];
      String doctorName = '';
      String specialization = '';

      // Get doctor's name from user object
      if (doctor.containsKey('user') && doctor['user'] is Map) {
        String firstName = doctor['user']['firstName'] ?? '';
        String lastName = doctor['user']['lastName'] ?? '';
        doctorName = '$firstName $lastName'.trim();
      }

      // Get specialization
      if (doctor.containsKey('specialization')) {
        specialization = doctor['specialization'];
      }

      // Return combined name and specialization
      if (doctorName.isNotEmpty && specialization.isNotEmpty) {
        return 'Dr. $doctorName - $specialization';
      } else if (doctorName.isNotEmpty) {
        return 'Dr. $doctorName';
      } else if (specialization.isNotEmpty) {
        return 'Dr. Unknown - $specialization';
      }
      return 'Unknown Doctor';
    }
    return appointment['doctor']?.toString() ?? 'No doctor';
  }

  // Function to get patient name from appointment
  String _getPatientName(Map<String, dynamic> appointment) {
    if (appointment['patient'] is Map) {
      var patient = appointment['patient'];
      if (patient.containsKey('user')) {
        return patient['user'] ?? 'Unknown User';
      }
      return 'Unknown Patient';
    }
    return appointment['patient']?.toString() ?? 'No patient';
  }

  // Build a custom appointment card for the new data structure
  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: () {
          // Navigate to appointment detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentDetailScreen(
                appointment: appointment,
                onAppointmentUpdated: () {
                  fetchUpcomingAppointments();
                },
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FutureBuilder<String?>(
                      future: LocalStorageService.getAuthToken(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Text('Dr. ...',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18));
                        }
                        return DoctorUsernameText(
                          doctor: appointment['doctor'],
                          token: snapshot.data!,
                        );
                      },
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String value) async {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentDetailScreen(
                              appointment: appointment,
                              onAppointmentUpdated: () {
                                fetchUpcomingAppointments();
                              },
                            ),
                          ),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'view',
                        child: Text('View Details'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'status',
                        child: Text('Update Status'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child:
                            Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, color: Colors.blue.shade300, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _getPatientName(appointment),
                      style: TextStyle(color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Get icon based on specialization if available
                  appointment['doctor'] is Map &&
                          appointment['doctor'].containsKey('specialization')
                      ? _getSpecializationIcon(
                          appointment['doctor']['specialization'])
                      : const Icon(Icons.medical_services, color: Colors.teal),
                  const SizedBox(width: 6),
                  Text(
                    appointment['reason'] ?? 'No reason provided',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                          appointment['status']?.toString() ?? ''),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appointment['status']?.toString() ?? 'N/A',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.event, color: Colors.orange.shade300, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(appointment['date']),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.access_time,
                      color: Colors.purple.shade300, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    appointment['timeSlot'] ?? 'No time',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Format date string from ISO to readable format
  String _formatDate(dynamic date) {
    if (date == null) return 'No date';

    try {
      if (date is String) {
        final DateTime parsedDate = DateTime.parse(date);
        return DateFormat('MMM dd, yyyy').format(parsedDate);
      } else if (date is Map && date.containsKey('date')) {
        final DateTime parsedDate = DateTime.parse(date['date']);
        return DateFormat('MMM dd, yyyy').format(parsedDate);
      }
    } catch (e) {
      print('Error formatting date: $e');
    }

    return date.toString();
  }

  // Get icon based on doctor specialization
  Icon _getSpecializationIcon(String specialization) {
    switch (specialization.toLowerCase()) {
      case 'cardiologist':
        return Icon(Icons.favorite, color: Colors.red.shade400);
      case 'neurologist':
        return Icon(Icons.psychology, color: Colors.blue.shade400);
      case 'pediatrician':
        return Icon(Icons.child_care, color: Colors.green.shade400);
      case 'dermatologist':
        return Icon(Icons.face, color: Colors.orange.shade400);
      default:
        return const Icon(Icons.medical_services, color: Colors.teal);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Upcoming':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Show status update options
  void _showStatusUpdateOptions(Map<String, dynamic> appointment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Update Appointment Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.upcoming, color: Colors.blue),
                title: const Text('Upcoming'),
                onTap: () async {
                  await AppointmentUtils.updateAppointmentStatus(
                      context, appointment['_id'], 'Upcoming');
                  Navigator.pop(context);
                  fetchUpcomingAppointments();
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Completed'),
                onTap: () async {
                  await AppointmentUtils.updateAppointmentStatus(
                      context, appointment['_id'], 'Completed');
                  Navigator.pop(context);
                  fetchUpcomingAppointments();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Cancelled'),
                onTap: () async {
                  await AppointmentUtils.updateAppointmentStatus(
                      context, appointment['_id'], 'Cancelled');
                  Navigator.pop(context);
                  fetchUpcomingAppointments();
                },
              ),
              ListTile(
                leading: const Icon(Icons.pending, color: Colors.orange),
                title: const Text('Pending'),
                onTap: () async {
                  await AppointmentUtils.updateAppointmentStatus(
                      context, appointment['_id'], 'Pending');
                  Navigator.pop(context);
                  fetchUpcomingAppointments();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Filter bar
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search appointments',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ), // Fixed: removed comma and added closing parenthesis
                        onChanged: (value) {
                          // Implement search functionality
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _showFilterDialog,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: fetchUpcomingAppointments,
                    ),
                  ],
                ),
              ),

              // Appointments list
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : completedAppointments.isEmpty
                        ? const Center(child: Text('No upcoming appointments'))
                        : ListView.builder(
                            itemCount: completedAppointments.length,
                            padding: const EdgeInsets.all(8),
                            itemBuilder: (context, index) {
                              return _buildAppointmentCard(
                                  completedAppointments[index]);
                            },
                          ),
              ),
            ],
          ),

          // Add floating action button
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.blue,
              onPressed: () async {
                bool? result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(25.0)),
                  ),
                  builder: (context) => const AppointmentForm(isEditing: false),
                );

                if (result == true) {
                  fetchUpcomingAppointments();
                }
              },
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
