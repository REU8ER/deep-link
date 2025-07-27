import 'dart:async';

import 'package:app_links/app_links.dart';
import 'models/link_model.dart';
import 'services/link_service.dart';

class DeepLink {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  void listen(void Function(LinkModel) onLinkData) {
    _sub = _appLinks.uriLinkStream.listen((uri) async {
      final slug = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      if (slug.isNotEmpty) {
        final data = await LinkService.getLink(slug);
        onLinkData(data);
      }
    });
  }

  Future<void> checkInitialLink(void Function(LinkModel) onLinkData) async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      final slug = initial.pathSegments.isNotEmpty
          ? initial.pathSegments.last
          : '';
      if (slug.isNotEmpty) {
        final data = await LinkService.getLink(slug);
        onLinkData(data);
      }
    }
  }

  void dispose() => _sub?.cancel();
}
