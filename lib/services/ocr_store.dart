// Simple singleton to hold the last OCR result across page navigation.
class OcrStore {
  OcrStore._();
  static final OcrStore instance = OcrStore._();

  Map<String, dynamic>? data;
  // Saved editor state (the _componentsJson from the results page). Kept so that
  // navigating away and back to Plan Result shows the user's edits, not raw OCR.
  Map<String, dynamic>? editedComponents;

  void save(Map<String, dynamic> d) {
    data = d;
    editedComponents = null; // fresh OCR → drop any previous edits
  }

  void clear() {
    data = null;
    editedComponents = null;
  }

  bool get hasData => data != null;
}
