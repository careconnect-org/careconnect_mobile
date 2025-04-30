import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<AppointmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> upcomingAppointments = [];
  List<Map<String, dynamic>> completedAppointments = [];
  List<Map<String, dynamic>> cancelledAppointments = [];
  List<Map<String, dynamic>> allAppointments = [];
  bool isLoading = true;

  // Filter-related variables
  String? selectedDoctor;
  String? selectedStatus;
  String? selectedType;
  DateTime? selectedDate;
  List<String> doctorsList = [];
  final List<String> statusOptions = [
    'All',
    'Upcoming',
    'Completed',
    'Cancelled',
    'Pending'
  ];
  final List<String> typeOptions = [
    'All',
    'Video Call',
    'Voice Call',
    'Messaging'
  ];

  // Form controllers for create/edit appointment
  final TextEditingController _doctorController = TextEditingController();
  final TextEditingController _patientController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedType = 'Video Call';
  String _selectedStatus = 'Pending';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _doctorController.dispose();
    _patientController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // CRUD OPERATIONS

  // Read - Fetch all appointments
  Future<void> fetchAppointments() async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
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
        final List<dynamic> data = json.decode(response.body);
        allAppointments = List<Map<String, dynamic>>.from(data);

        // Extract unique doctor names for filtering
        Set<String> doctors = {};
        for (var appt in allAppointments) {
          if (appt['doctor'] != null && appt['doctor'].toString().isNotEmpty) {
            doctors.add(appt['doctor'].toString());
          }
        }
        doctorsList = ['All', ...doctors.toList()];

        // Filter appointments into categories
        _filterAppointments();
      } else {
        // Handle API error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to load appointments: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Create - Create a new appointment
  Future<void> createAppointment(Map<String, dynamic> appointmentData) async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse(
            'https://careconnect-api-v2kw.onrender.com/api/appointment/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(appointmentData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh appointments
        fetchAppointments();
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(responseData['message'] ?? 'Failed to create appointment'),
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
        isLoading = false;
      });
    }
  }

  // Update - Update an existing appointment
  Future<void> updateAppointment(
      String id, Map<String, dynamic> updatedData) async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse(
            'https://careconnect-api-v2kw.onrender.com/api/appointment/update/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh appointments
        fetchAppointments();
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(responseData['message'] ?? 'Failed to update appointment'),
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
        isLoading = false;
      });
    }
  }

  // Delete - Delete an appointment
  Future<void> deleteAppointment(String id) async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse(
            'https://careconnect-api-v2kw.onrender.com/api/appointment/delete/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh appointments
        fetchAppointments();
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(responseData['message'] ?? 'Failed to delete appointment'),
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
        isLoading = false;
      });
    }
  }

  // Filter - Filter appointments
  Future<void> filterAppointments() async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    // Create filter parameters
    Map<String, dynamic> filterParams = {};
    if (selectedDoctor != null && selectedDoctor != 'All') {
      filterParams['doctor'] = selectedDoctor;
    }
    if (selectedStatus != null && selectedStatus != 'All') {
      filterParams['status'] = selectedStatus;
    }
    if (selectedType != null && selectedType != 'All') {
      filterParams['type'] = selectedType;
    }
    if (selectedDate != null) {
      filterParams['date'] = DateFormat('yyyy-MM-dd').format(selectedDate!);
    }

    try {
      // Use GET with query parameters for filtering
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
        final List<dynamic> data = json.decode(response.body);
        allAppointments = List<Map<String, dynamic>>.from(data);
        _filterAppointments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to filter appointments: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Update Status - Update appointment status
  Future<void> updateAppointmentStatus(String id, String newStatus) async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse(
            'https://careconnect-api-v2kw.onrender.com/api/appointment/update/$id'),
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
        // Refresh appointments
        fetchAppointments();
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
        isLoading = false;
      });
    }
  }

  // Helper function to categorize appointments by status
  void _filterAppointments() {
    upcomingAppointments = [];
    completedAppointments = [];
    cancelledAppointments = [];

    for (var appt in allAppointments) {
      switch (appt['status']) {
        case 'Upcoming':
        case 'Pending':
          upcomingAppointments.add(appt);
          break;
        case 'Completed':
          completedAppointments.add(appt);
          break;
        case 'Cancelled':
          cancelledAppointments.add(appt);
          break;
      }
    }

    setState(() {});
  }

  // UI ELEMENTS AND HELPERS

  // Show appointment form for create/edit
  void _showAppointmentForm({Map<String, dynamic>? appointment}) {
    bool isEditing = appointment != null;

    // Clear form or set values from existing appointment
    if (isEditing) {
      _doctorController.text = appointment['doctor'] ?? '';
      _patientController.text = appointment['patient'] ?? '';
      _dateController.text = appointment['date'] ?? '';
      _timeController.text = appointment['timeSlot'] ?? '';
      _reasonController.text = appointment['reason'] ?? '';
      _notesController.text = appointment['notes'] ?? '';
      _selectedType = appointment['type'] ?? 'Video Call';
      _selectedStatus = appointment['status'] ?? 'Pending';
    } else {
      _doctorController.clear();
      _patientController.clear();
      _dateController.clear();
      _timeController.clear();
      _reasonController.clear();
      _notesController.clear();
      _selectedType = 'Video Call';
      _selectedStatus = 'Pending';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                      isEditing ? 'Edit Appointment' : 'Create New Appointment',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Doctor field
                    TextField(
                      controller: _doctorController,
                      decoration: const InputDecoration(
                        labelText: 'Doctor',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Patient field (might be auto-filled for patient users)
                    TextField(
                      controller: _patientController,
                      decoration: const InputDecoration(
                        labelText: 'Patient',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Date picker
                    TextField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate != null) {
                          setModalState(() {
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
                        labelText: 'Time Slot',
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
                          setModalState(() {
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
                        labelText: 'Appointment Type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: typeOptions
                          .where((t) => t != 'All')
                          .map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setModalState(() {
                            _selectedType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 15),

                    // Status dropdown (for editing)
                    if (isEditing)
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons
                              .event_available), // Changed from Icons.status to Icons.event_available
                        ),
                        items: statusOptions
                            .where((s) => s != 'All')
                            .map((String status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            setModalState(() {
                              _selectedStatus = value;
                            });
                          }
                        },
                      ),
                    if (isEditing) const SizedBox(height: 15),

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
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          // Prepare appointment data
                          final appointmentData = {
                            'doctor': _doctorController.text,
                            'patient': _patientController.text,
                            'date': _dateController.text,
                            'timeSlot': _timeController.text,
                            'type': _selectedType,
                            'reason': _reasonController.text,
                            'notes': _notesController.text,
                            'status': _selectedStatus,
                          };

                          if (isEditing) {
                            updateAppointment(
                                appointment['_id'], appointmentData);
                          } else {
                            createAppointment(appointmentData);
                          }
                          Navigator.pop(context);
                        },
                        child: Text(isEditing
                            ? 'Update Appointment'
                            : 'Create Appointment'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
                onTap: () {
                  updateAppointmentStatus(appointment['_id'], 'Upcoming');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Completed'),
                onTap: () {
                  updateAppointmentStatus(appointment['_id'], 'Completed');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Cancelled'),
                onTap: () {
                  updateAppointmentStatus(appointment['_id'], 'Cancelled');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.pending, color: Colors.orange),
                title: const Text('Pending'),
                onTap: () {
                  updateAppointmentStatus(appointment['_id'], 'Pending');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Show filter dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Appointments'),
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

                    // Status dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedStatus,
                      items: statusOptions.map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedStatus = value;
                        });
                      },
                      hint: const Text('Select Status'),
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
                      selectedStatus = null;
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

  // Display confirmation dialog for delete
  void _showDeleteConfirmationDialog(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text(
              'Are you sure you want to delete this appointment? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                deleteAppointment(id);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Icon _getTypeIcon(String type) {
    switch (type) {
      case 'Video Call':
        return const Icon(Icons.video_call, color: Colors.blue);
      case 'Voice Call':
        return const Icon(Icons.call, color: Colors.purple);
      case 'Messaging':
        return const Icon(Icons.message, color: Colors.orange);
      default:
        return const Icon(Icons.event_note, color: Colors.grey);
    }
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment,
      {bool showActions = false}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
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
                    appointment['doctor']?.toString() ?? 'No doctor',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (String value) {
                    if (value == 'edit') {
                      _showAppointmentForm(appointment: appointment);
                    } else if (value == 'delete') {
                      _showDeleteConfirmationDialog(appointment['_id']);
                    } else if (value == 'status') {
                      _showStatusUpdateOptions(appointment);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
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
            const SizedBox(height: 5),
            Row(
              children: [
                _getTypeIcon(appointment['type']?.toString() ?? ''),
                const SizedBox(width: 6),
                Text(appointment['type']?.toString() ?? 'N/A'),
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
            Text(
              '${appointment['date'] ?? 'No date'} | ${appointment['timeSlot'] ?? 'No time'}',
              style: const TextStyle(color: Colors.grey),
            ),
            if (appointment['reason'] != null &&
                appointment['reason'].toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Reason: ${appointment['reason']}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (showActions) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // Create a new appointment with same details
                      final newAppointment =
                          Map<String, dynamic>.from(appointment);
                      newAppointment.remove('_id');
                      newAppointment['status'] = 'Pending';
                      _doctorController.text = newAppointment['doctor'] ?? '';
                      _patientController.text = newAppointment['patient'] ?? '';
                      _dateController.text = '';
                      _timeController.text = '';
                      _reasonController.text = newAppointment['reason'] ?? '';
                      _notesController.text = newAppointment['notes'] ?? '';
                      _selectedType = newAppointment['type'] ?? 'Video Call';
                      _selectedStatus = 'Pending';
                      _showAppointmentForm(appointment: newAppointment);
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text("Book Again"),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: () =>
                        _showDeleteConfirmationDialog(appointment['_id']),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text("Delete"),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        title: const Text("My Appointments",
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: TabBar(
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          controller: _tabController,
          tabs: const [
            Tab(text: "Upcoming"),
            Tab(text: "Completed"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Upcoming
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: upcomingAppointments.isEmpty
                      ? const Center(child: Text('No upcoming appointments'))
                      : ListView.builder(
                          itemCount: upcomingAppointments.length,
                          itemBuilder: (context, index) {
                            return _buildAppointmentCard(
                                upcomingAppointments[index]);
                          },
                        ),
                ),

                // Completed
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: completedAppointments.isEmpty
                      ? const Center(child: Text('No completed appointments'))
                      : ListView.builder(
                          itemCount: completedAppointments.length,
                          itemBuilder: (context, index) {
                            return _buildAppointmentCard(
                              completedAppointments[index],
                              showActions: true,
                            );
                          },
                        ),
                ),

                // Cancelled
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: cancelledAppointments.isEmpty
                      ? const Center(child: Text('No cancelled appointments'))
                      : ListView.builder(
                          itemCount: cancelledAppointments.length,
                          itemBuilder: (context, index) {
                            return _buildAppointmentCard(
                                cancelledAppointments[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => _showAppointmentForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
