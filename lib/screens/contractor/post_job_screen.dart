import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'contractor_theme.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key, this.jobId, this.initialData});

  final String? jobId;
  final Map<String, dynamic>? initialData;

  bool get isEditing => jobId != null;

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _category = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  final _wage = TextEditingController();
  final _workers = TextEditingController(text: '1');
  final _contactPhone = TextEditingController();

  final Set<String> _preferredGenders = {'Male', 'Female'};
  final Set<DateTime> _workDates = {};

  String _jobType = 'Daily wage';
  String _wageType = 'Daily';
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _contactPhone.text = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';

    final data = widget.initialData;
    if (data == null) return;

    _title.text = data['title']?.toString() ?? '';
    _category.text = data['category']?.toString() ?? '';
    _location.text = data['location']?.toString() ?? '';
    _description.text = data['description']?.toString() ?? '';
    _wage.text = data['wageAmount']?.toString() ?? '';
    _workers.text = data['workersNeeded']?.toString() ?? '1';

    _contactPhone.text = data['contactPhone']?.toString() ?? _contactPhone.text;

    final savedGenders = data['preferredGender'];

    if (savedGenders is List) {
      _preferredGenders
        ..clear()
        ..addAll(
          savedGenders
              .map((e) => e.toString())
              .where((e) => ['Male', 'Female'].contains(e)),
        );
    } else if (savedGenders is String) {
      _preferredGenders
        ..clear()
        ..addAll(
          savedGenders == 'Both'
              ? ['Male', 'Female']
              : ['Male', 'Female'].where((e) => e == savedGenders),
        );
    }

    final type = data['jobType']?.toString();
    if (['Daily wage', 'Full-time', 'Part-time'].contains(type)) {
      _jobType = type!;
    }

    _wageType =
        data['wageType']?.toString() ??
        (_jobType == 'Daily wage' ? 'Daily' : 'Monthly');

    final savedDates = data['workDates'];
    if (savedDates is List) {
      for (final item in savedDates) {
        DateTime? date;

        if (item is Timestamp) {
          date = item.toDate();
        } else if (item is DateTime) {
          date = item;
        } else if (item is String) {
          date = DateTime.tryParse(item);
        }

        if (date != null) {
          _workDates.add(DateUtils.dateOnly(date));
        }
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _location.dispose();
    _description.dispose();
    _wage.dispose();
    _workers.dispose();
    _contactPhone.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter $label';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_preferredGenders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select Male, Female, or both.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in again.')));
      return;
    }

    setState(() => _saving = true);

    try {
      final jobData = <String, dynamic>{
        'title': _title.text.trim(),
        'category': _category.text.trim(),
        'location': _location.text.trim(),
        'description': _description.text.trim(),
        'wageAmount': num.parse(_wage.text.trim()),
        'wageType': _wageType,
        'jobType': _jobType,
        'workersNeeded': int.parse(_workers.text.trim()),
        'contractorId': user.uid,
        'workDates': _workDates.toList()..sort(),
        'preferredGender': _preferredGenders.toList()..sort(),
        'contactPhone': _contactPhone.text.trim(),
      };

      final jobs = FirebaseFirestore.instance.collection('jobs');

      if (widget.isEditing) {
        await jobs.doc(widget.jobId).update(jobData);
      } else {
        await jobs.add({
          ...jobData,
          'status': 'open',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Job updated successfully!'
                : 'Job posted successfully!',
          ),
        ),
      );

      Navigator.of(context).pop();
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save job: ${e.message ?? e.code}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _genderOption(String gender, IconData icon) {
    final selected = _preferredGenders.contains(gender);

    return Expanded(
      child: InkWell(
        onTap: _saving
            ? null
            : () {
                setState(() {
                  if (selected) {
                    _preferredGenders.remove(gender);
                  } else {
                    _preferredGenders.add(gender);
                  }
                });
              },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? contractorGreen : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? contractorGreen : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.white : contractorDarkGreen),
              const SizedBox(width: 6),
              Text(
                gender,
                style: TextStyle(
                  color: selected ? Colors.white : contractorDarkGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (selected)
                const Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectWorkDates() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final initialMonth = DateTime(today.year, today.month);

    final selected = await showDialog<Set<DateTime>>(
      context: context,
      builder: (dialogContext) {
        var month = initialMonth;
        final temporaryDates = Set<DateTime>.from(_workDates);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final firstDay = DateTime(month.year, month.month, 1);
            final leadingBlanks = firstDay.weekday - 1;
            final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
            final cellCount = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;

            return AlertDialog(
              title: const Text('Select work dates'),
              content: SizedBox(
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setDialogState(() {
                              month = DateTime(month.year, month.month - 1);
                            });
                          },
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text(
                            '${_monthName(month.month)} ${month.year}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setDialogState(() {
                              month = DateTime(month.year, month.month + 1);
                            });
                          },
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    Row(
                      children:
                          const [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun',
                          ].map((day) {
                            return Expanded(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    day,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cellCount,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                          ),
                      itemBuilder: (context, index) {
                        final dayNumber = index - leadingBlanks + 1;

                        if (dayNumber < 1 || dayNumber > daysInMonth) {
                          return const SizedBox.shrink();
                        }

                        final date = DateTime(
                          month.year,
                          month.month,
                          dayNumber,
                        );

                        final isSelected = temporaryDates.contains(date);
                        final isPast = date.isBefore(today);

                        return InkWell(
                          onTap: isPast
                              ? null
                              : () {
                                  setDialogState(() {
                                    if (isSelected) {
                                      temporaryDates.remove(date);
                                    } else {
                                      temporaryDates.add(date);
                                    }
                                  });
                                },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? contractorGreen
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: date == today
                                  ? Border.all(color: contractorGreen)
                                  : null,
                            ),
                            child: Text(
                              '$dayNumber',
                              style: TextStyle(
                                color: isPast
                                    ? Colors.grey.shade400
                                    : isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${temporaryDates.length} date(s) selected',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setDialogState(() => temporaryDates.clear());
                  },
                  child: const Text('Clear all'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      Set<DateTime>.from(temporaryDates),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: contractorGreen,
                  ),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _workDates
          ..clear()
          ..addAll(selected);
      });
    }
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  InputDecoration _decoration(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: contractorGreen),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: contractorGreen, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: contractorBackground,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Job' : 'Post a Job',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: contractorDarkGreen,
          ),
        ),
        backgroundColor: contractorBackground,
        foregroundColor: contractorDarkGreen,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Job details',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: contractorDarkGreen,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Provide clear details so workers know what the job requires.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _title,
              decoration: _decoration(
                'Job title',
                hint: 'e.g. Construction Helper',
              ),
              validator: (v) => _required(v, 'a job title'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _category,
              decoration: _decoration(
                'Work category',
                hint: 'e.g. Mason, Painter, Helper',
              ),
              validator: (v) => _required(v, 'a category'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _location,
              decoration: _decoration(
                'Work location',
                hint: 'City, area or site address',
                icon: Icons.location_on_outlined,
              ),
              validator: (v) => _required(v, 'a location'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _jobType,
              decoration: _decoration('Job type'),
              items: const [
                DropdownMenuItem(
                  value: 'Daily wage',
                  child: Text('Daily wage'),
                ),
                DropdownMenuItem(value: 'Full-time', child: Text('Full-time')),
                DropdownMenuItem(value: 'Part-time', child: Text('Part-time')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _jobType = v;
                    _wageType = v == 'Daily wage' ? 'Daily' : 'Monthly';
                  });
                }
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              decoration: _decoration(
                'Job description',
                hint: 'Work responsibilities, timings, requirements',
              ),
              validator: (v) => _required(v, 'a job description'),
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _wage,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _decoration(
                      _wageType == 'Daily' ? 'Wage (₹/day)' : 'Wage (₹/month)',
                    ),
                    validator: (v) {
                      final value = num.tryParse(v?.trim() ?? '');
                      if (value == null || value <= 0) {
                        return 'Enter valid wage';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _workers,
                    keyboardType: TextInputType.number,
                    decoration: _decoration('Workers needed'),
                    validator: (v) {
                      final value = int.tryParse(v?.trim() ?? '');
                      if (value == null || value < 1) {
                        return 'Enter 1 or more';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Gender selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: contractorGreen.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.people_alt_outlined, color: contractorGreen),
                      SizedBox(width: 8),
                      Text(
                        'Workers preferred',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: contractorDarkGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Select Male, Female, or both.',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _genderOption('Male', Icons.male),
                      const SizedBox(width: 10),
                      _genderOption('Female', Icons.female),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Contractor contact number
            TextFormField(
              controller: _contactPhone,
              keyboardType: TextInputType.phone,
              decoration: _decoration(
                'Contact phone number',
                hint: 'Number workers can call',
                icon: Icons.call_outlined,
              ),
              validator: (value) {
                final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                if (digits.length < 10 || digits.length > 13) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 6),
            const Text(
              'Workers can use this number to contact you about the job.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 18),

            // Work dates calendar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: contractorGreen.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_month, color: contractorGreen),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Work required dates',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: contractorDarkGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose any dates when you need workers. '
                    'You can select consecutive or separate dates.',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _selectWorkDates,
                    icon: const Icon(Icons.edit_calendar),
                    label: Text(
                      _workDates.isEmpty
                          ? 'Select work dates'
                          : 'Change selected dates',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: contractorGreen,
                      side: const BorderSide(color: contractorGreen),
                      minimumSize: const Size(double.infinity, 46),
                    ),
                  ),
                  if (_workDates.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_workDates.toList()..sort()).map((date) {
                        return Chip(
                          avatar: const Icon(
                            Icons.event_available,
                            size: 17,
                            color: contractorGreen,
                          ),
                          label: Text(_formatDate(date)),
                          onDeleted: _saving
                              ? null
                              : () {
                                  setState(() => _workDates.remove(date));
                                },
                          deleteIconColor: contractorGreen,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: contractorGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.isEditing ? 'Save Changes' : 'Publish Job',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
