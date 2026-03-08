import 'dart:math';

/// Represents a single BSL maths question.
///
/// Currently supports addition only, with operands 1-9
/// and answers 2-10 (matching available BSL number SVGs 1-10).
///
/// Example:
/// ```dart
/// final question = MathsQuestion(operand1: 3, operand2: 4, answer: 7);
/// print(question); // '3 + 4 = 7'
/// ```
class MathsQuestion {
  /// First operand (1-9)
  final int operand1;

  /// Second operand (1-9)
  final int operand2;

  /// The operator symbol (currently always '+')
  final String operatorSymbol;

  /// The correct answer
  final int answer;

  const MathsQuestion({
    required this.operand1,
    required this.operand2,
    this.operatorSymbol = '+',
    required this.answer,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MathsQuestion &&
          operand1 == other.operand1 &&
          operand2 == other.operand2;

  @override
  int get hashCode => operand1.hashCode ^ operand2.hashCode;

  @override
  String toString() => '$operand1 $operatorSymbol $operand2 = $answer';
}

/// Generates random maths questions for the BSL maths game.
///
/// Questions are generated based on the configured maximum answer value:
/// - Level 1: operands 1-9, sum 2-10
/// - Level 2: operands 1-10, sum 2-20 (operands capped at 10 for BSL assets)
class MathsQuestionGenerator {
  // Private constructor to prevent instantiation
  MathsQuestionGenerator._();

  /// Minimum operand value
  static const int minOperand = 1;

  /// Maximum operand value (BSL number assets only exist for 0-10)
  static const int maxAllowedOperand = 10;

  /// Generates a random addition question.
  ///
  /// Parameters:
  /// - [random]: The Random instance to use for generation
  /// - [maxAnswer]: Maximum allowed sum (10 for Level 1, 20 for Level 2)
  /// - [previousQuestion]: If provided, ensures the new question differs
  ///
  /// Returns a [MathsQuestion] where operand1 + operand2 <= [maxAnswer].
  /// Operands are capped at 10 to match available BSL number sign assets.
  static MathsQuestion generateAddition({
    required Random random,
    required int maxAnswer,
    MathsQuestion? previousQuestion,
  }) {
    // Cap operands at 10 (BSL number assets only exist for 0-10)
    final maxOperand =
        (maxAnswer - minOperand).clamp(minOperand, maxAllowedOperand);

    while (true) {
      // Pick first operand: 1 to maxOperand (max 10)
      final operand1 = random.nextInt(maxOperand) + minOperand;

      // Calculate maximum second operand to keep sum <= maxAnswer
      // Also cap at 10 since we only have BSL assets for 1-10
      final maxOperand2 =
          (maxAnswer - operand1).clamp(0, maxAllowedOperand);

      // Safety check
      if (maxOperand2 < minOperand) continue;

      // Pick second operand: 1 to maxOperand2 (max 10)
      final operand2 = random.nextInt(maxOperand2) + minOperand;

      final question = MathsQuestion(
        operand1: operand1,
        operand2: operand2,
        answer: operand1 + operand2,
      );

      // Ensure new question differs from the previous one
      if (question != previousQuestion) return question;
    }
  }
}
