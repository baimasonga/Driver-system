import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class EvidenceUploadService {
  static final _client = Supabase.instance.client;
  static const _uuid = Uuid();

  static Future<String?> pickAndUpload({
    required String organizationId,
    required String category,
    bool allowPdf = false,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowPdf
          ? const ['jpg', 'jpeg', 'png', 'webp', 'pdf']
          : const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null) return null;
    final file = result.files.single;
    if (file.bytes == null) throw StateError('The selected file could not be read.');
    if (file.size > 10 * 1024 * 1024) throw StateError('Evidence files cannot exceed 10 MB.');
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Sign in before uploading evidence.');
    final extension = (file.extension ?? 'jpg').toLowerCase();
    final path = '$organizationId/${user.id}/$category/${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-')}-${_uuid.v4()}.$extension';
    await _client.storage.from('fleet-evidence').uploadBinary(
      path,
      file.bytes!,
      fileOptions: FileOptions(contentType: _contentType(extension), upsert: false),
    );
    return path;
  }

  static String _contentType(String extension) {
    if (extension == 'pdf') return 'application/pdf';
    if (extension == 'png') return 'image/png';
    if (extension == 'webp') return 'image/webp';
    return 'image/jpeg';
  }
}
