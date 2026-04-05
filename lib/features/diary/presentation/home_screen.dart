import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/meal.dart';
import '../../../providers/diary_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/health_provider.dart';
import 'meal_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback onAddMeal;

  const HomeScreen({super.key, required this.onAddMeal});

  // Goal is now fetched from userProvider

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final today = ref.watch(diaryProvider);
    final healthState = ref.watch(healthProvider);
    final burned = healthState.isSynced ? healthState.burnedCalories : 0.0;
    
    final goal = user.dailyCalorieGoal + burned;
    final percent =
        (today.totalCalories / goal).clamp(0.0, 1.0).toDouble();

    final date = today.date;
    final formattedDate =
        '${_weekdayLabel(date.weekday)}, ${date.day} ${_monthLabel(date.month)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cal AI Nutrition Tracker'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // later: refresh from backend
          await Future<void>.delayed(const Duration(milliseconds: 400));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderDateChip(dateText: formattedDate),
              const SizedBox(height: 16),
              _SummaryCard(
                totalCalories: today.totalCalories,
                percent: percent,
                protein: today.totalProtein,
                carbs: today.totalCarbs,
                fats: today.totalFats,
              ),
              const SizedBox(height: 24),
              const Text(
                'Today\'s meals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _MealSection(
                mealName: 'Breakfast',
                icon: Icons.wb_sunny_outlined,
                color: Colors.orange,
                meals: today.meals
                    .where((m) => m.type == MealType.breakfast)
                    .toList(),
              ),
              _MealSection(
                mealName: 'Lunch',
                icon: Icons.lunch_dining,
                color: Colors.blue,
                meals:
                    today.meals.where((m) => m.type == MealType.lunch).toList(),
              ),
              _MealSection(
                mealName: 'Dinner',
                icon: Icons.nightlight_round,
                color: Colors.indigo,
                meals: today.meals
                    .where((m) => m.type == MealType.dinner)
                    .toList(),
              ),
              _MealSection(
                mealName: 'Snacks',
                icon: Icons.cookie_outlined,
                color: Colors.pink,
                meals:
                    today.meals.where((m) => m.type == MealType.snack).toList(),
              ),
              const SizedBox(height: 80), // space above FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAddMeal,
        icon: const Icon(Icons.add),
        label: const Text('Add meal'),
      ),
    );
  }

  static String _weekdayLabel(int weekday) {
    const labels = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    return labels[(weekday - 1).clamp(0, 6)];
  }

  static String _monthLabel(int month) {
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return labels[(month - 1).clamp(0, 11)];
  }
}

class _HeaderDateChip extends ConsumerWidget {
  final String dateText;

  const _HeaderDateChip({required this.dateText});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            ref.read(selectedDateProvider.notifier).update((state) => state.subtract(const Duration(days: 1)));
          },
        ),
        const Icon(Icons.today, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            dateText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            ref.read(selectedDateProvider.notifier).update((state) => state.add(const Duration(days: 1)));
          },
        ),
      ],
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  final double totalCalories;
  final double percent;
  final double protein;
  final double carbs;
  final double fats;

  const _SummaryCard({
    required this.totalCalories,
    required this.percent,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthProvider);
    final burned = healthState.isSynced ? healthState.burnedCalories : 0.0;
    final baseGoal = ref.watch(userProvider).dailyCalorieGoal;
    final goal = baseGoal + burned;
    final remaining = (goal - totalCalories).clamp(0.0, goal);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            _CalorieRing(
              percent: percent,
              totalCalories: totalCalories,
              goalCalories: goal,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${totalCalories.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} kcal',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Remaining: ${remaining.toStringAsFixed(0)} kcal',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (burned > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '+${burned.toStringAsFixed(0)} kcal burned',
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Wrap avoids horizontal overflow on narrow screens (Row + Chips was ~98px too wide).
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.start,
                    children: [
                      _MacroPill(
                        label: 'Protein',
                        value: '${protein.toStringAsFixed(0)} g',
                        color: Colors.blue,
                      ),
                      _MacroPill(
                        label: 'Carbs',
                        value: '${carbs.toStringAsFixed(0)} g',
                        color: Colors.orange,
                      ),
                      _MacroPill(
                        label: 'Fats',
                        value: '${fats.toStringAsFixed(0)} g',
                        color: Colors.pink,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalorieRing extends StatelessWidget {
  final double percent;
  final double totalCalories;
  final double goalCalories;

  const _CalorieRing({
    required this.percent,
    required this.totalCalories,
    required this.goalCalories,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: percent,
            strokeWidth: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          Center(
            child: Text(
              '${(percent * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: color.withValues(alpha: 0.08),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              color: color.darken(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  final String mealName;
  final IconData icon;
  final Color color;
  final List<Meal> meals;

  const _MealSection({
    required this.mealName,
    required this.icon,
    required this.color,
    required this.meals,
  });

  @override
  Widget build(BuildContext context) {
    final totalKcal = meals.fold<double>(
      0,
      (sum, m) => sum + m.totalCalories,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          mealName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          meals.isEmpty
              ? 'No items logged yet'
              : '${meals.length} meal(s) • ${totalKcal.toStringAsFixed(0)} kcal',
          style: const TextStyle(fontSize: 12),
        ),
        children: meals.map((meal) {
          final time =
              '${meal.timestamp.hour.toString().padLeft(2, '0')}:${meal.timestamp.minute.toString().padLeft(2, '0')}';
          return ListTile(
            title: Text(
              '${meal.totalCalories.toStringAsFixed(0)} kcal',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${meal.items.length} item(s) • $time',
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MealDetailScreen(meal: meal),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

extension _ColorDarken on Color {
  Color darken([double amount = .2]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark =
        hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}