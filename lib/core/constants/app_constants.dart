/// Constants used across the application.
///
/// Contains definitions for supported formats and groupings.
class AppConstants {
  AppConstants._();

  /// Supported destination format extensions for images.
  static const List<String> imageFormats = ['webp', 'png', 'jpg', 'avif', 'pdf'];

  /// Supported destination format extensions for videos (including audio extraction formats).
  static const List<String> videoFormats = ['mp4', 'webm', 'gif', 'mp3', 'wav', 'ogg'];

  /// Supported destination format extensions for audio.
  static const List<String> audioFormats = ['mp3', 'wav', 'ogg'];

  /// Grouping of supported format extensions by category.
  static const Map<String, List<String>> formatsByCategory = {
    'image': imageFormats,
    'video': videoFormats,
    'audio': audioFormats,
  };
}
