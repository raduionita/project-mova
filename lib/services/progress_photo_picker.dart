import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Picks a progress photo from the camera or library.
abstract class ProgressPhotoPicker {
  const ProgressPhotoPicker();

  Future<Uint8List?> pick(ImageSource source);
}

/// Device picker that compresses images into small local thumbnails.
class DeviceProgressPhotoPicker implements ProgressPhotoPicker {
  const DeviceProgressPhotoPicker([this._picker]);

  final ImagePicker? _picker;

  @override
  Future<Uint8List?> pick(ImageSource source) async {
    final file = await (_picker ?? ImagePicker()).pickImage(
      source: source,
      maxWidth: 720,
      maxHeight: 720,
      imageQuality: 70,
    );
    if (file == null) {
      return null;
    }
    return file.readAsBytes();
  }
}
