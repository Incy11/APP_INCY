import 'package:flutter/material.dart';
import 'package:flutter_quiz_app_2026/button.dart';

class StartScreen extends StatelessWidget {
  const StartScreen(this.startQuiz, {super.key});

  final void Function() startQuiz;

  @override
  Widget build(context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Image.asset(
          'assets/images/quiz-logo.png',
          width: 250,
          color: const Color.fromARGB(200, 255, 255, 255),
        ),
        const SizedBox(
          height: 50,
        ),
        const Text(
          'Learn Flutter the fun way!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        const SizedBox(
          height: 50,
        ),
        OutlinedButtonExample('Start Quiz',startQuiz, const Icon(Icons.arrow_right_alt)),
      ],
    );
  }
}
