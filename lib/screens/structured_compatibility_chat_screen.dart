import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../services/profile_api_service.dart';
import '../utils/app_snackbar.dart';
import 'discover_screen.dart';
import 'messaging_screen.dart';

class StructuredCompatibilityChatScreen extends StatefulWidget {
  const StructuredCompatibilityChatScreen({
    super.key,
    required this.matchedUserName,
    required this.matchInterestId,
  });

  final String matchedUserName;
  final int matchInterestId;

  @override
  State<StructuredCompatibilityChatScreen> createState() =>
      _StructuredCompatibilityChatScreenState();
}

class _StructuredCompatibilityChatScreenState
    extends State<StructuredCompatibilityChatScreen> {
  final TextEditingController _answerController = TextEditingController();
  final List<CompatibilityQuestion> _questions = _buildQuestions();
  final Map<int, String> _answers = <int, String>{};
  int _currentQuestionIndex = 0;
  String? _selectedOption;
  bool _isSubmitting = false;
  bool _isLoadingSavedProgress = true;

  CompatibilityQuestion get _currentQuestion => _questions[_currentQuestionIndex];

  bool get _isLastQuestion => _currentQuestionIndex == _questions.length - 1;

  @override
  void initState() {
    super.initState();
    _loadSavedProgress();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedProgress() async {
    try {
      final summary = await ProfileApiService.getStructuredConversationSummary(
        matchInterestId: widget.matchInterestId,
      );
      final questionSummaries = (summary['questions'] as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      for (final item in questionSummaries) {
        final index = item['question_index'] as int?;
        final answer = (item['your_answer'] as String? ?? '').trim();
        if (index != null && answer.isNotEmpty) {
          _answers[index] = answer;
        }
      }

      final allAnswered = _questions.every(
        (question) => (_answers[question.questionIndex] ?? '').trim().isNotEmpty,
      );

      if (!mounted) {
        return;
      }

      if (allAnswered) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => StructuredCompatibilitySummaryScreen(
              matchedUserName: widget.matchedUserName,
              questions: _questions,
              answers: _answers,
              matchInterestId: widget.matchInterestId,
            ),
          ),
        );
        return;
      }

      final firstUnansweredIndex = _questions.indexWhere(
        (question) => (_answers[question.questionIndex] ?? '').trim().isEmpty,
      );

      setState(() {
        _currentQuestionIndex = firstUnansweredIndex < 0 ? 0 : firstUnansweredIndex;
        _isLoadingSavedProgress = false;
      });

      final currentSavedAnswer = _answers[_currentQuestion.questionIndex] ?? '';
      if (_currentQuestion.options.isNotEmpty) {
        _selectedOption = currentSavedAnswer.isEmpty ? null : currentSavedAnswer;
        _answerController.clear();
      } else {
        _selectedOption = null;
        _answerController.text = currentSavedAnswer;
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingSavedProgress = false;
      });
    }
  }

  Future<void> _submitCurrentAnswer() async {
    final question = _currentQuestion;
    final textAnswer = _answerController.text.trim();
    final selectedAnswer = _selectedOption?.trim() ?? '';
    final answer = question.options.isNotEmpty ? selectedAnswer : textAnswer;

    if (answer.isEmpty) {
      AppSnackbar.show(context, 'Please provide your answer before continuing.');
      return;
    }

    _answers[question.questionIndex] = answer;

    if (_isLastQuestion) {
      setState(() {
        _isSubmitting = true;
      });
      try {
        await ProfileApiService.saveStructuredConversationAnswers(
          matchInterestId: widget.matchInterestId,
          answers: _answers.entries
              .map(
                (entry) => <String, dynamic>{
                  'question_index': entry.key,
                  'answer': entry.value,
                },
              )
              .toList(),
        );

        if (!mounted) {
          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StructuredCompatibilitySummaryScreen(
              matchedUserName: widget.matchedUserName,
              questions: _questions,
              answers: _answers,
              matchInterestId: widget.matchInterestId,
            ),
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
      return;
    }

    setState(() {
      _currentQuestionIndex += 1;
      final nextAnswer =
          _answers[_questions[_currentQuestionIndex].questionIndex] ?? '';
      if (_questions[_currentQuestionIndex].options.isNotEmpty) {
        _selectedOption = nextAnswer.isEmpty ? null : nextAnswer;
        _answerController.clear();
      } else {
        _selectedOption = null;
        _answerController.text = nextAnswer;
      }
    });
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex == 0) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _currentQuestionIndex -= 1;
      final previousAnswer =
          _answers[_questions[_currentQuestionIndex].questionIndex] ?? '';
      if (_questions[_currentQuestionIndex].options.isNotEmpty) {
        _selectedOption = previousAnswer.isEmpty ? null : previousAnswer;
        _answerController.clear();
      } else {
        _selectedOption = null;
        _answerController.text = previousAnswer;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSavedProgress) {
      return const Scaffold(
        backgroundColor: Color(0xfff2f4f7),
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final question = _currentQuestion;
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 1.5,
                      child: InkWell(
                        onTap: _goToPreviousQuestion,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xff202825),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: const Color(0xffe7efe9),
                      child: Text(
                        widget.matchedUserName.isEmpty
                            ? '?'
                            : widget.matchedUserName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.matchedUserName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff18201e),
                            ),
                          ),
                          const Text(
                            'Structured conversation',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.more_vert_rounded, color: Color(0xff5a6460)),
                  ],
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff25302d),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xffe1e4e0),
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(29, 53, 39, 0.08),
                                blurRadius: 24,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xffedf6ef),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  question.topic,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 24,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xfff3fbf5),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Text(
                                  question.prompt,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryGreen,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                question.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Color(0xff66726d),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 18),
                              if (question.options.isNotEmpty) ...[
                                const Text(
                                  'Choose one answer',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff24312d),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: question.options.map((option) {
                                    final isSelected = _selectedOption == option;
                                    return ChoiceChip(
                                      label: Text(option),
                                      selected: isSelected,
                                      onSelected: (_) {
                                        setState(() {
                                          _selectedOption = option;
                                        });
                                      },
                                      backgroundColor: const Color(0xffeef2f5),
                                      selectedColor: const Color(0xffe0f1e4),
                                      side: BorderSide(
                                        color: isSelected
                                            ? AppColors.primaryGreen
                                            : const Color(0xffe2e0d8),
                                      ),
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? AppColors.primaryGreen
                                            : const Color(0xff485451),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ] else ...[
                                const Text(
                                  'Write your answer',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff24312d),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _answerController,
                                  maxLength: 300,
                                  minLines: 5,
                                  maxLines: 7,
                                  decoration: InputDecoration(
                                    hintText: 'Type your answer here...',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.all(16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: const BorderSide(
                                        color: Color(0xffdde3de),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: const BorderSide(
                                        color: Color(0xffdde3de),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: const BorderSide(
                                        color: AppColors.primaryGreen,
                                        width: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _submitCurrentAnswer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(54),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    _isSubmitting
                                        ? 'Saving...'
                                        : _isLastQuestion
                                        ? 'Finish topics'
                                        : 'Submit answer',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Both of you will see each other\'s answers after submitting.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: Color(0xff6b7471),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.primaryGreen,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Discussion will be unlocked after both answers are submitted.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: Color(0xff5f6a66),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
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
    );
  }
}

class StructuredCompatibilitySummaryScreen extends StatefulWidget {
  const StructuredCompatibilitySummaryScreen({
    super.key,
    required this.matchedUserName,
    required this.questions,
    required this.answers,
    required this.matchInterestId,
  });

  final String matchedUserName;
  final List<CompatibilityQuestion> questions;
  final Map<int, String> answers;
  final int matchInterestId;

  @override
  State<StructuredCompatibilitySummaryScreen> createState() =>
      _StructuredCompatibilitySummaryScreenState();
}

class _StructuredCompatibilitySummaryScreenState
    extends State<StructuredCompatibilitySummaryScreen> {
  String? _compatibilityDecision;
  String? _familyStepDecision;
  Map<int, String> _matchedUserAnswers = <int, String>{};
  String _matchedCompatibilityDecision = '';
  String _matchedFamilyStepDecision = '';
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _chatUnlocked = false;

  bool get _matchedUserHasAnsweredReflection =>
      _matchedCompatibilityDecision.isNotEmpty || _matchedFamilyStepDecision.isNotEmpty;

  bool get _matchedUserRejected =>
      _matchedUserHasAnsweredReflection &&
      (_matchedCompatibilityDecision != 'Yes, I would like to continue.' ||
          _matchedFamilyStepDecision != 'Yes');

  String get _matchedDecisionStatus {
    if (_chatUnlocked) {
      return 'Accepted';
    }
    if (_matchedUserRejected) {
      return 'Rejected';
    }
    if (_matchedUserHasAnsweredReflection) {
      return 'Waiting for final unlock';
    }
    return 'They have not answered yet.';
  }

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await ProfileApiService.getStructuredConversationSummary(
        matchInterestId: widget.matchInterestId,
      );
      final questions = (summary['questions'] as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final currentReflection = Map<String, dynamic>.from(
        summary['current_user_reflection'] as Map? ?? const <String, dynamic>{},
      );
      final matchedReflection = Map<String, dynamic>.from(
        summary['matched_user_reflection'] as Map? ?? const <String, dynamic>{},
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _matchedUserAnswers = {
          for (final item in questions)
            item['question_index'] as int:
                (item['their_answer'] as String? ?? '').trim(),
        };
        _compatibilityDecision =
            (currentReflection['compatibility_decision'] as String? ?? '').trim().isEmpty
                ? null
                : (currentReflection['compatibility_decision'] as String).trim();
        _familyStepDecision =
            (currentReflection['family_step_decision'] as String? ?? '').trim().isEmpty
                ? null
                : (currentReflection['family_step_decision'] as String).trim();
        _matchedCompatibilityDecision =
            (matchedReflection['compatibility_decision'] as String? ?? '').trim();
        _matchedFamilyStepDecision =
            (matchedReflection['family_step_decision'] as String? ?? '').trim();
        _chatUnlocked = summary['chat_unlocked'] as bool? ?? false;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      AppSnackbar.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _completeFlow() async {
    if (_compatibilityDecision == null || _familyStepDecision == null) {
      AppSnackbar.show(context, 'Please answer both reflection questions.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    try {
      final summary = await ProfileApiService.submitStructuredConversationReflection(
        matchInterestId: widget.matchInterestId,
        compatibilityDecision: _compatibilityDecision!,
        familyStepDecision: _familyStepDecision!,
      );

      if (!mounted) {
        return;
      }

      final chatUnlocked = summary['chat_unlocked'] as bool? ?? false;
      final matchedReflection = Map<String, dynamic>.from(
        summary['matched_user_reflection'] as Map? ?? const <String, dynamic>{},
      );

      if (chatUnlocked) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MessagingScreen(
              matchedUserName: widget.matchedUserName,
              matchInterestId: widget.matchInterestId,
            ),
          ),
        );
        return;
      }

      setState(() {
        _chatUnlocked = false;
        _matchedCompatibilityDecision =
            (matchedReflection['compatibility_decision'] as String? ?? '').trim();
        _matchedFamilyStepDecision =
            (matchedReflection['family_step_decision'] as String? ?? '').trim();
      });
      AppSnackbar.show(
        context,
        _matchedUserRejected
            ? '${widget.matchedUserName} rejected the match.'
            : 'Your reflection was saved. Chat will unlock after both of you agree to continue.',
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const DiscoverScreen(initialTabIndex: 1),
        ),
        (route) => false,
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

  @override
  Widget build(BuildContext context) {
    final topicCount = widget.questions.map((item) => item.topic).toSet().length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 1.5,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xff202825),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Conversation Summary',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff18201e),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(29, 53, 39, 0.08),
                                blurRadius: 24,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You completed $topicCount topics with ${widget.matchedUserName}.',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xff1e2925),
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${widget.answers.length} answers submitted. Review your final reflection below before deciding the next step.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Color(0xff697176),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Shared answers',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xff1e2925),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Now that both of you completed the structured questions, you can review each other\'s answers here.',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Color(0xff697176),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 18),
                              ...List<Widget>.generate(
                                widget.questions.length,
                                (index) {
                                  final question = widget.questions[index];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: index == widget.questions.length - 1 ? 0 : 16,
                                    ),
                                    child: _AnswerComparisonCard(
                                      topic: question.topic,
                                      prompt: question.prompt,
                                      yourAnswer: widget.answers[index] ?? 'Not answered',
                                      theirAnswer:
                                          (_matchedUserAnswers[index] ?? '').isEmpty
                                              ? 'They have not answered yet.'
                                              : _matchedUserAnswers[index]!,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _ReflectionCard(
                          title:
                              'After these discussions, do you believe this person is compatible with you for marriage?',
                          options: const [
                            'Yes, I would like to continue.',
                            'I need more discussion.',
                            'I don\'t think we\'re compatible.',
                          ],
                          selectedValue: _compatibilityDecision,
                          onChanged: (value) {
                            setState(() {
                              _compatibilityDecision = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _ReflectionCard(
                          title:
                              'Would you like to proceed toward involving your families?',
                          options: const [
                            'Yes',
                            'Not yet',
                            'No',
                          ],
                          selectedValue: _familyStepDecision,
                          onChanged: (value) {
                            setState(() {
                              _familyStepDecision = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _ReflectionStatusCard(
                          title: '${widget.matchedUserName}\'s reflection',
                          items: [
                            'Status: $_matchedDecisionStatus',
                            'Compatibility: ${_matchedCompatibilityDecision.isEmpty ? 'They have not answered yet.' : _matchedCompatibilityDecision}',
                            'Family step: ${_matchedFamilyStepDecision.isEmpty ? 'They have not answered yet.' : _matchedFamilyStepDecision}',
                          ],
                        ),
                        if (_chatUnlocked) ...[
                          const SizedBox(height: 16),
                          const _ReflectionStatusCard(
                            title: 'Chat unlocked',
                            items: [
                              'Both of you agreed to continue.',
                              'You can now move into private messaging.',
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const DiscoverScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryGreen,
                          side: const BorderSide(color: AppColors.primaryGreen),
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Back to home',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _completeFlow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _chatUnlocked ? 'Go to chat' : 'Complete reflection',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerComparisonCard extends StatelessWidget {
  const _AnswerComparisonCard({
    required this.topic,
    required this.prompt,
    required this.yourAnswer,
    required this.theirAnswer,
  });

  final String topic;
  final String prompt;
  final String yourAnswer;
  final String theirAnswer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfff2f4f7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffdfe5ea)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xffedf6ef),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              topic,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            prompt,
            style: const TextStyle(
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: Color(0xff1f2825),
            ),
          ),
          const SizedBox(height: 14),
          _AnswerBubble(
            label: 'Your answer',
            answer: yourAnswer,
            isPrimary: false,
          ),
          const SizedBox(height: 10),
          _AnswerBubble(
            label: 'Their answer',
            answer: theirAnswer,
            isPrimary: true,
          ),
        ],
      ),
    );
  }
}

class _AnswerBubble extends StatelessWidget {
  const _AnswerBubble({
    required this.label,
    required this.answer,
    required this.isPrimary,
  });

  final String label;
  final String answer;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xffeaf7ef) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPrimary ? const Color(0xffcce5d2) : const Color(0xffe2ddd1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isPrimary ? AppColors.primaryGreen : const Color(0xff697176),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xff24312d),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReflectionStatusCard extends StatelessWidget {
  const _ReflectionStatusCard({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xffedf6ef),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xff264234),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  const _ReflectionCard({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  final String title;
  final List<String> options;
  final String? selectedValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xff1e2925),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((option) {
              final isSelected = option == selectedValue;
              return ChoiceChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (_) => onChanged(option),
                backgroundColor: const Color(0xffeef2f5),
                selectedColor: const Color(0xffe0f1e4),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : const Color(0xffe2e0d8),
                ),
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : const Color(0xff485451),
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class CompatibilityQuestion {
  const CompatibilityQuestion({
    required this.questionIndex,
    required this.topic,
    required this.prompt,
    required this.description,
    this.options = const <String>[],
  });

  final int questionIndex;
  final String topic;
  final String prompt;
  final String description;
  final List<String> options;
}

List<CompatibilityQuestion> _buildQuestions() {
  return const <CompatibilityQuestion>[
    CompatibilityQuestion(
      questionIndex: 0,
      topic: 'Marriage Intention ❤️',
      prompt: 'Why are you seeking marriage at this stage of your life?',
      description:
          'This tells the other person whether they are serious and what motivates them.',
    ),
    CompatibilityQuestion(
      questionIndex: 1,
      topic: 'Deen ☪️',
      prompt: 'What role do you want Islam to play in your future marriage and home?',
      description:
          'This is probably the most important question because it reveals their priorities and values.',
    ),
    CompatibilityQuestion(
      questionIndex: 2,
      topic: 'Spouse Expectations 🤝',
      prompt: 'What are the three most important qualities you are looking for in a spouse?',
      description:
          'This helps both people understand what each values most.',
    ),
    CompatibilityQuestion(
      questionIndex: 3,
      topic: 'Family 👨‍👩‍👧',
      prompt: 'How involved would you like your families to be after marriage?',
      description:
          'This is especially important in East African Muslim communities where family involvement can differ.',
    ),
    CompatibilityQuestion(
      questionIndex: 4,
      topic: 'Career & Lifestyle 💼',
      prompt:
          'How do you see balancing work, family, and personal responsibilities after marriage?',
      description:
          'This helps uncover expectations about work, roles, and daily life.',
    ),
    CompatibilityQuestion(
      questionIndex: 5,
      topic: 'Children 👶',
      prompt:
          'Do you hope to have children? If yes, what kind of Islamic values would you like to raise them with?',
      description:
          'This combines two important discussions into one question.',
    ),
    CompatibilityQuestion(
      questionIndex: 6,
      topic: 'Conflict Resolution 💬',
      prompt:
          'When disagreements arise, how do you believe a husband and wife should resolve them?',
      description:
          'A marriage is not about avoiding conflict, it is about handling it well. This question reveals maturity and communication style.',
    ),
    CompatibilityQuestion(
      questionIndex: 7,
      topic: 'Future Vision 🌍',
      prompt: 'Where do you hope to see yourself and your family in the next five years?',
      description:
          'This reveals long-term goals and whether both people are moving in a similar direction.',
    ),
  ];
}
