import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:openexam_app/features/plan/data/plan_progress_store.dart';
import 'package:openexam_app/features/plan/data/plan_schedule.dart';
import 'package:openexam_app/features/plan/domain/models/daily_plan.dart';

class DailyPlanPage extends StatefulWidget {
  const DailyPlanPage({super.key});

  @override
  State<DailyPlanPage> createState() => _DailyPlanPageState();
}

class _DailyPlanPageState extends State<DailyPlanPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  PlanProgressStore? _progressStore;
  Map<String, Set<int>> _completedTasksByDate = <String, Set<int>>{};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _initializeProgress();
  }

  Future<void> _initializeProgress() async {
    final store = await PlanProgressStore.create();
    final allStates = store.loadAllTaskStates(PlanSchedule.plans);

    if (!mounted) {
      return;
    }

    setState(() {
      _progressStore = store;
      _completedTasksByDate = allStates;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final now = DateTime.now();
    final todayPlan = PlanSchedule.resolveTodayPlan(now);
    final upcoming = PlanSchedule.upcomingPlans(now, count: 4);
    final overallProgress = PlanSchedule.progress(now);
    final todayCompleted = _completedTasksByDate[todayPlan.dateKey] ?? <int>{};
    final dailyProgress = todayPlan.tasks.isEmpty
        ? 0.0
        : todayCompleted.length / todayPlan.tasks.length;
    final streakDays = _calculateStreak(now);
    final daysToExam = PlanSchedule.daysUntilExam(now);

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final offset = 30 * _glowController.value;

        return Stack(
          children: [
            Positioned(
              top: -120 + offset,
              right: -80,
              child: _GlowCircle(color: Colors.blue.withValues(alpha: 0.14)),
            ),
            Positioned(
              left: -90,
              bottom: -130 + offset,
              child: _GlowCircle(color: Colors.indigo.withValues(alpha: 0.12)),
            ),
            child!,
          ],
        );
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _TodayFocusCard(
                plan: todayPlan,
                overallProgress: overallProgress,
                dailyProgress: dailyProgress,
                completedTasks: todayCompleted.length,
                totalTasks: todayPlan.tasks.length,
                streakDays: streakDays,
                daysToExam: daysToExam,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                '今日任务清单',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: todayPlan.tasks.length,
            itemBuilder: (context, index) {
              final task = todayPlan.tasks[index];
              final checked = todayCompleted.contains(index);
              final delay = 120 * index;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 380 + delay),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _TaskCard(
                    index: index + 1,
                    task: task,
                    checked: checked,
                    onChanged: (value) => _toggleTask(todayPlan, index, value),
                  ),
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                '接下来 4 天',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemBuilder: (context, index) => _UpcomingPlanCard(
                  plan: upcoming[index],
                  isDone: _isPlanCompleted(upcoming[index]),
                ),
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemCount: upcoming.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTask(DailyPlan plan, int index, bool? checked) async {
    final store = _progressStore;
    if (store == null) {
      return;
    }

    final shouldCheck = checked ?? false;
    final currentSet = {...(_completedTasksByDate[plan.dateKey] ?? <int>{})};
    final wasCompleted = currentSet.length >= plan.tasks.length;

    if (shouldCheck) {
      currentSet.add(index);
    } else {
      currentSet.remove(index);
    }

    await store.saveCompletedTaskIndices(plan.dateKey, currentSet);

    if (!mounted) {
      return;
    }

    setState(() {
      _completedTasksByDate = {
        ..._completedTasksByDate,
        plan.dateKey: currentSet,
      };
    });

    final isCompletedNow = currentSet.length >= plan.tasks.length;
    if (!wasCompleted && isCompletedNow) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('今日任务已全部完成，继续保持🔥'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _isPlanCompleted(DailyPlan plan) {
    final completedCount = _completedTasksByDate[plan.dateKey]?.length ?? 0;
    return plan.tasks.isNotEmpty && completedCount >= plan.tasks.length;
  }

  int _calculateStreak(DateTime now) {
    var cursor = DateTime(now.year, now.month, now.day);
    final todayPlan = PlanSchedule.findPlanForDate(cursor);

    if (todayPlan != null && !_isPlanCompleted(todayPlan)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var streak = 0;
    while (true) {
      final plan = PlanSchedule.findPlanForDate(cursor);
      if (plan == null) {
        break;
      }

      if (_isPlanCompleted(plan)) {
        streak += 1;
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      break;
    }

    return streak;
  }
}

class _TodayFocusCard extends StatelessWidget {
  const _TodayFocusCard({
    required this.plan,
    required this.overallProgress,
    required this.dailyProgress,
    required this.completedTasks,
    required this.totalTasks,
    required this.streakDays,
    required this.daysToExam,
  });

  final DailyPlan plan;
  final double overallProgress;
  final double dailyProgress;
  final int completedTasks;
  final int totalTasks;
  final int streakDays;
  final int daysToExam;

  @override
  Widget build(BuildContext context) {
    final totalProgress = (overallProgress * 100)
        .clamp(0, 100)
        .toStringAsFixed(0);
    final dailyPercent = (dailyProgress * 100).clamp(0, 100).toStringAsFixed(0);
    final normalizedDaily = dailyProgress.clamp(0, 1).toDouble();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.primaryContainer],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                '今日冲分计划',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (plan.isSpringFestivalBoost)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '春节加强',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            plan.shortDateLabel,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            plan.target,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日完成：$completedTasks / $totalTasks',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: math.max(normalizedDaily, 0.0),
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '30天冲刺进度：$totalProgress%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: math.max(normalizedDaily, 0.02),
                      strokeWidth: 7,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                    Text(
                      '$dailyPercent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(icon: Icons.bolt_rounded, text: '连签 $streakDays 天'),
              const SizedBox(width: 8),
              _InfoChip(icon: Icons.event, text: '距考试 $daysToExam 天'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.index,
    required this.task,
    required this.checked,
    required this.onChanged,
  });

  final int index;
  final String task;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: checked
              ? primaryColor.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1.3,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: primaryColor.withValues(alpha: 0.14),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 12,
                color: primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Checkbox(value: checked, onChanged: onChanged),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: checked ? Colors.black54 : Colors.black87,
                decoration: checked ? TextDecoration.lineThrough : null,
              ),
              child: Text(task),
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: checked ? 1 : 0,
            child: Icon(Icons.check_circle_rounded, color: primaryColor),
          ),
        ],
      ),
    );
  }
}

class _UpcomingPlanCard extends StatelessWidget {
  const _UpcomingPlanCard({required this.plan, required this.isDone});

  final DailyPlan plan;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.shortDateLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (isDone)
                Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(plan.tasks.first, maxLines: 2, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text(
            plan.target,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
