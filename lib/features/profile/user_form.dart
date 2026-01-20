import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../../models/user_profile.dart';
import '../bmi/bmi_screen.dart';
import 'profile_switch_screen.dart';

class UserForm extends StatefulWidget {
  final String uid;
  final UserProfile? existingProfile;
  
  const UserForm({super.key, required this.uid, this.existingProfile});

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _gender = 'Male';
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingProfile != null) {
      _heightController.text = widget.existingProfile!.height.toString();
      _weightController.text = widget.existingProfile!.weight.toString();
      _gender = widget.existingProfile!.gender;
      _heightUnit = widget.existingProfile!.heightUnit;
      _weightUnit = widget.existingProfile!.weightUnit;
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final profile = UserProfile(
        id: widget.existingProfile?.id ?? 
            DateTime.now().millisecondsSinceEpoch.toString(),
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        gender: _gender,
        date: DateTime.now(),
        heightUnit: _heightUnit,
        weightUnit: _weightUnit,
      );

      await FirestoreService().saveProfile(widget.uid, profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved successfully')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BMIScreen(uid: widget.uid, profile: profile),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingProfile == null ? 'Add Profile' : 'Edit Profile'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileSwitchScreen(uid: widget.uid),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Icon(
                              Icons.person,
                              size: 64,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'Enter Your Details',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Height Section
                          Text(
                            'Height',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _heightController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Value',
                                    prefixIcon: const Icon(Icons.height),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    final height = double.tryParse(value);
                                    if (height == null || height <= 0) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _heightUnit,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  items: ['cm', 'in']
                                      .map((unit) => DropdownMenuItem(
                                            value: unit,
                                            child: Text(unit),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() => _heightUnit = value!);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Weight Section
                          Text(
                            'Weight',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _weightController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Value',
                                    prefixIcon: const Icon(Icons.monitor_weight),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    final weight = double.tryParse(value);
                                    if (weight == null || weight <= 0) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _weightUnit,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  items: ['kg', 'lbs']
                                      .map((unit) => DropdownMenuItem(
                                            value: unit,
                                            child: Text(unit),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() => _weightUnit = value!);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Gender Section
                          Text(
                            'Gender',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _gender,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: ['Male', 'Female', 'Other']
                                .map((gender) => DropdownMenuItem(
                                      value: gender,
                                      child: Text(gender),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _gender = value!);
                            },
                          ),
                          const SizedBox(height: 24),

                          // Save Button
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: _saveProfile,
                                    icon: const Icon(Icons.calculate),
                                    label: const Text(
                                      'Calculate BMI',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade700,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
