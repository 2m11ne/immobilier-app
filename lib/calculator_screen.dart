import 'dart:math';
import 'package:flutter/material.dart';
import 'constants.dart';
import 'widgets.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  double price = 300000;
  double down = 20;
  double rate = 5;
  double years = 20;

  double get monthly {
    final loan = price * (1 - down / 100);
    final r = rate / 100 / 12;
    final n = years * 12;
    if (r == 0) return loan / n;
    return loan * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const PageHeader(title: 'Calculator', showBack: false),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: kTeal,
                child: Column(children: [
                  const Text('Monthly payment',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text('\$${monthly.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800)),
                ]),
              ),
              const SizedBox(height: 20),
              _slider('Property price', '\$${price.toInt()}', price, 50000,
                  1000000, (v) => setState(() => price = v)),
              _slider('Down payment', '${down.toInt()}%', down, 0, 50,
                  (v) => setState(() => down = v)),
              _slider('Interest rate', '${rate.toStringAsFixed(1)}%', rate, 1,
                  15, (v) => setState(() => rate = v)),
              _slider('Duration', '${years.toInt()} years', years, 5, 30,
                  (v) => setState(() => years = v)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slider(String label, String value, double v, double min, double max,
      ValueChanged<double> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      color: Colors.white,
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: kGrey)),
            Text(value,
                style: const TextStyle(
                    color: kNavy, fontWeight: FontWeight.w700)),
          ],
        ),
        Slider(
            value: v,
            min: min,
            max: max,
            activeColor: kTeal,
            onChanged: onChanged),
      ]),
    );
  }
}