import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/share_content.dart';
import '../models/share_platform.dart';
import '../services/app_availability_service.dart';
import '../services/social_share_service.dart';

class ShareController extends ChangeNotifier {
  ShareController({
    AppAvailabilityService? availabilityService,
    SocialShareService? shareService,
    ImagePicker? imagePicker,
  })  : _availabilityService =
            availabilityService ?? AppAvailabilityService(),
        _shareService = shareService ?? SocialShareService(),
        _imagePicker = imagePicker ?? ImagePicker();

  final AppAvailabilityService _availabilityService;
  final SocialShareService _shareService;
  final ImagePicker _imagePicker;

  final Set<SharePlatform> selectedPlatforms = {};
  final List<ShareResult> lastResults = [];

  List<SharePlatform> availablePlatforms = [];
  XFile? image;
  bool isLoadingApps = true;
  bool isSharing = false;

  Future<void> loadInstalledApps() async {
    isLoadingApps = true;
    notifyListeners();

    availablePlatforms = await _availabilityService.installedPlatforms();
    selectedPlatforms
      ..removeWhere((platform) => !availablePlatforms.contains(platform))
      ..addAll(availablePlatforms.take(1));

    isLoadingApps = false;
    notifyListeners();
  }

  void togglePlatform(SharePlatform platform, bool selected) {
    if (selected) {
      selectedPlatforms.add(platform);
    } else {
      selectedPlatforms.remove(platform);
    }
    notifyListeners();
  }

  Future<void> pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) {
      return;
    }

    image = picked;
    notifyListeners();
  }

  void removeImage() {
    image = null;
    notifyListeners();
  }

  Future<List<ShareResult>> share(ShareContent content) async {
    if (selectedPlatforms.isEmpty) {
      return const [
        ShareResult(
          platform: 'None',
          success: false,
          message: 'Choose at least one platform.',
        ),
      ];
    }

    isSharing = true;
    lastResults.clear();
    notifyListeners();

    final results = await _shareService.shareToMany(
      platforms: selectedPlatforms,
      content: content,
    );

    lastResults
      ..clear()
      ..addAll(results);
    isSharing = false;
    notifyListeners();
    return results;
  }
}
