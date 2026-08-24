import 'package:flutter/material.dart';

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String message;
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.message,
  });
}

const _pages = [
  _OnboardingPage(
    icon: Icons.electrical_services,
    title: 'Build Your Load Profile',
    message:
        'Add the appliances and equipment you want to power, and see your daily and monthly energy requirement.',
  ),
  _OnboardingPage(
    icon: Icons.wb_sunny,
    title: 'Size Your Solar System',
    message:
        'Estimate solar array, battery storage and inverter capacity from your actual load profile.',
  ),
  _OnboardingPage(
    icon: Icons.compare_arrows,
    title: 'Compare Designs',
    message:
        'Explore What-If scenarios and compare different system configurations side by side.',
  ),
  _OnboardingPage(
    icon: Icons.description_outlined,
    title: 'Create a Planning Report',
    message:
        'Save your project and generate a shareable planning report — entirely offline.',
  ),
];

/// Short, domain-specific first-launch onboarding (max 4 screens). Never
/// forces account creation and is not repeated after first completion —
/// it can be reopened later from Settings/Help.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onFinished,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          child: Icon(
                            page.icon,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_index == _pages.length - 1) {
                      widget.onFinished();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(
                    _index == _pages.length - 1 ? 'Get Started' : 'Next',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
