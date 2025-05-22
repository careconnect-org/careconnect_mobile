import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'appointment_utils.dart';
import 'appointment_form.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';
import 'package:careconnect/services/local_storage_service.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onAppointmentUpdated;

  const AppointmentDetailScreen({
    Key? key,
    required this.appointment,
    required this.onAppointmentUpdated,
  }) : super(key: key);

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late Map<String, dynamic> appointmentData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    appointmentData = widget.appointment;
  }

  // Format date string from ISO to readable format
  String _formatDate(dynamic date) {
    if (date == null) return 'No date';

    try {
      if (date is String) {
        final DateTime parsedDate = DateTime.parse(date);
        return DateFormat('MMMM dd, yyyy').format(parsedDate);
      } else if (date is Map && date.containsKey('date')) {
        final DateTime parsedDate = DateTime.parse(date['date']);
        return DateFormat('MMMM dd, yyyy').format(parsedDate);
      }
    } catch (e) {
      print('Error formatting date: $e');
    }

    return date.toString();
  }

  String _formatCreatedTime(dynamic createdAt) {
    if (createdAt == null) return 'Unknown';

    try {
      if (createdAt is String) {
        final DateTime parsedDate = DateTime.parse(createdAt);
        return DateFormat('MMM dd, yyyy HH:mm').format(parsedDate);
      }
    } catch (e) {
      print('Error formatting created time: $e');
    }

    return createdAt.toString();
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

  // Update appointment status using the dedicated status endpoint
  Future<void> _updateAppointmentStatus(String id, String newStatus) async {
    setState(() {
      _isLoading = true;
    });

    final token = await LocalStorageService.getAuthToken();
    if (token == null) return;

    try {
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

        setState(() {
          appointmentData['status'] = newStatus;
        });

        // Send notification for status change
        await NotificationService().sendAppointmentStatusChangedNotification(
          appointmentData,
          newStatus,
        );

        widget.onAppointmentUpdated();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showStatusUpdateOptions() {
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
                  _updateAppointmentStatus(appointmentData['_id'], 'Upcoming');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Completed'),
                onTap: () async {
                  _updateAppointmentStatus(appointmentData['_id'], 'Completed');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Cancelled'),
                onTap: () async {
                  _updateAppointmentStatus(appointmentData['_id'], 'Cancelled');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.pending, color: Colors.orange),
                title: const Text('Pending'),
                onTap: () async {
                  _updateAppointmentStatus(appointmentData['_id'], 'Pending');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorInfo() {
    if (appointmentData['doctor'] is! Map) {
      return _buildInfoRow(
          'Doctor', appointmentData['doctor']?.toString() ?? 'Unknown');
    }

    var doctor = appointmentData['doctor'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Doctor Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        _buildInfoRow('Specialization', doctor['specialization'] ?? 'Unknown'),
        _buildInfoRow('Hospital', doctor['hospital'] ?? 'Unknown'),
        _buildInfoRow(
            'Experience', '${doctor['yearsOfExperience'] ?? 0} years'),
        _buildInfoRow('License', doctor['licenseNumber'] ?? 'Unknown'),
        if (doctor['availableSlots'] != null &&
            doctor['availableSlots'] is List &&
            doctor['availableSlots'].isNotEmpty)
          _buildInfoRow('Available',
              '${_formatDate(doctor['availableSlots'][0]['date'])} (${doctor['availableSlots'][0]['from']} - ${doctor['availableSlots'][0]['to']})')
      ],
    );
  }

  Widget _buildPatientInfo() {
    if (appointmentData['patient'] is! Map) {
      return _buildInfoRow(
          'Patient', appointmentData['patient']?.toString() ?? 'Unknown');
    }

    var patient = appointmentData['patient'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Patient Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        _buildInfoRow('Blood Type', patient['bloodType'] ?? 'Unknown'),
        _buildInfoRow('Weight', '${patient['weight'] ?? '?'} kg'),
        _buildInfoRow('Height', '${patient['height'] ?? '?'} m'),
        if (patient['emergencyContact'] != null &&
            patient['emergencyContact'] is Map) ...[
          const SizedBox(height: 8),
          const Text(
            'Emergency Contact',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          _buildInfoRow(
              'Name', patient['emergencyContact']['name'] ?? 'Unknown'),
          _buildInfoRow(
              'Relation', patient['emergencyContact']['relation'] ?? 'Unknown'),
          _buildInfoRow(
              'Phone', patient['emergencyContact']['phone'] ?? 'Unknown'),
        ],
        if (patient['insurance'] != null && patient['insurance'] is Map) ...[
          const SizedBox(height: 8),
          const Text(
            'Insurance Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          _buildInfoRow(
              'Provider', patient['insurance']['provider'] ?? 'Unknown'),
          _buildInfoRow(
              'Policy #', patient['insurance']['policyNumber'] ?? 'Unknown'),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('Appointment Details', style: TextStyle(color: Colors.white)),
        actions: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              bool? result = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(25.0)),
                ),
                builder: (context) => AppointmentForm(
                  appointment: appointmentData,
                  isEditing: true,
                ),
              );

              if (result == true) {
                widget.onAppointmentUpdated();
                Navigator.pop(context);
              }
            },
          ),

          // More options
          PopupMenuButton<String>(
            onSelected: (String value) async {
              if (value == 'status') {
                _showStatusUpdateOptions();
              } else if (value == 'delete') {
                bool? confirmed =
                    await AppointmentUtils.showDeleteConfirmationDialog(
                  context,
                  appointmentData['_id'],
                );
                if (confirmed == true) {
                  widget.onAppointmentUpdated();
                  Navigator.pop(context);
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'status',
                child: Text('Update Status'),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appointment Status Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                      appointmentData['status']?.toString() ??
                                          ''),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  appointmentData['status']?.toString() ??
                                      'Unknown',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'ID: ${appointmentData['_id']?.toString().substring(0, 8) ?? 'Unknown'}',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                              'Date', _formatDate(appointmentData['date'])),
                          _buildInfoRow(
                              'Time',
                              appointmentData['timeSlot']?.toString() ??
                                  'Not specified'),
                          _buildInfoRow(
                              'Reason',
                              appointmentData['reason']?.toString() ??
                                  'Not specified'),
                          if (appointmentData['notes'] != null &&
                              appointmentData['notes'].toString().isNotEmpty)
                            _buildInfoRow('Notes', appointmentData['notes']),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                  'Created: ${_formatCreatedTime(appointmentData['createdAt'])}',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Doctor Information
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildDoctorInfo(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Patient Information
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildPatientInfo(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
