import 'dart:io';
import 'package:flutter/material.dart';
import '../models.dart';
import '../services/photo_service.dart';

class PhotoUploadScreen extends StatefulWidget {
  final Student student;

  const PhotoUploadScreen({super.key, required this.student});

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  bool _isLoading = false;
  String? _currentPhotoPath;

  @override
  void initState() {
    super.initState();
    _currentPhotoPath = widget.student.photoPath;
  }

  Future<void> _pickFromCamera() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String? imagePath = await PhotoService.pickFromCamera();
      if (imagePath != null) {
        await _updateStudentPhoto(imagePath);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo captured successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture photo: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String? imagePath = await PhotoService.pickFromGallery();
      if (imagePath != null) {
        await _updateStudentPhoto(imagePath);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo selected successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select photo: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStudentPhoto(String newPhotoPath) async {
    // Delete old photo if it exists
    if (_currentPhotoPath != null) {
      try {
        await PhotoService.deleteImage(_currentPhotoPath!);
      } catch (e) {
        // Ignore deletion errors
      }
    }

    // Update student record
    widget.student.photoPath = newPhotoPath;
    await widget.student.save();

    setState(() {
      _currentPhotoPath = newPhotoPath;
    });
  }

  Future<void> _removePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text('Are you sure you want to remove this student\'s photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (_currentPhotoPath != null) {
          await PhotoService.deleteImage(_currentPhotoPath!);
        }

        widget.student.photoPath = null;
        await widget.student.save();

        setState(() {
          _currentPhotoPath = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo removed successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove photo: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickFromGallery();
              },
            ),
            if (_currentPhotoPath != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop();
                  _removePhoto();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.fullName} - Photo'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Photo Display Area
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _currentPhotoPath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_currentPhotoPath!),
                                  fit: BoxFit.cover,
                                  width: 250,
                                  height: 250,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No photo uploaded',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showPhotoOptions,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(_currentPhotoPath != null ? 'Change Photo' : 'Add Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Student Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Student Information',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Name: ${widget.student.fullName}'),
                          Text('ID: ${widget.student.id}'),
                          Text('Gender: ${widget.student.gender}'),
                          if (_currentPhotoPath != null)
                            FutureBuilder<int>(
                              future: PhotoService.getImageSize(_currentPhotoPath!),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final sizeKB = (snapshot.data! / 1024).round();
                                  return Text('Photo Size: $sizeKB KB');
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tips
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Photo Tips',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• Use good lighting for clear photos\n'
                            '• Center the face in the frame\n'
                            '• Photos are automatically resized for optimal storage\n'
                            '• Supported formats: JPG, PNG',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}