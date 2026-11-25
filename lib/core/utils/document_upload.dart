import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

const _types = {
  'pdf': 'application/pdf',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'doc': 'application/msword',
  'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'xls': 'application/vnd.ms-excel',
  'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
};

Future<List<PlatformFile>> pickDocuments() async {
  final selection = await FilePicker.pickFiles(
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: _types.keys.toList(),
  );
  final files = selection?.files ?? [];
  for (final file in files) {
    if (file.path == null || !_types.containsKey(file.extension?.toLowerCase()) ||
        file.size == 0 || file.size > 5 * 1024 * 1024) {
      throw const FormatException('Choose a supported, non-empty file up to 5 MB.');
    }
  }
  return files;
}

Future<MultipartFile> documentPart(PlatformFile file) => MultipartFile.fromFile(
  file.path!,
  filename: file.name,
  contentType: DioMediaType.parse(_types[file.extension!.toLowerCase()]!),
);
