import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher_string.dart';

class UrlHelper {
  static String toAbsolute(String baseUrl, String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;

    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = url.startsWith('/') ? url : '/$url';
    return '$cleanBase$cleanPath';
  }

  static String normalizeSocialUrl(String platform, String handle) {
    String value = handle.trim();
    if (value.isEmpty) return '';

    if (value.startsWith('//')) {
      return 'https:$value';
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('www.')) {
      return 'https://$value';
    }

    if (value.contains('.') && !value.contains(' ')) {
      final Uri? candidate = Uri.tryParse('https://$value');
      if (candidate != null && candidate.host.isNotEmpty) {
        return candidate.toString();
      }
    }

    final lowerValue = value.toLowerCase();
    const knownDomains = <String>[
      'github.com',
      'github.com/',
      'instagram.com',
      'instagram.com/',
      'www.instagram.com',
      'www.instagram.com/',
      'discord.gg/',
      'discord.com',
      'discord.com/',
      'discord.com/invite/',
      'discord.com/',
      'discordapp.com/',
      't.me',
      't.me/',
      'telegram.me',
      'telegram.me/',
      'open.spotify.com',
      'open.spotify.com/',
      'spotify.com',
      'spotify.com/',
      'tiktok.com',
      'tiktok.com/',
      'www.tiktok.com',
      'www.tiktok.com/',
      'vt.tiktok.com',
      'vt.tiktok.com/',
    ];

    if (knownDomains.any(lowerValue.startsWith)) {
      return 'https://$value';
    }

    value = value.replaceFirst(RegExp(r'^@+'), '').trim();

    switch (platform.toLowerCase()) {
      case 'github':
        return 'https://github.com/$value';
      case 'instagram':
        return 'https://instagram.com/$value';
      case 'discord':
        return value.contains('/')
            ? 'https://discord.com/$value'
            : 'https://discord.com/users/$value';
      case 'telegram':
        return 'https://t.me/$value';
      case 'spotify':
        return value.startsWith('user/') ||
                value.startsWith('artist/') ||
                value.startsWith('track/') ||
                value.startsWith('album/') ||
                value.startsWith('playlist/')
            ? 'https://open.spotify.com/$value'
            : 'https://open.spotify.com/user/$value';
      case 'tiktok':
        return 'https://www.tiktok.com/@$value';
      default:
        return value;
    }
  }

  static Future<bool> launchSocialUrl(String platform, String handle) async {
    final url = normalizeSocialUrl(platform, handle);
    if (url.isEmpty) return false;

    try {
      return await launchUrlString(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[UrlHelper][LaunchSocial][Error] $e');
      return false;
    }
  }
}
