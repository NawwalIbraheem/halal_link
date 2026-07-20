import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../services/profile_api_service.dart';
import '../utils/app_snackbar.dart';
import 'profile_setup_lifestyle_screen.dart';

class ProfileSetupMarriageExpectationsScreen extends StatefulWidget {
  const ProfileSetupMarriageExpectationsScreen({super.key});

  @override
  State<ProfileSetupMarriageExpectationsScreen> createState() =>
      _ProfileSetupMarriageExpectationsScreenState();
}

class _ProfileSetupMarriageExpectationsScreenState
    extends State<ProfileSetupMarriageExpectationsScreen> {
  static const String _legacyQualitiesPlaceholder =
      'Practicing, kind, honest, supportive';

  final _formKey = GlobalKey<FormState>();
  final _qualitiesController = TextEditingController();

  bool _isSubmitting = false;
  String _selectedTimeline = 'Within 1 year';
  String _selectedChildrenPreference = 'In sha Allah';
  String _selectedLivingArrangement = 'Private home';
  String _selectedFamilyInvolvement = 'Medium';

  final List<String> _timelineOptions = const [
    'Within 6 months',
    'Within 1 year',
    'Within 2 years',
    'Flexible',
  ];

  final List<String> _childrenOptions = const [
    'Yes',
    'In sha Allah',
    'Not sure',
    'No',
  ];

  final List<String> _livingArrangementOptions = const [
    'Private home',
    'With family at first',
    'Flexible',
    'Separate apartment',
  ];

  final List<String> _familyInvolvementOptions = const [
    'Low',
    'Medium',
    'High',
  ];

  @override
  void initState() {
    super.initState();
    _hydrateMarriageExpectations();
  }

  @override
  void dispose() {
    _qualitiesController.dispose();
    super.dispose();
  }

  Future<void> _hydrateMarriageExpectations() async {
    try {
      final data = await ProfileApiService.getMarriageExpectations();
      if (!mounted) {
        return;
      }

      setState(() {
        final qualities = (data['qualities_looking_for'] as String? ?? '')
            .trim();
        _qualitiesController.text =
            qualities == _legacyQualitiesPlaceholder ? '' : qualities;
        final timeline = _timelineLabelFromApiValue(
          data['marriage_timeline'] as String? ?? '',
        );
        if (_timelineOptions.contains(timeline)) {
          _selectedTimeline = timeline;
        }
        final children = _childrenLabelFromApiValue(
          data['children_preference'] as String? ?? '',
        );
        if (_childrenOptions.contains(children)) {
          _selectedChildrenPreference = children;
        }
        final living = (data['preferred_living_arrangement'] as String? ?? '')
            .trim();
        if (living.isNotEmpty) {
          _selectedLivingArrangement = living;
        }
        final family = _familyLabelFromApiValue(
          data['family_involvement'] as String? ?? '',
        );
        if (_familyInvolvementOptions.contains(family)) {
          _selectedFamilyInvolvement = family;
        }
      });
    } catch (_) {
      // Keep seeded UI defaults if nothing has been saved yet.
    }
  }

  Future<void> _continueToNextStep() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ProfileApiService.updateMarriageExpectations(
        qualitiesLookingFor: _qualitiesController.text.trim(),
        marriageTimeline: _timelineApiValue(_selectedTimeline),
        childrenPreference: _childrenApiValue(_selectedChildrenPreference),
        preferredLivingArrangement: _selectedLivingArrangement,
        familyInvolvement: _familyApiValue(_selectedFamilyInvolvement),
      );
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ProfileSetupLifestyleScreen(),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackbar.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _timelineApiValue(String label) {
    switch (label) {
      case 'Within 6 months':
        return 'within_6_months';
      case 'Within 2 years':
        return 'within_2_years';
      case 'Flexible':
        return 'flexible';
      default:
        return 'within_1_year';
    }
  }

  String _timelineLabelFromApiValue(String value) {
    switch (value) {
      case 'within_6_months':
        return 'Within 6 months';
      case 'within_2_years':
        return 'Within 2 years';
      case 'flexible':
        return 'Flexible';
      default:
        return 'Within 1 year';
    }
  }

  String _childrenApiValue(String label) {
    switch (label) {
      case 'Yes':
        return 'yes';
      case 'Not sure':
        return 'not_sure';
      case 'No':
        return 'no';
      default:
        return 'in_sha_allah';
    }
  }

  String _childrenLabelFromApiValue(String value) {
    switch (value) {
      case 'yes':
        return 'Yes';
      case 'not_sure':
        return 'Not sure';
      case 'no':
        return 'No';
      default:
        return 'In sha Allah';
    }
  }

  String _familyApiValue(String label) {
    switch (label) {
      case 'Low':
        return 'low';
      case 'High':
        return 'high';
      default:
        return 'medium';
    }
  }

  String _familyLabelFromApiValue(String value) {
    switch (value) {
      case 'low':
        return 'Low';
      case 'high':
        return 'High';
      default:
        return 'Medium';
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
                            'Step 3 of 4',
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
                      value: 0.75,
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
                          'Marriage expectations',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff202124),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Let’s understand what you’re looking for.',
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
                  const Text(
                    'Qualities you’re looking for',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff40464b),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _qualitiesController,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Enter the qualities you are looking for';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Practicing, kind, honest, supportive',
                      hintStyle: const TextStyle(
                        color: Color(0xff98a0a6),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white,
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
                        borderSide: const BorderSide(
                          color: AppColors.primaryGreen,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'When do you want to get married?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff40464b),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DropdownCard(
                    value: _selectedTimeline,
                    items: _timelineOptions,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedTimeline = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Do you want children?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff40464b),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _childrenOptions.map((option) {
                      final isSelected = option == _selectedChildrenPreference;
                      return _ChoiceChipButton(
                        label: option,
                        selected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedChildrenPreference = option;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Preferred living arrangement',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff40464b),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DropdownCard(
                    value: _selectedLivingArrangement,
                    items: _livingArrangementOptions,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedLivingArrangement = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Family involvement preference',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff40464b),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DropdownCard(
                    value: _selectedFamilyInvolvement,
                    items: _familyInvolvementOptions,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedFamilyInvolvement = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownCard extends StatelessWidget {
  const _DropdownCard({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xfff4efe4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffd9d1c0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xfff4efe4),
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xff697077),
          ),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xff202124),
          ),
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
        ),
      ),
    );
  }
}

class _ChoiceChipButton extends StatelessWidget {
  const _ChoiceChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color.fromRGBO(1, 68, 51, 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryGreen : const Color(0xffe1dccf),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primaryGreen : const Color(0xff4f555a),
          ),
        ),
      ),
    );
  }
}
