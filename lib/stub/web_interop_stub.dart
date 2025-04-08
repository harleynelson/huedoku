// File: lib/stub/web_interop_stub.dart
// Provides a non-functional stub for non-web platforms
// to satisfy the compiler during conditional imports.

// Define a top-level 'window' object matching the structure used.
final window = _WebWindowStub();

// Define dummy classes matching the structure used (window.location.href)
class _WebWindowStub {
  // Provide a 'location' property that returns an instance of the location stub.
  final location = _LocationStub();
}

class _LocationStub {
  // Provide the 'href' setter that the main code tries to call.
  // On non-web platforms, it does nothing or logs a warning.
  set href(String _) {
    // Option 1: Do nothing silently
    // Option 2: Log a warning (useful for debugging)
    print('Warning: Attempted to set window.location.href on non-web platform.');
    // Option 3: Throw an error if this should never happen
    // throw UnimplementedError('window.location.href is web-only');
  }

  // If you were *reading* href, you'd add a getter:
  // String get href => throw UnimplementedError('href is web-only');
}

// Add dummy definitions for any other 'package:web' types or functions
// your code might reference via the 'web_interop' alias, if any.
// For just setting href, the above should be sufficient.