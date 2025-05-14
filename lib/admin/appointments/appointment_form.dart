import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';

class AppointmentForm extends StatefulWidget {
  final Map<String, dynamic>? appointment;
  final bool isEditing;
  final bool isRebooking;

  const AppointmentForm({
    Key? key,
    this.appointment,
    required this.isEditing,
    this.isRebooking = false,
  }) : super(key: key);

  @override
  State<AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<AppointmentForm> {
  // Replace text controllers with dropdown values
  String? _selectedDoctor;
  String? _selectedPatient;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedType = 'Video Call';
  String _selectedStatus = 'Pending';
  bool _isLoading = false;

  // Lists to hold doctors and patients data
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _patients = [];
  bool _isLoadingDoctors = true;
  bool _isLoadingPatients = true;

  final List<String> _typeOptions = ['Video Call', 'Voice Call', 'Messaging'];
  final List<String> _statusOptions = [
    'Upcoming',
    'Completed',
    'Cancelled',
    'Pending'
  ];

  // 1. Build a map of doctorId -> doctorName when fetching doctors
  Map<String, String> doctorIdToName = {};

  @override
  void initState() {
    super.initState();
    // Fetch doctors and patients when the form is initialized
    _fetchDoctors();
    _fetchPatients();

    if (widget.appointment != null) {
      // For date, time, reason, notes, type and status
      _dateController.text = widget.appointment!['date'] ?? '';
      _timeController.text = widget.appointment!['timeSlot'] ?? '';
      _reasonController.text = widget.appointment!['reason'] ?? '';
      _notesController.text = widget.appointment!['notes'] ?? '';
      _selectedType = widget.appointment!['type'] ?? 'Video Call';
      _selectedStatus = widget.isRebooking
          ? 'Pending'
          : (widget.appointment!['status'] ?? 'Pending');

      // If rebooking, clear the date and time
      if (widget.isRebooking) {
        _dateController.clear();
        _timeController.clear();
      }
    }
  }

  // Fetch doctors from API using the reference implementation
  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoadingDoctors = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to view doctors')),
      );
      setState(() => _isLoadingDoctors = false);
      return;
    }

    print('Fetching doctors from API...');
    try {
      final response = await http.get(
        Uri.parse('https://careconnect-api-v2kw.onrender.com/api/doctor/all'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('Doctor response status code: ${response.statusCode}');
      print('Doctor response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final List<dynamic> doctorsData = responseData['doctors'] ?? [];
          print('%%%%%%%%% $doctorsData');
          if (doctorsData.isEmpty) {
            print('No doctors found in response');
            setState(() {
              _isLoadingDoctors = false;
            });
            return;
          }

          setState(() {
            _doctors = doctorsData
                .map<Map<String, dynamic>>((doctor) {
                  // Extract doctor's name from user object
                  String doctorName = '';
                  if (doctor['user'] is Map) {
                    String firstName = doctor['user']['firstName'] ?? '';
                    String lastName = doctor['user']['lastName'] ?? '';
                    doctorName = '$firstName $lastName'.trim();
                  }

                  return {
                    '_id': doctor['_id'] ?? '',
                    'specialization': doctor['specialization'] ?? 'General Practitioner',
                    'hospital': doctor['hospital'] ?? 'Not specified',
                    'yearsOfExperience': doctor['yearsOfExperience'] ?? 0,
                    'licenseNumber': doctor['licenseNumber'] ?? '',
                    'user': doctorName.isNotEmpty ? doctorName : 'Unknown Doctor',
                  };
                })
                .toList();
            _isLoadingDoctors = false;

            // Set selected doctor from appointment if it exists
            if (widget.appointment != null && _doctors.isNotEmpty) {
              var doctorId = widget.appointment!['doctor'];
              // Handle string ID
              if (doctorId is String) {
                for (var doctor in _doctors) {
                  if (doctor['_id'] == doctorId) {
                    _selectedDoctor = doctor['_id'];
                    break;
                  }
                }
              }
              // Handle object with _id
              else if (doctorId is Map && doctorId.containsKey('_id')) {
                _selectedDoctor = doctorId['_id'];
              }
            }

            // 2. In your _getDoctorName function:
            for (var doctor in _doctors) {
              if (doctor['user'] != null && doctor['user'] is Map) {
                String name = '${doctor['user']['firstName'] ?? ''} ${doctor['user']['lastName'] ?? ''}'.trim();
                doctorIdToName[doctor['_id']] = name;
              }
            }
          });
        } catch (e) {
          print('Error parsing doctor response: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error parsing doctor data: $e')),
          );
          setState(() => _isLoadingDoctors = false);
        }
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please login again.')),
        );
        setState(() => _isLoadingDoctors = false);
      } else {
        print('Failed to load doctors: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load doctors: ${response.statusCode}')),
        );
        setState(() => _isLoadingDoctors = false);
      }
    } catch (e) {
      print('Error fetching doctors: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading doctors: $e')),
      );
      setState(() => _isLoadingDoctors = false);
    }
  }

  // Fetch patients from API with similar approach to doctors
  Future<void> _fetchPatients() async {
    setState(() {
      _isLoadingPatients = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to view patients')),
      );
      setState(() => _isLoadingPatients = false);
      return;
    }

    print('Fetching patients from API...');
    try {
      final response = await http.get(
        Uri.parse('https://careconnect-api-v2kw.onrender.com/api/patient/all'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('Patient response status code: ${response.statusCode}');
      print('Patient response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final List<dynamic> patientsData = responseData['patients'] ?? [];

          if (patientsData.isEmpty) {
            print('No patients found in response');
            setState(() {
              _isLoadingPatients = false;
            });
            return;
          }

          setState(() {
            _patients = patientsData
                .map<Map<String, dynamic>>((patient) => {
                      '_id': patient['_id'] ?? '',
                      'bloodType': patient['bloodType'] ?? '',
                      'weight': patient['weight'] ?? 0,
                      'height': patient['height'] ?? 0,
                      'user': patient['user'] != null
                          ? '${patient['user']['firstName'] ?? ''} ${patient['user']['lastName'] ?? ''}'
                          : 'Unknown Patient',
                    })
                .toList();
            _isLoadingPatients = false;

            // Set selected patient from appointment if it exists
            if (widget.appointment != null && _patients.isNotEmpty) {
              var patientId = widget.appointment!['patient'];
              if (patientId is String) {
                for (var patient in _patients) {
                  if (patient['_id'] == patientId) {
                    _selectedPatient = patient['_id'];
                    break;
                  }
                }
              } else if (patientId is Map && patientId.containsKey('_id')) {
                _selectedPatient = patientId['_id'];
              }
            }
          });
        } catch (e) {
          print('Error parsing patient response: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error parsing patient data: $e')),
          );
          setState(() => _isLoadingPatients = false);
        }
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please login again.')),
        );
        setState(() => _isLoadingPatients = false);
      } else {
        print('Failed to load patients: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load patients: ${response.statusCode}')),
        );
        setState(() => _isLoadingPatients = false);
      }
    } catch (e) {
      print('Error fetching patients: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading patients: $e')),
      );
      setState(() => _isLoadingPatients = false);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Helper function to get doctor display name
  String _getDoctorDisplayName(Map<String, dynamic> doctor) {
    String doctorName = doctor['user'] ?? 'Unknown Doctor';
    String specialization = doctor['specialization'] ?? '';

    // Return combined name and specialization
    return specialization.isNotEmpty 
        ? 'Dr. $doctorName - $specialization'
        : 'Dr. $doctorName';
  }

  // Helper function to get patient display name
  String _getPatientDisplayName(Map<String, dynamic> patient) {
    if (patient.containsKey('user')) {
      return patient['user'] ?? 'Unknown Patient';
    }
    if (patient.containsKey('name')) {
      return patient['name'];
    }
    return 'Patient ${patient['_id']?.toString().substring(0, 6) ?? ''}';
  }

  Future<void> _saveAppointment() async {
    // Validate inputs
    if (_selectedDoctor == null ||
        _selectedPatient == null ||
        _dateController.text.isEmpty ||
        _timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
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

        // Get appointment from response to use for notifications
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

        // Send notification based on action type
        if (widget.isEditing && !widget.isRebooking) {
          // For edited appointments
          await NotificationService()
              .sendAppointmentUpdatedNotification(savedAppointment);
        } else {
          // For new or rebooked appointments
          await NotificationService()
              .sendAppointmentCreatedNotification(savedAppointment);
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
    String title = widget.isEditing
        ? 'Edit Appointment'
        : widget.isRebooking
            ? 'Rebook Appointment'
            : 'Create New Appointment';

    bool isAnyLoading = _isLoading || _isLoadingDoctors || _isLoadingPatients;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Doctor dropdown
            _isLoadingDoctors
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : DropdownButtonFormField<String>(
                    value: _selectedDoctor,
                    decoration: const InputDecoration(
                      labelText: 'Doctor *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    hint: const Text('Select Doctor'),
                    items: _doctors.map((doctor) {
                      return DropdownMenuItem<String>(
                        value: doctor['_id'],
                        child: Text(_getDoctorDisplayName(doctor)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDoctor = value;
                      });
                    },
                  ),
            const SizedBox(height: 15),

            // Patient dropdown
            _isLoadingPatients
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : DropdownButtonFormField<String>(
                    value: _selectedPatient,
                    decoration: const InputDecoration(
                      labelText: 'Patient *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    hint: const Text('Select Patient'),
                    items: _patients.map((patient) {
                      return DropdownMenuItem<String>(
                        value: patient['_id'],
                        child: Text(_getPatientDisplayName(patient)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPatient = value;
                      });
                    },
                  ),
            const SizedBox(height: 15),

            // Date picker
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (pickedDate != null) {
                  setState(() {
                    _dateController.text =
                        DateFormat('yyyy-MM-dd').format(pickedDate);
                  });
                }
              },
            ),
            const SizedBox(height: 15),

            // Time slot field
            TextField(
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: 'Time Slot *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time),
              ),
              readOnly: true,
              onTap: () async {
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  setState(() {
                    _timeController.text = pickedTime.format(context);
                  });
                }
              },
            ),
            const SizedBox(height: 15),

            // Appointment type dropdown
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Appointment Type *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _typeOptions.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 15),

            // Status dropdown (for editing)
            if (widget.isEditing && !widget.isRebooking)
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event_available),
                ),
                items: _statusOptions.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
            if (widget.isEditing && !widget.isRebooking)
              const SizedBox(height: 15),

            // Reason field
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Appointment',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 15),

            // Notes field
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_add),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              child: isAnyLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _saveAppointment,
                      child: Text(widget.isEditing && !widget.isRebooking
                          ? 'Update Appointment'
                          : widget.isRebooking
                              ? 'Rebook Appointment'
                              : 'Create Appointment'),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

String _getDoctorName(Map<String, dynamic> appointment, Map<String, String> doctorIdToName) {
  if (appointment['doctor'] is Map) {
    var doctor = appointment['doctor'];
    String doctorName = '';
    String specialization = doctor['specialization'] ?? '';

    if (doctor['user'] is Map) {
      String firstName = doctor['user']['firstName'] ?? '';
      String lastName = doctor['user']['lastName'] ?? '';
      doctorName = '$firstName $lastName'.trim();
    } else if (doctor['user'] is String) {
      // Fallback: look up the name by doctor['_id']
      doctorName = doctorIdToName[doctor['_id']] ?? '';
    }

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
