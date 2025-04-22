import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _fullNameController =
      TextEditingController(text: 'Andrew Ainsley');
  final TextEditingController _firstNameController =
      TextEditingController(text: 'Andrew');
  final TextEditingController _birthDateController =
      TextEditingController(text: '12/27/1995');
  final TextEditingController _emailController =
      TextEditingController(text: 'andrew_ainsley@yourdomain.com');
  final TextEditingController _phoneController =
      TextEditingController(text: '+1 111 467 378 399');

  String _selectedCountry = 'United States';
  String _selectedGender = 'Male';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
        title: Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
        
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildTextField(
                        controller: _fullNameController,
                        label: 'Andrew Ainsley',
                      ),
                      const SizedBox(height: 16),
                      buildTextField(
                        controller: _firstNameController,
                        label: 'Andrew',
                      ),
                      const SizedBox(height: 16),
                      buildTextField(
                        controller: _birthDateController,
                        label: '12/27/1995',
                        suffix: Icons.calendar_today,
                      ),
                      const SizedBox(height: 16),
                      buildTextField(
                        controller: _emailController,
                        label: 'andrew_ainsley@yourdomain.com',
                        suffix: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      buildDropdownField(
                        value: _selectedCountry,
                        label: 'United States',
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCountry = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      buildPhoneField(
                        controller: _phoneController,
                        countryCode: 'US',
                      ),
                      // const SizedBox(height: 16),
                      // buildDropdownField(
                      //   value: _selectedGender,
                      //   label: 'Male',
                      //   onChanged: (value) {
                      //     if (value != null) {
                      //       setState(() {
                      //         _selectedGender = value;
                      //       });
                      //     }
                      //   },
                      // ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Update',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? suffix,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintText: label,
        suffixIcon: suffix != null ? Icon(suffix, color: Colors.grey) : null,
      ),
    );
  }

  Widget buildDropdownField({
    required String value,
    required String label,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(label),
          icon: const Icon(Icons.keyboard_arrow_down),
          items: <String>[
            'United States',
            'Canada',
            'United Kingdom',
            'Australia'
          ].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget buildPhoneField({
    required TextEditingController controller,
    required String countryCode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                // This would typically be a flag image
                Container(
                  width: 24,
                  height: 16,
                  color: Colors.blue,
                  margin: const EdgeInsets.only(right: 4),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 16),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '+1 111 467 378 399',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
