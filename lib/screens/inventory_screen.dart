import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_school_assistant/models.dart';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<String> _filterOptions = ['All', 'Educational', 'Furniture', 'Electronics', 'Other'];

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

  Future<void> _exportToExcel() async {
    try {
      final inventoryBox = Hive.box<InventoryItem>('inventory_items');
      final items = inventoryBox.values.toList();

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No items to export')),
        );
        return;
      }

      // Create Excel file
      final excelFile = excel.Excel.createExcel();
      final sheet = excelFile['Inventory'];

      // Add headers
      sheet.appendRow([
        excel.TextCellValue('Item Name'),
        excel.TextCellValue('Quantity'),
        excel.TextCellValue('Type'),
        excel.TextCellValue('Condition'),
        excel.TextCellValue('Description'),
        excel.TextCellValue('Date Added'),
      ]);

      // Add data
      for (final item in items) {
        sheet.appendRow([
          excel.TextCellValue(item.name),
          excel.TextCellValue(item.quantity.toString()),
          excel.TextCellValue(item.type),
          excel.TextCellValue(item.condition),
          excel.TextCellValue(item.description),
          excel.TextCellValue(item.dateAdded.toString()),
        ]);
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'inventory_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(excelFile.encode()!);

      // Share file
      await Share.shareXFiles([XFile(file.path)], text: 'Inventory Export');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to $fileName')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _importFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = File(result.files.first.path!);
      final bytes = await file.readAsBytes();
      final excelFile = excel.Excel.decodeBytes(bytes);

      if (excelFile.tables.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Excel file')),
        );
        return;
      }

      final sheet = excelFile.tables.values.first;
      final inventoryBox = Hive.box<InventoryItem>('inventory_items');

      int importedCount = 0;
      for (int i = 1; i < sheet.rows.length; i++) { // Skip header row
        final row = sheet.rows[i];
        if (row.length >= 6) {
          try {
            final item = InventoryItem(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i',
              name: row[0]?.value?.toString() ?? '',
              quantity: int.tryParse(row[1]?.value?.toString() ?? '0') ?? 0,
              type: row[2]?.value?.toString() ?? 'Other',
              condition: row[3]?.value?.toString() ?? 'Worked',
              description: row[4]?.value?.toString() ?? '',
              dateAdded: DateTime.tryParse(row[5]?.value?.toString() ?? '') ?? DateTime.now(),
            );

            if (item.name.isNotEmpty) {
              await inventoryBox.add(item);
              importedCount++;
            }
          } catch (e) {
            // Skip invalid rows
            continue;
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $importedCount items successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  Future<void> _showAddItemDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String selectedType = 'Educational';
    String selectedCondition = 'Worked';

    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Inventory Item'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Item Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter item name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter quantity';
                      }
                      final quantity = int.tryParse(value);
                      if (quantity == null || quantity < 0) {
                        return 'Please enter a valid quantity';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _filterOptions.skip(1).map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedType = value!;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCondition,
                    decoration: const InputDecoration(
                      labelText: 'Condition',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Worked', 'Not Worked'].map((condition) {
                      return DropdownMenuItem(
                        value: condition,
                        child: Text(condition),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedCondition = value!;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
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
                  final inventoryBox = Hive.box<InventoryItem>('inventory_items');
                  final newItem = InventoryItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    quantity: int.parse(quantityController.text.trim()),
                    type: selectedType,
                    condition: selectedCondition,
                    description: descriptionController.text.trim(),
                    dateAdded: DateTime.now(),
                  );
                  inventoryBox.add(newItem);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  List<InventoryItem> _getFilteredItems(List<InventoryItem> items) {
    return items.where((item) {
      final matchesFilter = _selectedFilter == 'All' || item.type == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery) ||
          item.description.toLowerCase().contains(_searchQuery);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  int _getTotalQuantity(List<InventoryItem> items) {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: _importFromExcel,
            tooltip: 'Import from Excel',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportToExcel,
            tooltip: 'Export to Excel',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Filter: ', style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: _filterOptions.map((filter) {
                            return DropdownMenuItem(
                              value: filter,
                              child: Text(filter),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedFilter = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<InventoryItem>('inventory_items').listenable(),
        builder: (context, Box<InventoryItem> box, _) {
          final allItems = box.values.toList();
          final filteredItems = _getFilteredItems(allItems);
          final totalQuantity = _getTotalQuantity(filteredItems);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Items: ${filteredItems.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total Quantity: $totalQuantity',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredItems.isEmpty
                    ? const Center(
                        child: Text('No items found. Tap + to add one.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getTypeColor(item.type),
                                child: Text(
                                  item.name[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Type: ${item.type} | Condition: ${item.condition}'),
                                  Text('Quantity: ${item.quantity}'),
                                  if (item.description.isNotEmpty)
                                    Text('Description: ${item.description}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      // TODO: Implement edit functionality
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
                                          title: const Text('Delete Item'),
                                          content: Text('Are you sure you want to delete "${item.name}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                item.delete();
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
                              ),
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
        onPressed: () => _showAddItemDialog(context),
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Educational':
        return Colors.blue;
      case 'Furniture':
        return Colors.green;
      case 'Electronics':
        return Colors.orange;
      case 'Other':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}