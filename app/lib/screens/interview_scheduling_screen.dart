import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_client.dart';
import '../services/interview_service.dart';
import '../theme/app_theme.dart';
import 'booking_confirmation_screen.dart';

class InterviewSchedulingScreen extends StatefulWidget {
  final String jobId;
  final String? applicationId;
  const InterviewSchedulingScreen({
    super.key,
    required this.jobId,
    this.applicationId,
  });

  @override
  State<InterviewSchedulingScreen> createState() =>
      _InterviewSchedulingScreenState();
}

class _InterviewSchedulingScreenState
    extends State<InterviewSchedulingScreen> {
  late DateTime _visibleMonth;
  DateTime? _selectedDay;
  String _selectedTimeSlot = '2:00 pm - 2:30 pm';
  final _reasonController = TextEditingController();
  bool _submitting = false;

  static const _timeSlots = [
    '10:00 am - 10:30 am',
    '11:30 am - 12:00 pm',
    '2:00 pm - 2:30 pm',
    '3:30 pm - 4:00 pm',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day + 3);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth =
          DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  List<DateTime?> _buildCalendarGrid() {
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingEmpty = firstOfMonth.weekday % 7; // Sunday-first grid

    final cells = <DateTime?>[];
    for (int i = 0; i < leadingEmpty; i++) {
      cells.add(null);
    }
    for (int day = 1; day <= daysInMonth; day++) {
      cells.add(DateTime(_visibleMonth.year, _visibleMonth.month, day));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  Future<void> _handleConfirm() async {
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose an interview day')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await InterviewService.instance.scheduleInterview(
        jobId: widget.jobId,
        applicationId: widget.applicationId,
        date: _selectedDay!,
        timeSlot: _selectedTimeSlot,
        reason: _reasonController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(
            date: _selectedDay!,
            timeSlot: _selectedTimeSlot,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not schedule interview: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cells = _buildCalendarGrid();
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Interview Scheduling')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Please choose your interview day and time. We'll send you "
                "a confirmation once it's scheduled.",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => _changeMonth(-1),
                        ),
                        Text(
                          DateFormat('MMMM yyyy').format(_visibleMonth),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => _changeMonth(1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                          .map((d) => Expanded(
                                child: Center(
                                  child: Text(
                                    d,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const Divider(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cells.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final date = cells[index];
                        if (date == null) return const SizedBox.shrink();

                        final isSelected = _selectedDay != null &&
                            date.year == _selectedDay!.year &&
                            date.month == _selectedDay!.month &&
                            date.day == _selectedDay!.day;
                        final isPast = date
                            .isBefore(DateTime(today.year, today.month, today.day));

                        return GestureDetector(
                          onTap: isPast
                              ? null
                              : () => setState(() => _selectedDay = date),
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: AppColors.black, width: 1.6)
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w400,
                                  color: isPast
                                      ? AppColors.textHint
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_selectedDay != null)
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 20, color: AppColors.textPrimary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay!)}\n'
                        '$_selectedTimeSlot',
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeSlots.map((slot) {
                  final selected = slot == _selectedTimeSlot;
                  return ChoiceChip(
                    label: Text(slot),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedTimeSlot = slot),
                    selectedColor: AppColors.black,
                    backgroundColor: AppColors.surfaceGrey,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide.none,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Reason for rescheduling',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _reasonController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Type your reason (optional)',
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Interview FAQs',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'How should I prepare for an interview?',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              const Text(
                'What are the best resume tips?',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _submitting ? null : _handleConfirm,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
