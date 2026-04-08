import '../models/body_scan.dart';

class BodyScanRepository {
  final List<BodyScan> _scans = [];

  void addScan(BodyScan scan) {
    _scans.add(scan);
  }

  BodyScan? getLatestScan() {
    if (_scans.isEmpty) return null;
    return _scans.last;
  }

  BodyScan? getPreviousScan() {
    if (_scans.length < 2) return null;
    return _scans[_scans.length - 2];
  }

  List<BodyScan> getAllScans() => List.unmodifiable(_scans);
}