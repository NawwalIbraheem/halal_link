import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import '../constants/app_colors.dart';
import '../constants/profile_setup_options.dart';
import '../services/profile_api_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/auth_session_store.dart';
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
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  DateTime? _selectedDate;
  String? _selectedLocation;
  String? _selectedEducationLevel;
  String? _selectedOccupation;
  Uint8List? _selectedPhotoBytes;
  final Set<String> _selectedLanguages = <String>{};
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: (AuthSessionStore.user['full_name'] as String?) ?? widget.fullName,
    );
    _phoneController = TextEditingController(
      text:
          (AuthSessionStore.user['phone_number'] as String?) ??
          widget.phoneNumber,
    );
    _emailController = TextEditingController(
      text: (AuthSessionStore.user['email'] as String?) ?? widget.email,
    );
    _hydrateProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _hydrateProfile() async {
    try {
      await AuthSessionStore.load();
      if (!mounted) {
        return;
      }
      _populateFromProfile(AuthSessionStore.user);
      final profile = await ProfileApiService.getBasicProfile();
      if (!mounted) {
        return;
      }
      _populateFromProfile(profile);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _populateFromProfile(AuthSessionStore.user);
    }
  }

  void _populateFromProfile(Map<String, dynamic> profile) {
    final languagesValue = (profile['languages'] as String? ?? '').trim();
    final parsedLanguages = languagesValue.isEmpty
        ? <String>{}
        : languagesValue
              .split(',')
              .map((language) => language.trim())
              .where((language) => language.isNotEmpty)
              .toSet();

    final dateText = profile['date_of_birth']?.toString() ?? '';
    final parsedDate = dateText.isEmpty ? null : DateTime.tryParse(dateText);
    final photoBase64 = (profile['profile_photo_base64'] as String? ?? '').trim();
    final photoBytes = _decodePhotoBytes(photoBase64);

    setState(() {
      _nameController.text =
          (profile['full_name'] as String? ?? _nameController.text).trim();
      _phoneController.text =
          (profile['phone_number'] as String? ?? _phoneController.text).trim();
      _emailController.text =
          (profile['email'] as String? ?? _emailController.text).trim();
      _selectedDate = parsedDate ?? _selectedDate;
      _selectedLocation = _normalizeDropdownValue(
        profile['location'] as String?,
        ProfileSetupOptions.eastAfricanRegions,
      );
      _selectedEducationLevel = _normalizeDropdownValue(
        profile['education'] as String?,
        ProfileSetupOptions.educationLevels,
      );
      _selectedOccupation = _normalizeDropdownValue(
        profile['occupation'] as String?,
        ProfileSetupOptions.occupations,
      );
      _selectedLanguages
        ..clear()
        ..addAll(parsedLanguages);
      _selectedPhotoBytes = photoBytes;
    });
  }

  Uint8List? _decodePhotoBytes(String encodedValue) {
    if (encodedValue.isEmpty) {
      return null;
    }

    try {
      return base64Decode(encodedValue);
    } catch (_) {
      return null;
    }
  }

  String? _normalizeDropdownValue(String? rawValue, List<String> items) {
    final trimmedValue = rawValue?.trim() ?? '';
    if (trimmedValue.isEmpty) {
      return null;
    }

    return items.contains(trimmedValue) ? trimmedValue : null;
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final latestAllowedDate = DateTime.now().subtract(
      const Duration(days: 365 * 18),
    );

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1998, 1, 1),
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

    if (!mounted || pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  Future<void> _pickLanguages() async {
    FocusScope.of(context).unfocus();
    final tempSelection = Set<String>.from(_selectedLanguages);
    var searchQuery = '';

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredLanguages = ProfileSetupOptions.languages
                .where(
                  (language) => language.toLowerCase().contains(
                    searchQuery.toLowerCase().trim(),
                  ),
                )
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: Color(0xfffbfbf7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xffd6d0c2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Select languages',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff202124),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xff6d7378),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) {
                          setModalState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search languages',
                          hintStyle: const TextStyle(
                            color: Color(0xff9aa0a6),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xff6d7378),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xffe1dccf),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primaryGreen,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xffe4dfd3)),
                          ),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: filteredLanguages.length,
                            separatorBuilder: (_, _) => const Divider(
                              height: 1,
                              color: Color(0xffefeadf),
                            ),
                            itemBuilder: (context, index) {
                              final language = filteredLanguages[index];
                              final isSelected = tempSelection.contains(
                                language,
                              );
                              return CheckboxListTile(
                                value: isSelected,
                                activeColor: AppColors.primaryGreen,
                                checkboxShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(
                                  language,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff202124),
                                  ),
                                ),
                                onChanged: (_) {
                                  setModalState(() {
                                    if (isSelected) {
                                      tempSelection.remove(language);
                                    } else {
                                      tempSelection.add(language);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.of(context).pop(tempSelection),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Save languages',
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
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _selectedLanguages
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> _selectPhoto() async {
    FocusScope.of(context).unfocus();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add profile photo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff202124),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose how you want to add your photo.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xff667078),
                  ),
                ),
                const SizedBox(height: 18),
                _PhotoSourceTile(
                  icon: Icons.photo_camera_outlined,
                  title: 'Take photo',
                  subtitle: 'Open the camera',
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                const SizedBox(height: 10),
                _PhotoSourceTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Choose from gallery',
                  subtitle: 'Select an existing picture',
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || source == null) {
      return;
    }

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1400,
      );

      if (!mounted || pickedFile == null) {
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedPhotoBytes = bytes;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackbar.show(
        context,
        'Could not open the camera or gallery. Please try again.',
      );
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

  Future<void> _continueToNextStep() async {
    if (_isNavigating) {
      return;
    }

    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState!.validate();
    final hasDate = _selectedDate != null;
    final hasLanguages = _selectedLanguages.isNotEmpty;

    if (!formValid || !hasDate || !hasLanguages) {
      AppSnackbar.show(
        context,
        'Please complete all required profile details.',
      );
      return;
    }

    setState(() {
      _isNavigating = true;
    });

    try {
      await ProfileApiService.updateBasicProfile(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        dateOfBirth:
            '${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
        location: _selectedLocation ?? '',
        education: _selectedEducationLevel ?? '',
        occupation: _selectedOccupation ?? '',
        languages: _selectedLanguages.toList()..sort(),
        profilePhotoBase64: _selectedPhotoBytes == null
            ? ''
            : base64Encode(_selectedPhotoBytes!),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => const ProfileSetupIslamicProfileScreen(),
            ),
          )
          .then((_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isNavigating = false;
            });
          });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isNavigating = false;
      });
      AppSnackbar.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 16),
            child: Form(
              key: _formKey,
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
                      onTap: _selectPhoto,
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
                                colors: [Color(0xffece8df), Color(0xffdfd8ca)],
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
                                  backgroundImage: _selectedPhotoBytes == null
                                      ? null
                                      : MemoryImage(_selectedPhotoBytes!),
                                  child: _selectedPhotoBytes == null
                                      ? Text(
                                          _nameController.text.trim().isEmpty
                                              ? '+'
                                              : _nameController.text
                                                    .trim()[0]
                                                    .toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryGreen,
                                          ),
                                        )
                                      : null,
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
                          Text(
                            _selectedPhotoBytes == null ? 'Add photo' : 'Change photo',
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
                    padding: const EdgeInsets.all(18),
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
                      children: [
                        _ReadOnlyProfileField(
                          label: 'Full name',
                          controller: _nameController,
                          icon: Icons.person_outline,
                          fallbackText: 'Saved from your account',
                        ),
                        const SizedBox(height: 14),
                        _ReadOnlyProfileField(
                          label: 'Phone number',
                          controller: _phoneController,
                          icon: Icons.phone_outlined,
                          fallbackText: 'Saved from your account',
                        ),
                        const SizedBox(height: 14),
                        _ReadOnlyProfileField(
                          label: 'Email',
                          controller: _emailController,
                          icon: Icons.mail_outline,
                          fallbackText: 'Saved from your account',
                        ),
                        const SizedBox(height: 14),
                        _DateField(
                          label: 'Date of birth',
                          value: _formattedBirthDate,
                          onTap: _pickDate,
                          validator: () {
                            if (_selectedDate == null) {
                              return 'Select your date of birth';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _DropdownField(
                          label: 'Location',
                          value: _selectedLocation,
                          items: ProfileSetupOptions.eastAfricanRegions,
                          hintText: 'Select your region',
                          icon: Icons.location_on_outlined,
                          onChanged: (value) {
                            setState(() {
                              _selectedLocation = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Select your location';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _DropdownField(
                          label: 'Education level',
                          value: _selectedEducationLevel,
                          items: ProfileSetupOptions.educationLevels,
                          hintText: 'Select your education level',
                          icon: Icons.school_outlined,
                          onChanged: (value) {
                            setState(() {
                              _selectedEducationLevel = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Select your education level';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _DropdownField(
                          label: 'Occupation',
                          value: _selectedOccupation,
                          items: ProfileSetupOptions.occupations,
                          hintText: 'Select your occupation',
                          icon: Icons.work_outline,
                          onChanged: (value) {
                            setState(() {
                              _selectedOccupation = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Select your occupation';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _LanguageField(
                          selectedLanguages: _selectedLanguages.toList()
                            ..sort(),
                          onTap: _pickLanguages,
                          validator: () {
                            if (_selectedLanguages.isEmpty) {
                              return 'Select at least one language';
                            }
                            return null;
                          },
                        ),
                      ],
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
                            'Your account details are already carried from signup. Add the rest of your profile here so we can match you better.',
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
                        AppSnackbar.show(
                          context,
                          'You can skip this for now and complete it later.',
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

class _PhotoSourceTile extends StatelessWidget {
  const _PhotoSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xfff8f6f0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffe5dfd2)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(1, 68, 51, 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryGreen, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff202124),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xff667078),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xff8a9298),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyProfileField extends StatelessWidget {
  const _ReadOnlyProfileField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.fallbackText,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    final hasValue = controller.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xff7a7f84),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            hintText: fallbackText,
            hintStyle: const TextStyle(color: Color(0xff9aa0a6), fontSize: 14),
            filled: true,
            fillColor: const Color(0xfff7f4ed),
            prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xffe1dccf)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xffe1dccf)),
            ),
          ),
          style: TextStyle(
            color: hasValue ? const Color(0xff202124) : const Color(0xff889097),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.hintText,
    required this.icon,
    required this.onChanged,
    required this.validator,
  });

  final String label;
  final String? value;
  final List<String> items;
  final String hintText;
  final IconData icon;
  final ValueChanged<String?> onChanged;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    final normalizedValue = items.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xff7a7f84),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: normalizedValue,
          dropdownColor: const Color(0xfff4efe4),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xff1f3a32),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xff697077),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xff9aa0a6), fontSize: 14),
            filled: true,
            fillColor: const Color(0xfff4efe4),
            prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xffd9d1c0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primaryGreen,
                width: 1.2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xffc43d34)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xffc43d34)),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateField extends FormField<String> {
  _DateField({
    required String label,
    required String value,
    required VoidCallback onTap,
    required String? Function() validator,
  }) : super(
         validator: (_) => validator(),
         builder: (state) {
           final hasValue = value.trim().isNotEmpty;

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 label,
                 style: const TextStyle(
                   fontSize: 12,
                   color: Color(0xff7a7f84),
                   fontWeight: FontWeight.w600,
                 ),
               ),
               const SizedBox(height: 8),
               InkWell(
                 onTap: onTap,
                 borderRadius: BorderRadius.circular(14),
                 child: Container(
                   padding: const EdgeInsets.symmetric(
                     horizontal: 14,
                     vertical: 16,
                   ),
                   decoration: BoxDecoration(
                     color: const Color(0xfffcfbf7),
                     borderRadius: BorderRadius.circular(14),
                     border: Border.all(
                       color: state.hasError
                           ? const Color(0xffc43d34)
                           : const Color(0xffe1dccf),
                     ),
                   ),
                   child: Row(
                     children: [
                       const Icon(
                         Icons.cake_outlined,
                         color: AppColors.primaryGreen,
                         size: 20,
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Text(
                           hasValue ? value : 'Select your date of birth',
                           style: TextStyle(
                             fontSize: 14,
                             color: hasValue
                                 ? const Color(0xff202124)
                                 : const Color(0xff9aa0a6),
                             fontWeight: hasValue
                                 ? FontWeight.w600
                                 : FontWeight.w500,
                           ),
                         ),
                       ),
                       const Icon(
                         Icons.chevron_right_rounded,
                         color: Color(0xff91979c),
                       ),
                     ],
                   ),
                 ),
               ),
               if (state.hasError) ...[
                 const SizedBox(height: 6),
                 Text(
                   state.errorText!,
                   style: const TextStyle(
                     color: Color(0xffc43d34),
                     fontSize: 12,
                   ),
                 ),
               ],
             ],
           );
         },
       );
}

class _LanguageField extends FormField<String> {
  _LanguageField({
    required List<String> selectedLanguages,
    required VoidCallback onTap,
    required String? Function() validator,
  }) : super(
         validator: (_) => validator(),
         builder: (state) {
           final hasSelection = selectedLanguages.isNotEmpty;

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               const Text(
                 'Languages',
                 style: TextStyle(
                   fontSize: 12,
                   color: Color(0xff7a7f84),
                   fontWeight: FontWeight.w600,
                 ),
               ),
               const SizedBox(height: 8),
               InkWell(
                 onTap: onTap,
                 borderRadius: BorderRadius.circular(14),
                 child: Container(
                   width: double.infinity,
                   padding: const EdgeInsets.symmetric(
                     horizontal: 14,
                     vertical: 16,
                   ),
                   decoration: BoxDecoration(
                     color: const Color(0xfffcfbf7),
                     borderRadius: BorderRadius.circular(14),
                     border: Border.all(
                       color: state.hasError
                           ? const Color(0xffc43d34)
                           : const Color(0xffe1dccf),
                     ),
                   ),
                   child: Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Padding(
                         padding: EdgeInsets.only(top: 1),
                         child: Icon(
                           Icons.translate_outlined,
                           color: AppColors.primaryGreen,
                           size: 20,
                         ),
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: hasSelection
                             ? Wrap(
                                 spacing: 8,
                                 runSpacing: 8,
                                 children: selectedLanguages.map((language) {
                                   return Container(
                                     padding: const EdgeInsets.symmetric(
                                       horizontal: 10,
                                       vertical: 6,
                                     ),
                                     decoration: BoxDecoration(
                                       color: const Color.fromRGBO(
                                         1,
                                         68,
                                         51,
                                         0.08,
                                       ),
                                       borderRadius: BorderRadius.circular(999),
                                     ),
                                     child: Text(
                                       language,
                                       style: const TextStyle(
                                         fontSize: 12,
                                         fontWeight: FontWeight.w600,
                                         color: AppColors.primaryGreen,
                                       ),
                                     ),
                                   );
                                 }).toList(),
                               )
                             : const Text(
                                 'Select the languages you speak',
                                 style: TextStyle(
                                   color: Color(0xff9aa0a6),
                                   fontSize: 14,
                                 ),
                               ),
                       ),
                       const SizedBox(width: 8),
                       const Icon(
                         Icons.keyboard_arrow_down_rounded,
                         color: Color(0xff697077),
                       ),
                     ],
                   ),
                 ),
               ),
               if (state.hasError) ...[
                 const SizedBox(height: 6),
                 Text(
                   state.errorText!,
                   style: const TextStyle(
                     color: Color(0xffc43d34),
                     fontSize: 12,
                   ),
                 ),
               ],
             ],
           );
         },
       );
}
