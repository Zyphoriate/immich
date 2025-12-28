import 'dart:convert';
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:immich_mobile/domain/models/store.model.dart';
import 'package:immich_mobile/entities/store.entity.dart';
import 'package:immich_mobile/models/server_distribution/cached_server_endpoint.model.dart';
import 'package:immich_mobile/utils/url_helper.dart';
import 'package:logging/logging.dart';

final serverDistributionServiceProvider = Provider(
  (ref) => ServerDistributionService(),
);

class ServerDistributionService {
  final _log = Logger("ServerDistributionService");
  static const int defaultCacheDurationMinutes = 60;
  static const Duration requestTimeout = Duration(seconds: 10);

  /// Fetches the server URL from the distribution server
  /// 
  /// The distribution server is expected to return a JSON response with the following format:
  /// {
  ///   "serverUrl": "https://actual-server.example.com"
  /// }
  Future<String> fetchServerUrlFromDistribution(String distributionUrl) async {
    final client = http.Client();
    
    try {
      final sanitizedUrl = sanitizeUrl(distributionUrl);
      final uri = Uri.parse(sanitizedUrl);
      
      _log.info("Fetching server URL from distribution server: $sanitizedUrl");
      
      final response = await client
          .get(uri, headers: {"Accept": "application/json"})
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data.containsKey('serverUrl')) {
          final serverUrl = data['serverUrl'] as String;
          _log.info("Received server URL from distribution: $serverUrl");
          return serverUrl;
        } else {
          final availableFields = data.keys.join(', ');
          throw Exception(
            'Distribution server response missing "serverUrl" field. '
            'Available fields: $availableFields',
          );
        }
      } else {
        throw HttpException(
          'Distribution server returned status code ${response.statusCode}',
        );
      }
    } catch (error, stackTrace) {
      _log.severe("Error fetching from distribution server", error, stackTrace);
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Gets the server URL, using cache if valid, otherwise fetches from distribution
  Future<String> getServerUrl(String distributionUrl) async {
    final cacheDuration = Duration(
      minutes: Store.get(
        StoreKey.serverCacheDurationMinutes,
        defaultCacheDurationMinutes,
      ),
    );

    // Try to get cached endpoint
    final cachedEndpointJson = Store.tryGet(StoreKey.cachedServerEndpoint);
    
    if (cachedEndpointJson != null && cachedEndpointJson.isNotEmpty) {
      try {
        final cachedEndpoint = CachedServerEndpoint.fromJson(cachedEndpointJson);
        
        // Check if cache is still valid and distribution URL matches
        if (!cachedEndpoint.isExpired(cacheDuration) && 
            cachedEndpoint.distributionUrl == distributionUrl) {
          _log.info("Using cached server URL: ${cachedEndpoint.serverUrl}");
          return cachedEndpoint.serverUrl;
        } else {
          _log.info("Cache expired or distribution URL changed, fetching new server URL");
        }
      } catch (error) {
        _log.warning("Failed to parse cached endpoint, will fetch new one", error);
      }
    }

    // Cache is invalid or doesn't exist, fetch from distribution server
    final serverUrl = await fetchServerUrlFromDistribution(distributionUrl);
    
    // Cache the new server URL
    await cacheServerUrl(serverUrl, distributionUrl);
    
    return serverUrl;
  }

  /// Caches the server URL with the current timestamp
  Future<void> cacheServerUrl(String serverUrl, String distributionUrl) async {
    final cachedEndpoint = CachedServerEndpoint(
      serverUrl: serverUrl,
      cachedAt: DateTime.now(),
      distributionUrl: distributionUrl,
    );
    
    await Store.put(StoreKey.cachedServerEndpoint, cachedEndpoint.toJson());
    _log.info("Cached server URL: $serverUrl");
  }

  /// Clears the cached server endpoint
  Future<void> clearCache() async {
    await Store.delete(StoreKey.cachedServerEndpoint);
    _log.info("Cleared cached server endpoint");
  }

  /// Checks if there is a valid cached endpoint
  bool hasCachedEndpoint(String distributionUrl) {
    final cacheDuration = Duration(
      minutes: Store.get(
        StoreKey.serverCacheDurationMinutes,
        defaultCacheDurationMinutes,
      ),
    );

    final cachedEndpointJson = Store.tryGet(StoreKey.cachedServerEndpoint);
    
    if (cachedEndpointJson == null || cachedEndpointJson.isEmpty) {
      return false;
    }

    try {
      final cachedEndpoint = CachedServerEndpoint.fromJson(cachedEndpointJson);
      return !cachedEndpoint.isExpired(cacheDuration) && 
             cachedEndpoint.distributionUrl == distributionUrl;
    } catch (error) {
      _log.warning("Failed to check cached endpoint", error);
      return false;
    }
  }
}
