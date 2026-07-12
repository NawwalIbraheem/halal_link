import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

class ProfileSetupIslamicProfileScreen extends StatefulWidget {
  const ProfileSetupIslamicProfileScreen({super.key});

  @override
  State<ProfileSetupIslamicProfileScreen> createState() =>
      _ProfileSetupIslamicProfileScreenState();
}

class _ProfileSetupIslamicProfileScreenState
    extends State<ProfileSetupIslamicProfileScreen> {
  final _goalsController = TextEditingController();

  final List<String> _prayerOptions = const [
    'Always',
    'Often',
    'Sometimes',
    'Rarely',
  ];

  final List<String> _quranOptions = const [
    'I read the Quran',
    'Regularly',
    'Occasionally',
    'Learning',
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
  String _selectedQuran = 'Regularly';
  final Set<String> _selectedValues = {
    'Deen',
    'Character',
    'Modesty',
    'Family values',
  };

  @override
  void initState() {
    super.initState();
    _goalsController.text =
        'I want to improve my deen, learn more about Islam and build a strong Islamic family.';
  }

  @override
  void dispose() {
    _goalsController.dispose();
    super.dispose();
  }

  void _continueToNextStep() {
    FocusScope.of(context).unfocus();

    if (_goalsController.text.trim().isEmpty || _selectedValues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your Islamic profile before continuing.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Islamic profile saved. Marriage expectations comes next.'),
      ),
    );
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xffe1dccf)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedQuran,
                              borderRadius: BorderRadius.circular(16),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xff697077),
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff202124),
                              ),
                              items: _quranOptions.map((option) {
                                return DropdownMenuItem<String>(
                                  value: option,
                                  child: Text(option),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _selectedQuran = value;
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
            color: selected
                ? AppColors.primaryGreen
                : const Color(0xffe1dccf),
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
