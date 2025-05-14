import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'services/notification_service.dart';

class AppointmentForm extends StatefulWidget {
  final Map<String, dynamic>? appointment;
  final bool isEditing;
  final bool isRebooking;

  AppointmentForm({Key? key, this.appointment, this.isEditing = false, this.isRebooking = false})
      : super(key: key);

  @override
  _AppointmentFormState createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<AppointmentForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Selected values
  String? _selectedDoctor;
  String? _selectedPatient;
  String? _selectedType;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing || widget.isRebooking) {
      _populateFields();
    }
  }

  void _populateFields() {
    if (widget.appointment != null) {
      _dateController.text = widget.appointment!['date'] != null
          ? DateFormat('yyyy-MM-dd').format(DateTime.parse(widget.appointment!['date']))
          : '';
      _timeController.text = widget.appointment!['timeSlot'] != null
          ? DateFormat('HH:mm').format(DateTime.parse(widget.appointment!['timeSlot']))
          : '';
      _selectedDoctor = widget.appointment!['doctor'];
      _selectedPatient = widget.appointment!['patient'];
      _selectedType = widget.appointment!['type'];
      _reasonController.text = widget.appointment!['reason'] ?? '';
      _notesController.text = widget.appointment!['notes'] ?? '';
      _selectedStatus = widget.appointment!['status'];
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final appointmentData = {
        'doctor': _selectedDoctor,
        'patient': _selectedPatient,
        'date': _dateController.text,
        'timeSlot': _timeController.text,
        'type': _selectedType,
        'reason': _reasonController.text,
        'notes': _notesController.text,
        'status': _selectedStatus,
      };

      final response = widget.isEditing && !widget.isRebooking
          ? await http.put(
              Uri.parse(
                  'https://careconnect-api-v2kw.onrender.com/api/appointment/update/${widget.appointment!['_id']}'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(appointmentData),
            )
          : await http.post(
              Uri.parse(
                  'https://careconnect-api-v2kw.onrender.com/api/appointment/create'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(appointmentData),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing && !widget.isRebooking
                ? 'Appointment updated successfully'
                : widget.isRebooking
                    ? 'Appointment rebooked successfully'
                    : 'Appointment created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Get the appointment from response
        final responseData = json.decode(response.body);
        Map<String, dynamic> savedAppointment;
        
        // Handle different response formats
        if (responseData is Map && responseData.containsKey('appointment')) {
          savedAppointment = responseData['appointment'];
        } else if (responseData is Map && responseData.containsKey('data')) {
          savedAppointment = responseData['data'];
        } else {
          savedAppointment = responseData;
        }

        // Send the appropriate notification
        final notificationService = NotificationService();
        if (widget.isEditing && !widget.isRebooking) {
          await notificationService.sendAppointmentUpdatedNotification(savedAppointment);
        } else {
          await notificationService.sendAppointmentCreatedNotification(savedAppointment);
        }

        Navigator.pop(context, true);
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(responseData['message'] ?? 'Failed to save appointment'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Appointment' : 'New Appointment'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              // Form fields go here
            ],
          ),
        ),
      ),
    );
  }
}
