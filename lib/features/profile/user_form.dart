import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/services/firestore_service.dart';
import '../../models/user_profile.dart';
import '../../models/weight_entry.dart';
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
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _gender = 'Male';
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';
  bool _isLoading = false;
  DateTime _measurementDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.existingProfile != null) {
      _nameController.text = widget.existingProfile!.name;
      _heightController.text = widget.existingProfile!.height.toString();
      _weightController.text = widget.existingProfile!.weight.toString();
      _gender = widget.existingProfile!.gender;
      _heightUnit = widget.existingProfile!.heightUnit;
      _weightUnit = widget.existingProfile!.weightUnit;
      _measurementDate = widget.existingProfile!.date;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _showHeightPicker() {
    final isInches = _heightUnit == 'in';
    final items = isInches
        ? List.generate(25, (i) => 48 + i) // 4'0" (48 in) to ~6'11" (72+)
        : List.generate(81, (i) => 140 + i); // 140cm-220cm

    final initialIndex = _heightController.text.isNotEmpty
        ? items.indexWhere((v) => v.toString() == _heightController.text)
        : 0;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SizedBox(
          height: 280,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  height: 4,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: initialIndex < 0 ? 0 : initialIndex),
                  itemExtent: 44,
                  onSelectedItemChanged: (i) {
                    final val = items[i];
                    setState(() {
                      _heightController.text = val.toString();
                    });
                  },
                  children: items.map((v) {
                    if (isInches) {
                      final feet = v ~/ 12;
                      final inches = v % 12;
                      return Center(
                        child: Text(
                          "$feet' $inches\"",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                      );
                    }
                    return Center(
                      child: Text(
                        '$v cm',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWeightPicker({FormFieldState<String>? formState}) {
    final isLbs = _weightUnit == 'lbs';
    final items = isLbs
        ? List.generate(251, (i) => 80 + i) // 80-330 lbs
        : List.generate(166, (i) => 35 + i); // 35-200 kg

    final initialIndex = _weightController.text.isNotEmpty
        ? items.indexWhere((v) => v.toString() == _weightController.text)
        : 0;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SizedBox(
          height: 280,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  height: 4,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: initialIndex < 0 ? 0 : initialIndex),
                  itemExtent: 44,
                  onSelectedItemChanged: (i) {
                    final val = items[i];
                    setState(() {
                      _weightController.text = val.toString();
                    });
                    formState?.didChange(_weightController.text);
                  },
                  children: items
                      .map(
                        (v) => Center(
                          child: Text(
                            '$v ${isLbs ? 'lbs' : 'kg'}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final generatedSlug = _nameController.text.trim().toLowerCase().replaceAll(RegExp(r"[^a-z0-9]+"), "-");
      String id = widget.existingProfile?.id ?? (generatedSlug.isNotEmpty ? generatedSlug : DateTime.now().millisecondsSinceEpoch.toString());

      // If creating and id exists, warn user and ask to rename or continue
      if (widget.existingProfile == null) {
        final exists = await FirestoreService().profileExists(widget.uid, id);
        if (exists) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Name already exists'),
              content: Text('A profile named "${_nameController.text.trim()}" already exists. Use a different name?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Rename'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Create anyway'),
                ),
              ],
            ),
          );
          if (proceed != true) {
            setState(() => _isLoading = false);
            return; // Let user rename and retry
          }
          final suffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36).substring(7);
          id = '${generatedSlug.isEmpty ? 'profile' : generatedSlug}-$suffix';
        }
      }

      final profile = UserProfile(
        id: id,
        name: _nameController.text.trim().isEmpty ? 'Profile' : _nameController.text.trim(),
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        gender: _gender,
        date: _measurementDate,
        heightUnit: _heightUnit,
        weightUnit: _weightUnit,
      );

      // Save/Update the profile doc
      await FirestoreService().saveProfile(widget.uid, profile);

      // Add a weight history entry
      final weightEntry = WeightEntry(
        weight: profile.weight,
        weightUnit: profile.weightUnit,
        date: profile.date,
      );
      await FirestoreService().addWeightEntry(widget.uid, profile.id, weightEntry);

      if (mounted) {
        setState(() => _isLoading = false);
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
                  // Progress indicator style header
                  Text(
                    'Body Data',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fill your latest measurements',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                          
                          // Name Section
                          Text(
                            'Profile Name',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (widget.existingProfile == null) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a profile name';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Measurement date
                          Text(
                            'Measurement date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              '${_measurementDate.year}-${_measurementDate.month.toString().padLeft(2, '0')}-${_measurementDate.day.toString().padLeft(2, '0')}',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _measurementDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _measurementDate = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

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
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ChoiceChip(
                                      label: const Text('FT'),
                                      selected: _heightUnit == 'in',
                                      onSelected: (_) => setState(() => _heightUnit = 'in'),
                                      selectedColor: Colors.black,
                                      labelStyle: TextStyle(
                                        color: _heightUnit == 'in' ? Colors.white : Colors.black,
                                      ),
                                      backgroundColor: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    ChoiceChip(
                                      label: const Text('CM'),
                                      selected: _heightUnit == 'cm',
                                      onSelected: (_) => setState(() => _heightUnit = 'cm'),
                                      selectedColor: Colors.black,
                                      labelStyle: TextStyle(
                                        color: _heightUnit == 'cm' ? Colors.white : Colors.black,
                                      ),
                                      backgroundColor: Colors.white,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: _showHeightPicker,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _heightController.text.isEmpty ? 'Select height' : '${_heightController.text} ${_heightUnit == 'in' ? 'in' : 'cm'}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const Icon(Icons.arrow_drop_down),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
                          FormField<String>(
                            validator: (_) {
                              if (_weightController.text.isEmpty) return 'Required';
                              final weight = double.tryParse(_weightController.text);
                              if (weight == null || weight <= 0) return 'Invalid';
                              return null;
                            },
                            builder: (formState) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          ChoiceChip(
                                            label: const Text('KG'),
                                            selected: _weightUnit == 'kg',
                                            onSelected: (_) {
                                              setState(() => _weightUnit = 'kg');
                                              formState.didChange(_weightController.text);
                                            },
                                            selectedColor: Colors.black,
                                            labelStyle: TextStyle(
                                              color: _weightUnit == 'kg' ? Colors.white : Colors.black,
                                            ),
                                            backgroundColor: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          ChoiceChip(
                                            label: const Text('LBS'),
                                            selected: _weightUnit == 'lbs',
                                            onSelected: (_) {
                                              setState(() => _weightUnit = 'lbs');
                                              formState.didChange(_weightController.text);
                                            },
                                            selectedColor: Colors.black,
                                            labelStyle: TextStyle(
                                              color: _weightUnit == 'lbs' ? Colors.white : Colors.black,
                                            ),
                                            backgroundColor: Colors.white,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      OutlinedButton(
                                        onPressed: () => _showWeightPicker(formState: formState),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _weightController.text.isEmpty ? 'Select weight' : '${_weightController.text} ${_weightUnit == 'lbs' ? 'lbs' : 'kg'}',
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                            const Icon(Icons.arrow_drop_down),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (formState.hasError)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6, left: 4),
                                    child: Text(
                                      formState.errorText!,
                                      style: const TextStyle(color: Colors.red, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
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
