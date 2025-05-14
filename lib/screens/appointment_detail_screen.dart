import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';
import 'package:flutter/rendering.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  bool _isUpdating = false;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedAppointment = await _appointmentService.updateAppointmentStatus(
        widget.appointment['_id'],
        newStatus,
      );

      setState(() {
        widget.appointment['status'] = newStatus;
        if (updatedAppointment != null) {
          widget.appointment.addAll(updatedAppointment);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Widget _buildStatusSection() {
    final status = widget.appointment['status']?.toString().toLowerCase() ?? '';
    final statusColor = _getStatusColor(status);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              if (!_isUpdating) ...[
                if (status != 'completed')
                  TextButton.icon(
                    onPressed: () => _updateStatus('Completed'),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                    label: const Text('Complete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                if (status != 'cancelled')
                  TextButton.icon(
                    onPressed: () => _updateStatus('Cancelled'),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
              ] else
                const CircularProgressIndicator(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                widget.appointment['date'] ?? 'No date',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                widget.appointment['timeSlot'] ?? 'No time',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
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

  String _getPatientName(Map<String, dynamic>? patient) {
    if (patient == null) return 'No patient';
    final user = patient['user'];
    if (user == null) return 'No patient';
    if (user is Map) {
      return '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}';
    }
    return 'No patient';
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.appointment['doctor'] is Map ? widget.appointment['doctor'] as Map<String, dynamic> : null;
    final patient = widget.appointment['patient'] is Map ? widget.appointment['patient'] as Map<String, dynamic> : null;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusSection(),
            const SizedBox(height: 24),

            if (doctor != null)
              _buildInfoCard(
                'Doctor Information',
                [
                  Text(
                    _getDoctorName(doctor),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Specialization', doctor['specialization'] ?? 'N/A'),
                  _buildInfoRow('License', doctor['licenseNumber'] ?? 'N/A'),
                  _buildInfoRow('Hospital', doctor['hospital'] ?? 'N/A'),
                  _buildInfoRow('Experience', '${doctor['yearsOfExperience'] ?? 'N/A'} years'),
                ],
              ),
            const SizedBox(height: 16),

            if (patient != null)
              _buildInfoCard(
                'Patient Information',
                [
                  Text(
                    _getPatientName(patient),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Blood Type', patient['bloodType'] ?? 'N/A'),
                  _buildInfoRow('Height', '${patient['height'] ?? 'N/A'} m'),
                  _buildInfoRow('Weight', '${patient['weight'] ?? 'N/A'} kg'),
                  if (patient['insurance'] is Map) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Insurance Information',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildInfoRow('Provider', (patient['insurance'] as Map)['provider'] ?? 'N/A'),
                    _buildInfoRow('Policy Number', (patient['insurance'] as Map)['policyNumber'] ?? 'N/A'),
                  ],
                  if (patient['emergencyContact'] is Map) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Emergency Contact',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildInfoRow('Name', (patient['emergencyContact'] as Map)['name'] ?? 'N/A'),
                    _buildInfoRow('Relation', (patient['emergencyContact'] as Map)['relation'] ?? 'N/A'),
                    _buildInfoRow('Phone', (patient['emergencyContact'] as Map)['phone'] ?? 'N/A'),
                  ],
                ],
              ),
            const SizedBox(height: 16),

            _buildInfoCard(
              'Appointment Details',
              [
                if (widget.appointment['reason'] != null && widget.appointment['reason'].toString().isNotEmpty)
                  _buildInfoRow('Reason', widget.appointment['reason']),
                if (widget.appointment['notes'] != null && widget.appointment['notes'].toString().isNotEmpty)
                  _buildInfoRow('Notes', widget.appointment['notes']),
                if (widget.appointment['cancellationReason'] != null && widget.appointment['cancellationReason'].toString().isNotEmpty)
                  _buildInfoRow('Cancellation Reason', widget.appointment['cancellationReason'], isError: true),
                const SizedBox(height: 8),
                _buildInfoRow('Created', DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(widget.appointment['createdAt']))),
                _buildInfoRow('Last Updated', DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(widget.appointment['updatedAt']))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 