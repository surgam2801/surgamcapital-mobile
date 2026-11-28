import 'package:flutter/material.dart';

class CalculatorToolOption {
  const CalculatorToolOption(this.id, this.title, this.description, this.icon);

  final String id;
  final String title;
  final String description;
  final IconData icon;
}

const goalCalculatorTools = [
  CalculatorToolOption(
    'retirement',
    'Retirement',
    'Estimate the corpus for your post-work years.',
    Icons.beach_access_rounded,
  ),
  CalculatorToolOption(
    'education',
    'Child education',
    'Plan for future education costs.',
    Icons.school_rounded,
  ),
  CalculatorToolOption(
    'home',
    'Home purchase',
    'Build a plan for your home goal.',
    Icons.home_work_rounded,
  ),
  CalculatorToolOption(
    'car',
    'Car purchase',
    'Estimate the future cost of a vehicle.',
    Icons.directions_car_rounded,
  ),
  CalculatorToolOption(
    'wedding',
    'Wedding',
    'Plan ahead for a meaningful milestone.',
    Icons.celebration_rounded,
  ),
  CalculatorToolOption(
    'travel',
    'Travel',
    'Turn a future trip into a savings target.',
    Icons.flight_takeoff_rounded,
  ),
  CalculatorToolOption(
    'emergency',
    'Emergency fund',
    'Set aside a buffer for unexpected needs.',
    Icons.health_and_safety_rounded,
  ),
  CalculatorToolOption(
    'custom',
    'Custom financial goal',
    'Create an estimate for any personal goal.',
    Icons.flag_rounded,
  ),
];

const investmentCalculatorTools = [
  CalculatorToolOption(
    'sip',
    'SIP calculator',
    'Project regular monthly investments.',
    Icons.autorenew_rounded,
  ),
  CalculatorToolOption(
    'step-up-sip',
    'Step-Up SIP',
    'See how annual increases change a SIP projection.',
    Icons.trending_up_rounded,
  ),
  CalculatorToolOption(
    'lumpsum',
    'Lumpsum calculator',
    'Estimate the growth of a one-time investment.',
    Icons.account_balance_wallet_rounded,
  ),
];
