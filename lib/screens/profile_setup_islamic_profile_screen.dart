import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../services/profile_api_service.dart';
import '../utils/app_snackbar.dart';
import 'profile_setup_marriage_expectations_screen.dart';

class ProfileSetupIslamicProfileScreen extends StatefulWidget {
  const ProfileSetupIslamicProfileScreen({super.key});

  @override
  State<ProfileSetupIslamicProfileScreen> createState() =>
      _ProfileSetupIslamicProfileScreenState();
}

class _ProfileSetupIslamicProfileScreenState
    extends State<ProfileSetupIslamicProfileScreen> {
  final _goalsController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _prayerOptions = const [
    'Always',
    'Often',
    'Sometimes',
    'Rarely',
  ];

  final List<String> _quranActivityOptions = const [
    'I read the Quran',
    'I do Hifz',
    'I attend Tafsir classes',
    'I am learning Tajweed',
  ];

  final List<String> _quranFrequencyOptions = const [
    'Regularly',
    'Occasionally',
    'Learning',
    'Rarely',
  ];

  final List<String> _values = const [
    'Deen',
    'Character',
    'Modesty',
    'Family values',
    'Honesty',
    'Kindness',
  ];

  String _selectedPrayer = 'Often';
  String _selectedQuranActivity = 'I read the Quran';
  String _selectedQuranFrequency = 'Regularly';
  final Set<String> _selectedValues = {
    'Deen',
    'Character',
    'Modesty',
    'Family values',
  };

  @override
  void initState() {
    super.initState();
    _hydrateIslamicProfile();
  }

  @override
  void dispose() {
    _goalsController.dispose();
    super.dispose();
  }

  Future<void> _hydrateIslamicProfile() async {
    try {
      final profile = await ProfileApiService.getIslamicProfile();
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedPrayer =
            (profile['prayer_level'] as String?)?.isNotEmpty == true
            ? _prayerLabelFromApiValue(profile['prayer_level'] as String)
            : _selectedPrayer;
        _selectedQuranActivity =
            (profile['quran_activity'] as String?)?.isNotEmpty == true
            ? _quranActivityLabelFromApiValue(
                profile['quran_activity'] as String,
              )
            : _selectedQuranActivity;
        _selectedQuranFrequency =
            (profile['quran_frequency'] as String?)?.isNotEmpty == true
            ? _frequencyLabelFromApiValue(profile['quran_frequency'] as String)
            : _selectedQuranFrequency;
        _goalsController.text =
            (profile['islamic_goals'] as String?)?.isNotEmpty == true
            ? profile['islamic_goals'] as String
            : '';
        _selectedValues
          ..clear()
          ..addAll(
            (profile['marriage_values'] as List<dynamic>? ?? []).map(
              (value) => value.toString(),
            ),
          );
      });
    } catch (_) {
      // Keep the current blank/default selections if nothing has been saved yet.
    }
  }

  Future<void> _continueToNextStep() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (_goalsController.text.trim().isEmpty || _selectedValues.isEmpty) {
      AppSnackbar.show(
        context,
        'Please complete your Islamic profile before continuing.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    try {
      await ProfileApiService.updateIslamicProfile(
        prayerLevel: _selectedPrayer.toLowerCase(),
        quranActivity: _quranActivityToApiValue(_selectedQuranActivity),
        quranFrequency: _selectedQuranFrequency.toLowerCase(),
        islamicGoals: _goalsController.text.trim(),
        marriageValues: _selectedValues.toList(),
      );
      if (!mounted) {
        return;
      }
      AppSnackbar.show(
        context,
        'Islamic profile saved. Marriage expectations comes next.',
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ProfileSetupMarriageExpectationsScreen(),
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

  String _quranActivityToApiValue(String label) {
    switch (label) {
      case 'I do Hifz':
        return 'hifz';
      case 'I attend Tafsir classes':
        return 'tafsir';
      case 'I am learning Tajweed':
        return 'tajweed';
      default:
        return 'read_quran';
    }
  }

  String _quranActivityLabelFromApiValue(String value) {
    switch (value) {
      case 'hifz':
        return 'I do Hifz';
      case 'tafsir':
        return 'I attend Tafsir classes';
      case 'tajweed':
        return 'I am learning Tajweed';
      default:
        return 'I read the Quran';
    }
  }

  String _prayerLabelFromApiValue(String value) {
    switch (value) {
      case 'always':
        return 'Always';
      case 'sometimes':
        return 'Sometimes';
      case 'rarely':
        return 'Rarely';
      default:
        return 'Often';
    }
  }

  String _frequencyLabelFromApiValue(String value) {
    switch (value) {
      case 'occasionally':
        return 'Occasionally';
      case 'learning':
        return 'Learning';
      case 'rarely':
        return 'Rarely';
      default:
        return 'Regularly';
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
                          'Step 2 of 4',
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
                    value: 0.5,
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
                        'Your Islamic profile',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff202124),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Help others understand your deen.',
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
                  'How would you describe your prayer?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff40464b),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _prayerOptions.map((option) {
                    final isSelected = option == _selectedPrayer;
                    return _ChoiceChipButton(
                      label: option,
                      selected: isSelected,
                      onTap: () => setState(() => _selectedPrayer = option),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Quran learning',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff40464b),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xfff4efe4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xffd9d1c0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedQuranActivity,
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
                            items: _quranActivityOptions.map((option) {
                              return DropdownMenuItem<String>(
                                value: option,
                                child: Text(
                                  option,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xff1f3a32),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _selectedQuranActivity = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xfff4efe4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xffd9d1c0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedQuranFrequency,
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
                            items: _quranFrequencyOptions.map((option) {
                              return DropdownMenuItem<String>(
                                value: option,
                                child: Text(
                                  option,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xff1f3a32),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _selectedQuranFrequency = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Islamic goals',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff40464b),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffe1dccf)),
                  ),
                  child: TextField(
                    controller: _goalsController,
                    maxLines: 4,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      hintText:
                          'Share what you hope to improve in deen and family life.',
                      hintStyle: TextStyle(
                        color: Color(0xff98a0a6),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.fromLTRB(14, 14, 14, 12),
                      counterStyle: TextStyle(
                        color: Color(0xffa0a6ab),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Values important in marriage',
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
                  children: _values.map((value) {
                    final isSelected = _selectedValues.contains(value);
                    return _ValueToggle(
                      label: value,
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedValues.remove(value);
                          } else {
                            _selectedValues.add(value);
                          }
                        });
                      },
                    );
                  }).toList(),
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

class _ValueToggle extends StatelessWidget {
  const _ValueToggle({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffe1dccf)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: selected
                      ? AppColors.primaryGreen
                      : const Color(0xffc9c4b8),
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xff4f555a),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
