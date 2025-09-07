import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PhotoService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick image from camera
  static Future<String?> pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        return await _saveImageToAppDirectory(image);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image from camera: $e');
    }
  }

  /// Pick image from gallery
  static Future<String?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        return await _saveImageToAppDirectory(image);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  /// Save image to app's documents directory
  static Future<String> _saveImageToAppDirectory(XFile image) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = path.join(appDir.path, 'student_photos');

      // Create images directory if it doesn't exist
      final Directory imagesDirectory = Directory(imagesDir);
      if (!await imagesDirectory.exists()) {
        await imagesDirectory.create(recursive: true);
      }

      // Generate unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = path.extension(image.path);
      final String fileName = 'student_$timestamp$extension';
      final String filePath = path.join(imagesDir, fileName);

      // Copy image to app directory
      await File(image.path).copy(filePath);

      return filePath;
    } catch (e) {
      throw Exception('Failed to save image: $e');
    }
  }

  /// Delete image file
  static Future<void> deleteImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Check if image file exists
  static Future<bool> imageExists(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      return await imageFile.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get image file size
  static Future<int> getImageSize(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        return await imageFile.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Clean up unused images (orphaned photos)
  static Future<void> cleanupOrphanedImages(List<String> usedImagePaths) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = path.join(appDir.path, 'student_photos');
      final Directory imagesDirectory = Directory(imagesDir);

      if (!await imagesDirectory.exists()) {
        return;
      }

      final List<FileSystemEntity> files = imagesDirectory.listSync();
      final Set<String> usedPaths = usedImagePaths.toSet();

      for (final FileSystemEntity entity in files) {
        if (entity is File) {
          final String filePath = entity.path;
          if (!usedPaths.contains(filePath)) {
            // This image is not referenced by any student, delete it
            try {
              await entity.delete();
            } catch (e) {
              // Ignore deletion errors for cleanup
            }
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  /// Get all student photo paths from database
  static Future<List<String>> getAllStudentPhotoPaths() async {
    try {
      // This would need to be implemented to get all photo paths from students
      // For now, return empty list
      return [];
    } catch (e) {
      return [];
    }
  }
}