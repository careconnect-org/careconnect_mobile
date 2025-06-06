import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'appointment_detail_screen.dart';

class CancelledAppointmentsScreen extends StatefulWidget {
  const CancelledAppointmentsScreen({super.key});

  @override
  State<CancelledAppointmentsScreen> createState() => _CancelledAppointmentsScreenState();
}

class _CancelledAppointmentsScreenState extends State<CancelledAppointmentsScreen> {
  List<Map<String, dynamic>> appointments = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userData = prefs.getString('user_data');
      
      if (token == null || userData == null) {
        setState(() {
          error = 'Please login to view appointments';
          isLoading = false;
        });
        return;
      }

      final userInfo = json.decode(userData);
      print('Full login response: $userInfo');
      
      // Get the user ID from the user object
      final userId = userInfo['_id'];
      print('User ID: $userId');

      if (userId == null) {
        print('Error: User ID not found in response');
        setState(() {
          error = 'User ID not found. Please login again.';
          isLoading = false;
        });
        return;
      }

      // First, get the patient ID using the user ID
      print('Getting patient ID for user: $userId');
      final patientResponse = await http.get(
        Uri.parse('https://careconnect-api-v2kw.onrender.com/api/patient/getPatientByUser/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Patient response status code: ${patientResponse.statusCode}');
      print('Patient response body: ${patientResponse.body}');

      if (patientResponse.statusCode != 200) {
        setState(() {
          error = 'Failed to get patient information';
          isLoading = false;
        });
        return;
      }

      final patientData = json.decode(patientResponse.body);
      final patientId = patientData['patient']?['_id'];
      print('Patient ID: $patientId');

      if (patientId == null) {
        setState(() {
          error = 'Patient ID not found';
          isLoading = false;
        });
        return;
      }

      // Now get appointments using the patient ID
      print('Getting appointments for patient: $patientId');
      final response = await http.get(
        Uri.parse('https://careconnect-api-v2kw.onrender.com/api/appointment/byPatient/$patientId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Appointments response status code: ${response.statusCode}');
      print('Appointments response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final List<dynamic> appointmentsData = responseData['appointments'] ?? [];
          
          setState(() {
            appointments = List<Map<String, dynamic>>.from(appointmentsData)
                .where((appt) => appt['status'] == 'Cancelled')
                .toList();
            isLoading = false;
          });
        } catch (e) {
          print('Error parsing response: $e');
          setState(() {
            error = 'Error parsing response: $e';
            isLoading = false;
          });
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          setState(() {
            error = errorData['message'] ?? 'Failed to load appointments: ${response.statusCode}';
            isLoading = false;
          });
        } catch (e) {
          setState(() {
            error = 'Failed to load appointments: ${response.statusCode}';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  String _getDoctorName(Map<String, dynamic>? doctor) {
    if (doctor == null) return 'No doctor';
    
    final user = doctor['user'];
    if (user == null) return 'No doctor';
    
    if (user is Map) {
      return 'Dr. ${user['firstName'] ?? ''} ${user['lastName'] ?? ''}';
    }
    
    return 'No doctor';
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final doctor = appointment['doctor'] is Map ? appointment['doctor'] as Map<String, dynamic> : null;
    final doctorName = _getDoctorName(doctor);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentDetailScreen(appointment: appointment),
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
                    child: Text(
                      doctorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Cancelled',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    appointment['date'] ?? 'No date',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    appointment['timeSlot'] ?? 'No time',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              if (appointment['reason'] != null && appointment['reason'].toString().isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.note, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reason: ${appointment['reason']}',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (appointment['cancellationReason'] != null && appointment['cancellationReason'].toString().isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.cancel, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cancellation Reason: ${appointment['cancellationReason']}',
                        style: const TextStyle(fontSize: 14, color: Colors.red),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchAppointments,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : appointments.isEmpty
                  ? const Center(child: Text('No cancelled appointments'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        return _buildAppointmentCard(appointments[index]);
                      },
                    ),
    );
  }
} 