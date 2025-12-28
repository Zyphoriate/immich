// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

/// Model for cached server endpoint with timestamp
class CachedServerEndpoint {
  final String serverUrl;
  final DateTime cachedAt;
  final String distributionUrl;

  const CachedServerEndpoint({
    required this.serverUrl,
    required this.cachedAt,
    required this.distributionUrl,
  });

  CachedServerEndpoint copyWith({
    String? serverUrl,
    DateTime? cachedAt,
    String? distributionUrl,
  }) {
    return CachedServerEndpoint(
      serverUrl: serverUrl ?? this.serverUrl,
      cachedAt: cachedAt ?? this.cachedAt,
      distributionUrl: distributionUrl ?? this.distributionUrl,
    );
  }

  bool isExpired(Duration cacheDuration) {
    final expirationTime = cachedAt.add(cacheDuration);
    return DateTime.now().isAfter(expirationTime);
  }

  @override
  String toString() =>
      'CachedServerEndpoint(serverUrl: $serverUrl, cachedAt: $cachedAt, distributionUrl: $distributionUrl)';

  @override
  bool operator ==(covariant CachedServerEndpoint other) {
    if (identical(this, other)) return true;

    return other.serverUrl == serverUrl &&
        other.cachedAt == cachedAt &&
        other.distributionUrl == distributionUrl;
  }

  @override
  int get hashCode =>
      serverUrl.hashCode ^ cachedAt.hashCode ^ distributionUrl.hashCode;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'serverUrl': serverUrl,
      'cachedAt': cachedAt.millisecondsSinceEpoch,
      'distributionUrl': distributionUrl,
    };
  }

  factory CachedServerEndpoint.fromMap(Map<String, dynamic> map) {
    return CachedServerEndpoint(
      serverUrl: map['serverUrl'] as String,
      cachedAt: DateTime.fromMillisecondsSinceEpoch(map['cachedAt'] as int),
      distributionUrl: map['distributionUrl'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory CachedServerEndpoint.fromJson(String source) =>
      CachedServerEndpoint.fromMap(json.decode(source) as Map<String, dynamic>);
}
