import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'appointment_form.dart';
import 'appointment_utils.dart';
import 'appointment_detail_screen.dart';
import '../../services/notification_service.dart';
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

class UpcomingAppointmentsScreen extends StatefulWidget {
  const UpcomingAppointmentsScreen({super.key});

  @override
  State<UpcomingAppointmentsScreen> createState() =>
      _UpcomingAppointmentsScreenState();
}

class _UpcomingAppointmentsScreenState
    extends State<UpcomingAppointmentsScreen> {
  List<Map<String, dynamic>> upcomingAppointments = [];
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
  String? _token;

  @override
  void initState() {
    super.initState();
    _initAndFetch();
  }

  Future<void> _initAndFetch() async {
    final token = await LocalStorageService.getAuthToken();
    setState(() {
      _token = token;
    });
    await fetchUpcomingAppointments();
  }

  Future<void> fetchUpcomingAppointments() async {
    setState(() {
      isLoading = true;
    });

    final token = _token ?? await LocalStorageService.getAuthToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            'https://careconnect-api-v2kw.onrender.com/api/appointment/all'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> allAppointments = [];

        if (responseData is List) {
          allAppointments = responseData;
        } else if (responseData is Map &&
            responseData.containsKey('appointments')) {
          allAppointments = responseData['appointments'] as List<dynamic>;
        } else if (responseData is Map && responseData.containsKey('data')) {
          allAppointments = responseData['data'] as List<dynamic>;
        } else if (responseData is Map) {
          for (var value in responseData.values) {
            if (value is List) {
              allAppointments = value;
              break;
            }
          }
          if (allAppointments.isEmpty && responseData.containsKey('_id')) {
            allAppointments = [responseData];
          }
        }

        // Filter for upcoming and pending
        upcomingAppointments = allAppointments
            .where((appointment) =>
                appointment['status'] == 'Upcoming' ||
                appointment['status'] == 'Pending')
            .cast<Map<String, dynamic>>()
            .toList();

        // Extract unique doctor names, handling nested objects
        Set<String> doctors = {};
        for (var appt in upcomingAppointments) {
          if (appt['doctor'] != null) {
            String doctorName = '';
            String specialization = '';

            if (appt['doctor'] is Map) {
              var doctorObj = appt['doctor'];
              if (doctorObj.containsKey('user') && doctorObj['user'] is Map) {
                String username = doctorObj['user']['username'] ?? '';
                doctorName = username;
              } else if (doctorObj.containsKey('user') &&
                  doctorObj['user'] is String) {
                doctorName = doctorObj['user'];
              }
              if (doctorObj.containsKey('specialization')) {
                specialization = doctorObj['specialization'] ?? '';
              }
            } else {
              doctorName = appt['doctor'].toString();
            }

            if (doctorName.isNotEmpty && specialization.isNotEmpty) {
              doctors.add('Dr. $doctorName - $specialization');
            } else if (doctorName.isNotEmpty) {
              doctors.add('Dr. $doctorName');
            } else if (specialization.isNotEmpty) {
              doctors.add('Dr. Unknown - $specialization');
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
      print('################## $e');

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

    final token = _token ?? await LocalStorageService.getAuthToken();
    if (token == null) return;

    Map<String, dynamic> filterParams = {
      'status': 'Pending'
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

        if (responseData is List) {
          filteredAppointments = responseData;
        } else if (responseData is Map &&
            responseData.containsKey('appointments')) {
          filteredAppointments = responseData['appointments'] as List<dynamic>;
        } else if (responseData is Map && responseData.containsKey('data')) {
          filteredAppointments = responseData['data'] as List<dynamic>;
        } else if (responseData is Map) {
          for (var value in responseData.values) {
            if (value is List) {
              filteredAppointments = value;
              break;
            }
          }
          if (filteredAppointments.isEmpty && responseData.containsKey('_id')) {
            filteredAppointments = [responseData];
          }
        }
        setState(() {
          upcomingAppointments =
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

  String _getPatientName(Map<String, dynamic> appointment) {
    if (appointment['patient'] is Map) {
      var patient = appointment['patient'];
      if (patient.containsKey('user')) {
        if (patient['user'] is Map) {
          return patient['user']['username'] ?? patient['user']['firstName'] ?? 'Unknown User';
        }
        if (patient['user'] is String) {
          return patient['user'];
        }
        return 'Unknown User';
      }
      return 'Unknown Patient';
    }
    return appointment['patient']?.toString() ?? 'No patient';
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: () {
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
                    child: (_token == null)
                        ? const Text('Dr. ...')
                        : DoctorUsernameText(
                            doctor: appointment['doctor'],
                            token: _token!,
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
                      } else if (value == 'status') {
                        _showStatusUpdateOptions(appointment);
                      } else if (value == 'delete') {
                        bool? confirmed =
                            await AppointmentUtils.showDeleteConfirmationDialog(
                                context, appointment['_id']);
                        if (confirmed == true) {
                          fetchUpcomingAppointments();
                        }
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

  Future<void> updateAppointmentStatus(String id, String newStatus) async {
    setState(() {
      isLoading = true;
    });

    final token = await LocalStorageService.getAuthToken();
    if (token == null) return;

    try {
      final getResponse = await http.get(
        Uri.parse(
            'https://careconnect-api-v2kw.onrender.com/api/appointment/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (getResponse.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to get appointment details'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      final appointmentData = json.decode(getResponse.body);
      Map<String, dynamic> appointment;

      if (appointmentData is Map &&
          appointmentData.containsKey('appointment')) {
        appointment = appointmentData['appointment'];
      } else if (appointmentData is Map &&
          appointmentData.containsKey('data')) {
        appointment = appointmentData['data'];
      } else {
        appointment = appointmentData;
      }

      final response = await http.put(
        Uri.parse(
            'https://careconnect-api-v2kw.onrender.com/api/appointment/status/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );

        final patientInfo = _getPatientInfo(appointment);
        print(
            'Sending status update notification to patient: ${patientInfo['name']} (${patientInfo['id']})');

        await NotificationService().sendAppointmentStatusChangedNotification(
          appointment,
          newStatus,
          sendToPatient: true,
          sendToDoctor: true,
        );

        fetchUpcomingAppointments();
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Failed to update status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

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
                  await updateAppointmentStatus(appointment['_id'], 'Upcoming');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Completed'),
                onTap: () async {
                  await updateAppointmentStatus(
                      appointment['_id'], 'Completed');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Cancelled'),
                onTap: () async {
                  await updateAppointmentStatus(
                      appointment['_id'], 'Cancelled');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.pending, color: Colors.orange),
                title: const Text('Pending'),
                onTap: () async {
                  await updateAppointmentStatus(appointment['_id'], 'Pending');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendNewAppointmentNotification() async {
    try {
      final token = await LocalStorageService.getAuthToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse(
            'https://careconnect-api-v2kw.onrender.com/api/appointment/recent'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        Map<String, dynamic> recentAppointment;

        if (responseData is Map && responseData.containsKey('appointment')) {
          recentAppointment = responseData['appointment'];
        } else if (responseData is Map && responseData.containsKey('data')) {
          recentAppointment = responseData['data'];
        } else {
          recentAppointment = responseData;
        }

        final patientInfo = _getPatientInfo(recentAppointment);
        print(
            'Sending notification to patient: ${patientInfo['name']} (${patientInfo['id']})');

        await NotificationService().sendNewAppointmentNotification(
          recentAppointment,
          sendToPatient: true,
          sendToDoctor: true,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment created and notifications sent'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error sending new appointment notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, dynamic> _getPatientInfo(Map<String, dynamic> appointment) {
    String id = '';
    String name = '';

    try {
      if (appointment['patient'] is Map) {
        var patient = appointment['patient'];
        if (patient.containsKey('_id')) {
          id = patient['_id']?.toString() ?? '';
        } else if (patient.containsKey('id')) {
          id = patient['id']?.toString() ?? '';
        } else if (patient.containsKey('userId')) {
          id = patient['userId']?.toString() ?? '';
        }

        if (patient.containsKey('user')) {
          name = patient['user']?.toString() ?? '';
        } else if (patient.containsKey('name')) {
          name = patient['name']?.toString() ?? '';
        }
      } else if (appointment['patientId'] != null) {
        id = appointment['patientId']?.toString() ?? '';
        name = appointment['patientName']?.toString() ?? '';
      }
      if (id.isEmpty && appointment['patient'] != null) {
        id = appointment['patient'].toString();
      }
      if (name.isEmpty && appointment['patientName'] != null) {
        name = appointment['patientName'].toString();
      }
    } catch (e) {
      print('Error extracting patient info: $e');
    }

    return {'id': id, 'name': name};
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
                        ),
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
                    : upcomingAppointments.isEmpty
                        ? const Center(child: Text('No upcoming appointments'))
                        : ListView.builder(
                            itemCount: upcomingAppointments.length,
                            padding: const EdgeInsets.all(8),
                            itemBuilder: (context, index) {
                              return _buildAppointmentCard(
                                  upcomingAppointments[index]);
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
                  await _sendNewAppointmentNotification();
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