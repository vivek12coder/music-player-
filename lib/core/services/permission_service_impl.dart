import 'dart:io';

import 'package:permission_handler/permission_handler.dart' as ph;

import '../contracts/app_contracts.dart';
import '../models/app_models.dart';

class PermissionServiceImpl implements PermissionService {
  @override
  Future<PermissionAccess> checkLibraryPermission() async {
    return _bestStatusFromFutures(
      _candidatePermissions().map((permission) => permission.status),
    );
  }

  @override
  Future<bool> openSettings() => ph.openAppSettings();

  @override
  Future<PermissionAccess> requestLibraryPermission() async {
    final statuses = <ph.PermissionStatus>[];
    for (final permission in _candidatePermissions()) {
      statuses.add(await permission.request());
    }
    return _bestStatus(statuses);
  }

  List<ph.Permission> _candidatePermissions() {
    if (!Platform.isAndroid) {
      return [ph.Permission.audio];
    }
    return [ph.Permission.audio, ph.Permission.storage];
  }

  PermissionAccess _bestStatus(Iterable<ph.PermissionStatus> statuses) {
    if (statuses.any((status) => status.isGranted)) {
      return PermissionAccess.granted;
    }
    if (statuses.any((status) => status.isPermanentlyDenied || status.isRestricted)) {
      return PermissionAccess.permanentlyDenied;
    }
    if (statuses.any((status) => status.isDenied || status.isLimited)) {
      return PermissionAccess.denied;
    }
    return PermissionAccess.unknown;
  }

  Future<PermissionAccess> _bestStatusFromFutures(
    Iterable<Future<ph.PermissionStatus>> futures,
  ) async {
    final resolved = await Future.wait(futures);
    if (resolved.any((status) => status.isGranted)) {
      return PermissionAccess.granted;
    }
    if (resolved.any((status) => status.isPermanentlyDenied || status.isRestricted)) {
      return PermissionAccess.permanentlyDenied;
    }
    if (resolved.any((status) => status.isDenied || status.isLimited)) {
      return PermissionAccess.denied;
    }
    return PermissionAccess.unknown;
  }
}
