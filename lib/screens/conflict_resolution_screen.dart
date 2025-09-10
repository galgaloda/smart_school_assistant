import 'package:flutter/material.dart';
import '../services/sync_service.dart';

class ConflictResolutionScreen extends StatefulWidget {
  final List<String> conflicts;
  final Function(String, ConflictStrategy) onResolve;

  const ConflictResolutionScreen({
    super.key,
    required this.conflicts,
    required this.onResolve,
  });

  @override
  State<ConflictResolutionScreen> createState() => _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState extends State<ConflictResolutionScreen> {
  final Map<String, ConflictStrategy> _resolutions = {};

  @override
  void initState() {
    super.initState();
    // Initialize with recommended strategies
    for (final conflict in widget.conflicts) {
      final collectionName = _extractCollectionName(conflict);
      _resolutions[conflict] = ConflictResolver.getRecommendedStrategy(collectionName);
    }
  }

  String _extractCollectionName(String conflict) {
    // Extract collection name from conflict string (e.g., "students:123" -> "students")
    final parts = conflict.split(':');
    return parts.isNotEmpty ? parts[0] : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolve Sync Conflicts'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _resolveAllConflicts,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: const Text('Resolve All'),
          ),
        ],
      ),
      body: widget.conflicts.isEmpty
          ? const Center(
              child: Text('No conflicts to resolve'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: widget.conflicts.length,
              itemBuilder: (context, index) {
                final conflict = widget.conflicts[index];
                final collectionName = _extractCollectionName(conflict);
                final currentStrategy = _resolutions[conflict] ?? ConflictStrategy.merge;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getConflictIcon(collectionName),
                              color: Colors.orange,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _formatConflictTitle(conflict),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getConflictDescription(collectionName),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Resolution Strategy:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<ConflictStrategy>(
                          value: currentStrategy,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: ConflictStrategy.values.map((strategy) {
                            return DropdownMenuItem(
                              value: strategy,
                              child: Text(_formatStrategyName(strategy)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _resolutions[conflict] = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getStrategyColor(currentStrategy).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getStrategyDescription(currentStrategy),
                            style: TextStyle(
                              color: _getStrategyColor(currentStrategy),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _resolveAllConflicts() {
    for (final conflict in widget.conflicts) {
      final strategy = _resolutions[conflict] ?? ConflictStrategy.merge;
      widget.onResolve(conflict, strategy);
    }
    Navigator.of(context).pop();
  }

  IconData _getConflictIcon(String collectionName) {
    switch (collectionName) {
      case 'students':
        return Icons.person;
      case 'teachers':
        return Icons.school;
      case 'subjects':
        return Icons.book;
      case 'class_sections':
        return Icons.class_;
      case 'timetable_entries':
        return Icons.schedule;
      case 'attendance_records':
        return Icons.check_circle;
      case 'scores':
        return Icons.grade;
      case 'assessments':
        return Icons.assignment;
      case 'semesters':
        return Icons.calendar_month;
      case 'inventory_items':
        return Icons.inventory;
      case 'data_records':
        return Icons.folder;
      default:
        return Icons.warning;
    }
  }

  String _formatConflictTitle(String conflict) {
    final parts = conflict.split(':');
    if (parts.length >= 2) {
      final collectionName = _humanizeCollectionName(parts[0]);
      final itemId = parts[1];
      return '$collectionName Conflict (ID: $itemId)';
    }
    return 'Data Conflict';
  }

  String _humanizeCollectionName(String collectionName) {
    switch (collectionName) {
      case 'students':
        return 'Student';
      case 'teachers':
        return 'Teacher';
      case 'subjects':
        return 'Subject';
      case 'class_sections':
        return 'Class';
      case 'timetable_entries':
        return 'Timetable Entry';
      case 'attendance_records':
        return 'Attendance Record';
      case 'scores':
        return 'Score';
      case 'assessments':
        return 'Assessment';
      case 'semesters':
        return 'Semester';
      case 'inventory_items':
        return 'Inventory Item';
      case 'data_records':
        return 'Data Record';
      default:
        return collectionName.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _getConflictDescription(String collectionName) {
    switch (collectionName) {
      case 'students':
        return 'This student record has been modified both locally and in the cloud. Choose how to resolve the conflict.';
      case 'teachers':
        return 'This teacher record has been modified both locally and in the cloud. Choose how to resolve the conflict.';
      case 'attendance_records':
        return 'This attendance record has been modified both locally and in the cloud. Choose how to resolve the conflict.';
      case 'scores':
        return 'This score record has been modified both locally and in the cloud. Choose how to resolve the conflict.';
      default:
        return 'This record has been modified both locally and in the cloud. Choose how to resolve the conflict.';
    }
  }

  String _formatStrategyName(ConflictStrategy strategy) {
    switch (strategy) {
      case ConflictStrategy.localWins:
        return 'Keep Local Changes';
      case ConflictStrategy.cloudWins:
        return 'Keep Cloud Changes';
      case ConflictStrategy.merge:
        return 'Merge Changes';
      case ConflictStrategy.askUser:
        return 'Ask User (Not Available)';
    }
  }

  String _getStrategyDescription(ConflictStrategy strategy) {
    switch (strategy) {
      case ConflictStrategy.localWins:
        return 'Your local changes will be kept, cloud changes will be discarded.';
      case ConflictStrategy.cloudWins:
        return 'Cloud changes will be kept, your local changes will be discarded.';
      case ConflictStrategy.merge:
        return 'Both local and cloud changes will be combined intelligently.';
      case ConflictStrategy.askUser:
        return 'User will be prompted to choose (currently defaults to merge).';
    }
  }

  Color _getStrategyColor(ConflictStrategy strategy) {
    switch (strategy) {
      case ConflictStrategy.localWins:
        return Colors.blue;
      case ConflictStrategy.cloudWins:
        return Colors.green;
      case ConflictStrategy.merge:
        return Colors.purple;
      case ConflictStrategy.askUser:
        return Colors.orange;
    }
  }
}