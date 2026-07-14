abstract final class DiskUsageSizeFormatter {
  static String format(int bytes) {
    if (bytes <= 0) {
      return '0 KB';
    }

    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;

    if (bytes < mb) {
      final value = bytes / kb;
      return '${_trim(value < 1 ? 1 : value)} KB';
    }

    if (bytes < gb) {
      return '${_trim(bytes / mb)} MB';
    }

    return '${_trim(bytes / gb)} GB';
  }

  static String _trim(double value) {
    final rounded = (value * 10).round() / 10;
    if (rounded == rounded.truncateToDouble()) {
      return rounded.toInt().toString();
    }

    return rounded.toStringAsFixed(1);
  }
}
