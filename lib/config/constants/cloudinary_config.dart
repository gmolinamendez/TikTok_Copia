// Datos de Cloudinary (no son secretos: el preset "unsigned" solo permite subir archivos).
// Se sacan del Dashboard de Cloudinary y de Settings > Upload > Upload presets.
class CloudinaryConfig {
  static const String cloudName = 'goql6tew';
  static const String uploadPreset = 'toktik_usigned';

  static bool get isConfigured => !cloudName.startsWith('PON_AQUI') && !uploadPreset.startsWith('PON_AQUI');
}
