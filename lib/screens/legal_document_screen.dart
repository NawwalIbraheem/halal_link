import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.effectiveDate,
    required this.summary,
    required this.sections,
  });

  final String title;
  final String effectiveDate;
  final String summary;
  final List<LegalSection> sections;

  static List<LegalSection> termsOfServiceSections() {
    return const [
      LegalSection(
        heading: '1. Who Can Use Nikah Link',
        body:
            'Nikah Link is intended for adults who are using the platform for halal introductions, marriage discussions, and respectful communication. By creating an account, you confirm that the information you provide is accurate and that you are using the app for lawful purposes only.',
      ),
      LegalSection(
        heading: '2. Account Responsibilities',
        body:
            'You are responsible for keeping your login details safe, for all activity under your account, and for making sure your profile details stay truthful. You must not impersonate another person, misrepresent your identity, or create accounts for deceptive purposes.',
      ),
      LegalSection(
        heading: '3. Acceptable Conduct',
        body:
            'Users must communicate respectfully and use the app in a way that aligns with the marriage-focused purpose of the platform. Harassment, hate speech, fraud, threats, explicit sexual content, spam, and misuse of personal information are not allowed.',
      ),
      LegalSection(
        heading: '4. Profile Content',
        body:
            'You remain responsible for the text, photos, and other information you share. By uploading content, you give Nikah Link permission to display and process that content inside the app so the service can function, while you still keep ownership of your original content.',
      ),
      LegalSection(
        heading: '5. Matching And Messaging',
        body:
            'Nikah Link provides tools that help users discover profiles, express interest, and communicate. We do not guarantee compatibility, marriage outcomes, or the conduct of any individual user. You should use your judgment and take appropriate care before sharing sensitive personal details.',
      ),
      LegalSection(
        heading: '6. Safety And Enforcement',
        body:
            'We may review reports, limit features, suspend accounts, or remove content when needed to protect users or enforce platform rules. Repeated violations, abusive behavior, or attempts to bypass safety measures may lead to permanent account removal.',
      ),
      LegalSection(
        heading: '7. Service Availability',
        body:
            'We aim to keep the app available and reliable, but we cannot promise uninterrupted access at all times. Features may change, improve, pause, or be removed as the product develops.',
      ),
      LegalSection(
        heading: '8. Limitation Of Liability',
        body:
            'To the extent allowed by law, Nikah Link is provided on an as-available basis. We are not responsible for indirect losses, personal disputes between users, or decisions made by users based on profile information or conversations in the app.',
      ),
      LegalSection(
        heading: '9. Changes To These Terms',
        body:
            'We may update these terms as the platform grows. When that happens, the latest version shown in the app becomes the governing version from its effective date.',
      ),
    ];
  }

  static List<LegalSection> privacyPolicySections() {
    return const [
      LegalSection(
        heading: '1. Information We Collect',
        body:
            'We collect the information you provide during signup and profile setup, such as your name, email, phone number, date of birth, location, education, occupation, languages, Islamic profile details, and marriage preferences. We may also collect technical information needed to run and secure the app.',
      ),
      LegalSection(
        heading: '2. How We Use Information',
        body:
            'We use your information to create your account, personalize your profile, support matching and messaging features, improve the service, protect users, and respond to support or safety concerns.',
      ),
      LegalSection(
        heading: '3. Profile Visibility',
        body:
            'Some profile details are shown to other users so the matching experience can work. Sensitive settings, such as privacy preferences, should be respected according to the options available in the app.',
      ),
      LegalSection(
        heading: '4. Sharing Of Information',
        body:
            'We do not sell your personal data. We may share information with trusted service providers that help operate the app, or when disclosure is required for legal, security, fraud prevention, or enforcement reasons.',
      ),
      LegalSection(
        heading: '5. Data Storage And Security',
        body:
            'We take reasonable steps to protect personal information through technical and organizational safeguards. However, no system can guarantee complete security, so users should also take care with the information they choose to share.',
      ),
      LegalSection(
        heading: '6. Your Choices',
        body:
            'You may update parts of your profile inside the app. You can also stop using the service at any time. Requests related to account removal or privacy rights can be handled through the support process you establish for the app.',
      ),
      LegalSection(
        heading: '7. Retention',
        body:
            'We keep information for as long as it is needed to provide the service, comply with legal obligations, resolve disputes, and enforce our policies. Some records may remain in backups or logs for a limited period.',
      ),
      LegalSection(
        heading: '8. Children',
        body:
            'Nikah Link is not intended for children. Accounts should only be created by adults who meet the app’s eligibility rules.',
      ),
      LegalSection(
        heading: '9. Policy Updates',
        body:
            'We may update this privacy policy from time to time. The version displayed in the app with the current effective date will apply going forward.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppColors.primaryGreen,
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xfff6f9f7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xffdbe7df)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff202124),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Effective date: $effectiveDate',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        summary,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xff586169),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ...sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _LegalSectionCard(section: section),
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

class LegalSection {
  const LegalSection({
    required this.heading,
    required this.body,
  });

  final String heading;
  final String body;
}

class _LegalSectionCard extends StatelessWidget {
  const _LegalSectionCard({required this.section});

  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffe5e1d8)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 33, 24, 0.04),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.heading,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xff202124),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            section.body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Color(0xff5d666d),
            ),
          ),
        ],
      ),
    );
  }
}
