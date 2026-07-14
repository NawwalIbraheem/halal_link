import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../services/profile_api_service.dart';
import 'discover_screen.dart';

class ProfileSetupLifestyleScreen extends StatefulWidget {
  const ProfileSetupLifestyleScreen({super.key});

  @override
  State<ProfileSetupLifestyleScreen> createState() =>
      _ProfileSetupLifestyleScreenState();
}

class _ProfileSetupLifestyleScreenState
    extends State<ProfileSetupLifestyleScreen> {
  bool _isSubmitting = false;
  String _selectedHeightRange = '170 - 175 cm';
  String _selectedBodyType = 'Average';
  String _selectedCulturalBackground = 'Tanzanian';
  String _selectedDressStyle = 'Semi-formal';
  bool _photoPrivacyMatchesOnly = true;

  final List<String> _heightOptions = const [
    'Below 150 cm',
    '150 - 155 cm',
    '156 - 160 cm',
    '161 - 165 cm',
    '166 - 169 cm',
    '170 - 175 cm',
    '176 - 180 cm',
    '181 - 185 cm',
    'Above 185 cm',
  ];

  final List<String> _bodyTypeOptions = const [
    'Slim',
    'Average',
    'Athletic',
    'Broad',
  ];

  final List<String> _culturalBackgroundOptions = const [
    'Tanzanian',
    'Kenyan',
    'Ugandan',
    'Rwandan',
    'Burundian',
    'Ethiopian',
    'Somali',
    'Sudanese',
    'Comorian',
    'Other',
  ];

  final List<String> _dressStyleOptions = const [
    'Traditional',
    'Semi-formal',
    'Casual',
  ];

  @override
  void initState() {
    super.initState();
    _hydrateLifestyleProfile();
  }

  Future<void> _hydrateLifestyleProfile() async {
    try {
      final data = await ProfileApiService.getLifestyleProfile();
      if (!mounted) {
        return;
      }

      setState(() {
        final height = (data['height_range'] as String? ?? '').trim();
        if (_heightOptions.contains(height)) {
          _selectedHeightRange = height;
        }

        final bodyType = _bodyTypeLabelFromApiValue(
          data['body_type'] as String? ?? '',
        );
        if (_bodyTypeOptions.contains(bodyType)) {
          _selectedBodyType = bodyType;
        }

        final culturalBackground =
            (data['cultural_background'] as String? ?? '').trim();
        if (_culturalBackgroundOptions.contains(culturalBackground)) {
          _selectedCulturalBackground = culturalBackground;
        }

        final dressStyle = _dressStyleLabelFromApiValue(
          data['dress_style'] as String? ?? '',
        );
        if (_dressStyleOptions.contains(dressStyle)) {
          _selectedDressStyle = dressStyle;
        }

        _photoPrivacyMatchesOnly =
            data['photo_privacy_matches_only'] as bool? ?? true;
      });
    } catch (_) {
      // Keep seeded defaults if nothing has been saved yet.
    }
  }

  Future<void> _completeProfile() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
    });

    try {
      await ProfileApiService.updateLifestyleProfile(
        heightRange: _selectedHeightRange,
        bodyType: _bodyTypeApiValue(_selectedBodyType),
        culturalBackground: _selectedCulturalBackground,
        dressStyle: _dressStyleApiValue(_selectedDressStyle),
        photoPrivacyMatchesOnly: _photoPrivacyMatchesOnly,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile completed successfully.'),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DiscoverScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _bodyTypeApiValue(String label) {
    switch (label) {
      case 'Slim':
        return 'slim';
      case 'Athletic':
        return 'athletic';
      case 'Broad':
        return 'broad';
      default:
        return 'average';
    }
  }

  String _bodyTypeLabelFromApiValue(String value) {
    switch (value) {
      case 'slim':
        return 'Slim';
      case 'athletic':
        return 'Athletic';
      case 'broad':
        return 'Broad';
      default:
        return 'Average';
    }
  }

  String _dressStyleApiValue(String label) {
    switch (label) {
      case 'Traditional':
        return 'traditional';
      case 'Casual':
        return 'casual';
      default:
        return 'semi_formal';
    }
  }

  String _dressStyleLabelFromApiValue(String value) {
    switch (value) {
      case 'traditional':
        return 'Traditional';
      case 'casual':
        return 'Casual';
      default:
        return 'Semi-formal';
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
                          'Step 4 of 4',
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
                    value: 1,
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
                        'Physical & lifestyle information',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff202124),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Be open and honest. This builds trust.',
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
                const _FieldLabel('Height'),
                const SizedBox(height: 10),
                _DropdownCard(
                  value: _selectedHeightRange,
                  items: _heightOptions,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedHeightRange = value;
                    });
                  },
                ),
                const SizedBox(height: 18),
                const _FieldLabel('Body type'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _bodyTypeOptions.map((option) {
                    return _ChoiceChipButton(
                      label: option,
                      selected: option == _selectedBodyType,
                      onTap: () {
                        setState(() {
                          _selectedBodyType = option;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const _FieldLabel('Cultural background'),
                const SizedBox(height: 10),
                _DropdownCard(
                  value: _selectedCulturalBackground,
                  items: _culturalBackgroundOptions,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedCulturalBackground = value;
                    });
                  },
                ),
                const SizedBox(height: 18),
                const _FieldLabel('Dress style'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _dressStyleOptions.map((option) {
                    return _ChoiceChipButton(
                      label: option,
                      selected: option == _selectedDressStyle,
                      onTap: () {
                        setState(() {
                          _selectedDressStyle = option;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffe1dccf)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Photo privacy',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff202124),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Show my photos only to approved matches',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xff5f6368),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _photoPrivacyMatchesOnly,
                        onChanged: (value) {
                          setState(() {
                            _photoPrivacyMatchesOnly = value;
                          });
                        },
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.primaryGreen,
                        thumbColor: WidgetStateProperty.resolveWith((states) {
                          return Colors.white;
                        }),
                        inactiveTrackColor: const Color(0xffc9c3b6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _completeProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _isSubmitting ? 'Saving...' : 'Complete profile',
                      style: const TextStyle(
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
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xff40464b),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe1dccf)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
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
            return DropdownMenuItem<String>(value: item, child: Text(item));
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
