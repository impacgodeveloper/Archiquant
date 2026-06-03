// Simple singleton to hold the last OCR result across page navigation.
class OcrStore {
  OcrStore._();
  static final OcrStore instance = OcrStore._();

  Map<String, dynamic>? data;

  void save(Map<String, dynamic> d) => data = d;
  void clear() => data = null;
  bool get hasData => data != null;
}
