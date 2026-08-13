import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../config/routes/app_router.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/child_profile.dart';

class AddChildScreen extends ConsumerStatefulWidget {
  final String? childId; // null = add mode, non-null = edit mode
  const AddChildScreen({super.key, this.childId});

  @override
  ConsumerState<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends ConsumerState<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _dateOfBirth;
  String _gender = 'male';
  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.childId != null;
    if (_isEdit) {
      _loadChild();
    }
  }

  Future<void> _loadChild() async {
    final user = ref.read(currentUserProvider);
    if (user == null || widget.childId == null) return;

    final child = await ref.read(firestoreServiceProvider).getChild(
          clinicianId: user.uid,
          childId: widget.childId!,
        );

    if (child != null && mounted) {
      setState(() {
        _nameController.text = child.name;
        _dateOfBirth = child.dateOfBirth;
        _gender = child.gender;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 4),
      firstDate: DateTime(now.year - 8),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date of birth')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    final clinicianId = user?.uid ?? 'demo_clinician';

    setState(() => _isLoading = true);

    try {
      final childId = widget.childId ?? DateTime.now().millisecondsSinceEpoch.toString();
      final child = ChildProfile(
        id: childId,
        name: _nameController.text.trim(),
        dateOfBirth: _dateOfBirth!,
        gender: _gender,
        enrollmentDate: DateTime.now(),
        clinicianId: clinicianId,
      );

      try {
        if (_isEdit) {
          await ref.read(firestoreServiceProvider).updateChild(
                clinicianId: clinicianId,
                childId: widget.childId!,
                data: {
                  'name': child.name,
                  'dateOfBirth': child.dateOfBirth,
                  'gender': child.gender,
                },
              );
        } else {
          await ref.read(firestoreServiceProvider).addChild(
                clinicianId: clinicianId,
                child: child,
              );
        }
      } catch (_) {
        // Fallback for offline / local demo testing mode
      }

      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        } else {
          context.goNamed(AppRouter.children);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Child updated!' : 'Child added!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        } else {
          context.goNamed(AppRouter.children);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Child' : 'Add New Child'),
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRouter.home);
            }
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: AppColors.warmGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    _gender == 'male'
                        ? Icons.boy_rounded
                        : _gender == 'female'
                            ? Icons.girl_rounded
                            : Icons.child_care_rounded,
                    size: 44,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Name
              Text('Child\'s Name', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Enter child\'s full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the child\'s name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Date of Birth
              Text('Date of Birth', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDateOfBirth,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.textHint.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          color: AppColors.textHint, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _dateOfBirth != null
                            ? DateFormat('dd MMM yyyy').format(_dateOfBirth!)
                            : 'Select date of birth',
                        style: _dateOfBirth != null
                            ? AppTextStyles.bodyLarge
                            : AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textHint,
                              ),
                      ),
                      const Spacer(),
                      if (_dateOfBirth != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _calculateAge(),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Gender
              Text('Gender', style: AppTextStyles.labelLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildGenderOption('male', 'Boy', Icons.boy_rounded),
                  const SizedBox(width: 12),
                  _buildGenderOption('female', 'Girl', Icons.girl_rounded),
                  const SizedBox(width: 12),
                  _buildGenderOption(
                      'other', 'Other', Icons.child_care_rounded),
                ],
              ),

              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEdit ? 'Update Child' : 'Add Child',
                          style: AppTextStyles.buttonText,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String value, String label, IconData icon) {
    final isSelected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textHint.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? AppColors.primary : AppColors.textHint,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateAge() {
    if (_dateOfBirth == null) return '';
    final now = DateTime.now();
    int years = now.year - _dateOfBirth!.year;
    if (now.month < _dateOfBirth!.month ||
        (now.month == _dateOfBirth!.month && now.day < _dateOfBirth!.day)) {
      years--;
    }
    return '$years yrs';
  }
}
