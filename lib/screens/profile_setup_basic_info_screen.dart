import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import 'profile_setup_islamic_profile_screen.dart';

class ProfileSetupBasicInfoScreen extends StatefulWidget {
  const ProfileSetupBasicInfoScreen({
    super.key,
    this.fullName = '',
    this.phoneNumber = '',
    this.email = '',
  });

  final String fullName;
  final String phoneNumber;
  final String email;

  @override
  State<ProfileSetupBasicInfoScreen> createState() =>
      _ProfileSetupBasicInfoScreenState();
}

class _ProfileSetupBasicInfoScreenState
    extends State<ProfileSetupBasicInfoScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  final _locationController = TextEditingController();
  final _educationController = TextEditingController();
  final _occupationController = TextEditingController();
  final _languagesController = TextEditingController();

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.fullName);
    _phoneController = TextEditingController(text: widget.phoneNumber);
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _educationController.dispose();
    _occupationController.dispose();
    _languagesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final latestAllowedDate = DateTime.now().subtract(
      const Duration(days: 365 * 18),
    );
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? latestAllowedDate,
      firstDate: DateTime(1950),
      lastDate: latestAllowedDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xff202124),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _editTextField({
    required String title,
    required String hintText,
    required TextEditingController controller,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final draftController = TextEditingController(text: controller.text);

    final updatedValue = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final viewInsets = MediaQuery.of(context).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xfffcfbf7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xffd8d2c7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff202124),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Update your basic info so your profile feels complete and trustworthy.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xff6a6f73),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: draftController,
                  textCapitalization: textCapitalization,
                  keyboardType: keyboardType,
                  autofocus: true,
                  maxLines: title == 'Languages' ? 2 : 1,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      color: Color(0xff8d9398),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xffddd8cb)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primaryGreen,
                        width: 1.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(draftController.text.trim());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Save changes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    draftController.dispose();

    if (updatedValue != null && updatedValue.isNotEmpty) {
      setState(() {
        controller.text = updatedValue;
      });
    }
  }

  String get _formattedBirthDate {
    if (_selectedDate == null) {
      return '';
    }

    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${_selectedDate!.day.toString().padLeft(2, '0')} '
        '${monthNames[_selectedDate!.month - 1]} '
        '${_selectedDate!.year}';
  }

  bool get _hasRequiredFields {
    return _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _selectedDate != null &&
        _locationController.text.trim().isNotEmpty &&
        _educationController.text.trim().isNotEmpty &&
        _occupationController.text.trim().isNotEmpty &&
        _languagesController.text.trim().isNotEmpty;
  }

  void _continueToNextStep() {
    FocusScope.of(context).unfocus();

    if (!_hasRequiredFields) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all profile details before continuing.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileSetupIslamicProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final items = [
      _BasicInfoItem(
        icon: Icons.person_outline,
        label: 'Full name',
        value: _nameController.text,
        placeholder: 'Enter your full name',
        onTap: () => _editTextField(
          title: 'Full name',
          hintText: 'Enter your full name',
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
        ),
      ),
      _BasicInfoItem(
        icon: Icons.phone_outlined,
        label: 'Phone number',
        value: _phoneController.text,
        placeholder: 'Enter your phone number',
        onTap: () => _editTextField(
          title: 'Phone number',
          hintText: 'Enter your phone number',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
        ),
      ),
      _BasicInfoItem(
        icon: Icons.mail_outline,
        label: 'Email',
        value: _emailController.text,
        placeholder: 'Enter your email address',
        onTap: () => _editTextField(
          title: 'Email',
          hintText: 'Enter your email address',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
      ),
      _BasicInfoItem(
        icon: Icons.cake_outlined,
        label: 'Date of birth',
        value: _formattedBirthDate,
        placeholder: 'Select your date of birth',
        onTap: _pickDate,
      ),
      _BasicInfoItem(
        icon: Icons.location_on_outlined,
        label: 'Location',
        value: _locationController.text,
        placeholder: 'Enter your city and country',
        onTap: () => _editTextField(
          title: 'Location',
          hintText: 'Enter your city and country',
          controller: _locationController,
          textCapitalization: TextCapitalization.words,
        ),
      ),
      _BasicInfoItem(
        icon: Icons.school_outlined,
        label: 'Education',
        value: _educationController.text,
        placeholder: 'Enter your education level',
        onTap: () => _editTextField(
          title: 'Education',
          hintText: 'Enter your education level',
          controller: _educationController,
          textCapitalization: TextCapitalization.words,
        ),
      ),
      _BasicInfoItem(
        icon: Icons.work_outline,
        label: 'Occupation',
        value: _occupationController.text,
        placeholder: 'Enter your occupation',
        onTap: () => _editTextField(
          title: 'Occupation',
          hintText: 'Enter your occupation',
          controller: _occupationController,
          textCapitalization: TextCapitalization.words,
        ),
      ),
      _BasicInfoItem(
        icon: Icons.translate_outlined,
        label: 'Languages',
        value: _languagesController.text,
        placeholder: 'Example: Swahili, English, Arabic',
        onTap: () => _editTextField(
          title: 'Languages',
          hintText: 'Example: Swahili, English, Arabic',
          controller: _languagesController,
          textCapitalization: TextCapitalization.words,
        ),
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xfffbfbf7),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xfffdfdfb), Color(0xfff6f1e7)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xff1f1f1f),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Step 1 of 4',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff5f6368),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: const LinearProgressIndicator(
                      value: 0.25,
                      minHeight: 6,
                      backgroundColor: Color(0xffddd8cb),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          'Tell us about yourself',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff202124),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'This helps us find better matches for you.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xff6a6f73),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Photo upload can be connected after we add media support.',
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(56),
                      child: Column(
                        children: [
                          Container(
                            width: 94,
                            height: 94,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xffece8df),
                                  Color(0xffdfd8ca),
                                ],
                              ),
                              border: Border.all(
                                color: const Color(0xffddd8cb),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(29, 35, 30, 0.08),
                                  blurRadius: 18,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: const Color(0xfff9f7f2),
                                  child: Text(
                                    _nameController.text.isEmpty
                                        ? '+'
                                        : _nameController.text.trim()[0]
                                            .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.photo_camera_outlined,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Add photo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff4f555a),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xffe4dfd3)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(36, 41, 37, 0.05),
                          blurRadius: 22,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: items
                          .asMap()
                          .entries
                          .map(
                            (entry) => _ProfileInfoTile(
                              item: entry.value,
                              isFirst: entry.key == 0,
                              isLast: entry.key == items.length - 1,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xfff3eee4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xffe0d9cc)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Use your real details here. Clear profiles usually feel safer and get better responses.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: Color(0xff566067),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _continueToNextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'You can skip this for now and complete it later.',
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                      ),
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
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

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  final _BasicInfoItem item;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final hasValue = item.value.trim().isNotEmpty;

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(18) : Radius.zero,
        bottom: isLast ? const Radius.circular(18) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xffefeadf))),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xfff6f3eb),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, size: 18, color: AppColors.primaryGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff7a7f84),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasValue ? item.value : item.placeholder,
                    style: TextStyle(
                      fontSize: 15,
                      color: hasValue
                          ? const Color(0xff202124)
                          : const Color(0xff9aa0a6),
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xff91979c),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _BasicInfoItem {
  const _BasicInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String placeholder;
  final VoidCallback onTap;
}
