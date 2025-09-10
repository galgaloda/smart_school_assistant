import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_school_assistant/models.dart';
import 'package:smart_school_assistant/services/backup_service.dart';

class DataRecordsScreen extends StatefulWidget {
  const DataRecordsScreen({super.key});

  @override
  State<DataRecordsScreen> createState() => _DataRecordsScreenState();
}

class _DataRecordsScreenState extends State<DataRecordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Policies',
    'Student Records',
    'Teacher Records',
    'Administrative',
    'Announcements',
    'Contacts',
    'Statistics'
  ];

  final List<String> _statuses = ['All', 'Active', 'Archived', 'Draft'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddRecordDialog(BuildContext context) async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    String selectedCategory = 'Policies';
    String selectedPriority = 'Medium';
    String selectedStatus = 'Active';

    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Data Record'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Record Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter record title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.skip(1).map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedCategory = value!;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Low', 'Medium', 'High', 'Critical'].map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(priority),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedPriority = value!;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: _statuses.skip(1).map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedStatus = value!;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter record content';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final recordsBox = Hive.box<DataRecord>('data_records');
                  final newRecord = DataRecord(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text.trim(),
                    category: selectedCategory,
                    content: contentController.text.trim(),
                    priority: selectedPriority,
                    status: selectedStatus,
                    dateCreated: DateTime.now(),
                    createdBy: 'Admin', // In a real app, this would be the current user
                  );
                  recordsBox.add(newRecord);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  List<DataRecord> _getFilteredRecords(List<DataRecord> records) {
    return records.where((record) {
      final matchesCategory = _selectedCategory == 'All' || record.category == _selectedCategory;
      final matchesStatus = _selectedStatus == 'All' || record.status == _selectedStatus;
      final matchesSearch = _searchQuery.isEmpty ||
          record.title.toLowerCase().contains(_searchQuery) ||
          record.content.toLowerCase().contains(_searchQuery) ||
          record.category.toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesStatus && matchesSearch;
    }).toList();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.yellow.shade700;
      case 'High':
        return Colors.orange;
      case 'Critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Archived':
        return Colors.grey;
      case 'Draft':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFilterDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(color: Colors.white, fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createBackup(BuildContext context) async {
    try {
      await BackupService.saveBackupToFile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data Records backup created and shared successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Data Records Backup'),
        content: const Text(
          'This will replace all current data records with the backup data. '
          'This action cannot be undone. Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final results = await BackupService.importFromFile();
      if (results != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data Records restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No backup file selected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to restore backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Records Management'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: () => _createBackup(context),
            tooltip: 'Backup Data Records',
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () => _restoreBackup(context),
            tooltip: 'Restore Data Records',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(160),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 400;
                return Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search records...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 8 : 12,
                        ),
                      ),
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                    ),
                    const SizedBox(height: 8),
                    isSmallScreen
                        ? Column(
                            children: [
                              _buildFilterDropdown('Category', _selectedCategory, _categories, (value) {
                                setState(() => _selectedCategory = value!);
                              }),
                              const SizedBox(height: 8),
                              _buildFilterDropdown('Status', _selectedStatus, _statuses, (value) {
                                setState(() => _selectedStatus = value!);
                              }),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _buildFilterDropdown('Category', _selectedCategory, _categories, (value) {
                                  setState(() => _selectedCategory = value!);
                                }),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildFilterDropdown('Status', _selectedStatus, _statuses, (value) {
                                  setState(() => _selectedStatus = value!);
                                }),
                              ),
                            ],
                          ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<DataRecord>('data_records').listenable(),
        builder: (context, Box<DataRecord> box, _) {
          final allRecords = box.values.toList();
          final filteredRecords = _getFilteredRecords(allRecords);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 400;
                    return isSmallScreen
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Records: ${filteredRecords.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Categories: ${_categories.length - 1}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Records: ${filteredRecords.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Categories: ${_categories.length - 1}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                  },
                ),
              ),
              Expanded(
                child: filteredRecords.isEmpty
                    ? const Center(
                        child: Text('No records found. Tap + to add one.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getPriorityColor(record.priority),
                                child: Text(
                                  record.category[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                record.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Category: ${record.category}'),
                                  Text('Priority: ${record.priority}'),
                                  Text('Status: ${record.status}'),
                                  Text(
                                    'Created: ${record.dateCreated.toString().split(' ')[0]}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (record.content.length > 50)
                                    Text(
                                      '${record.content.substring(0, 50)}...',
                                      style: const TextStyle(fontSize: 12),
                                    )
                                  else
                                    Text(
                                      record.content,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isSmallScreen = constraints.maxWidth < 400;
                                  return isSmallScreen
                                      ? PopupMenuButton<String>(
                                          onSelected: (value) {
                                            switch (value) {
                                              case 'edit':
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Edit functionality - Coming Soon')),
                                                );
                                                break;
                                              case 'delete':
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Delete Record'),
                                                    content: Text('Are you sure you want to delete "${record.title}"?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(),
                                                        child: const Text('Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          record.delete();
                                                          Navigator.of(context).pop();
                                                        },
                                                        child: const Text('Delete'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                break;
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, color: Colors.blue, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Edit'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete, color: Colors.red, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Delete'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(record.status),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                record.status,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue),
                                              onPressed: () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Edit functionality - Coming Soon')),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Delete Record'),
                                                    content: Text('Are you sure you want to delete "${record.title}"?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(),
                                                        child: const Text('Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          record.delete();
                                                          Navigator.of(context).pop();
                                                        },
                                                        child: const Text('Delete'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        );
                                },
                              ),
                              onTap: () {
                                // Show full record details
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(record.title),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Category: ${record.category}'),
                                          Text('Priority: ${record.priority}'),
                                          Text('Status: ${record.status}'),
                                          Text('Created: ${record.dateCreated}'),
                                          const SizedBox(height: 16),
                                          const Text('Content:', style: TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 8),
                                          Text(record.content),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordDialog(context),
        tooltip: 'Add Record',
        child: const Icon(Icons.add),
      ),
    );
  }
}