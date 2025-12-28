# Distribution Server Feature

## Overview

This feature allows the Immich Android client to retrieve the actual server address from a distribution server. The distribution server acts as a centralized endpoint that can redirect clients to the appropriate Immich server instance.

## How It Works

1. **User Input**: The user enters a distribution server URL in the login screen
2. **Enable Distribution Mode**: The user checks the "Use Distribution Server" checkbox
3. **Fetch Server URL**: When connecting, the client requests the actual server URL from the distribution server
4. **Caching**: The actual server URL is cached locally with a timestamp
5. **Cache Validation**: On subsequent connections, the client uses the cached server URL if it's still valid (default: 60 minutes)
6. **Cache Refresh**: If the cache has expired, the client fetches a new server URL from the distribution server

## Distribution Server API

The distribution server must provide an HTTP endpoint that returns a JSON response with the following format:

```json
{
  "serverUrl": "https://actual-server.example.com"
}
```

### Example Implementation

Here's a simple example of a distribution server using Node.js/Express:

```javascript
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.json({
    serverUrl: "https://immich-prod.example.com"
  });
});

app.listen(3000, () => {
  console.log('Distribution server running on port 3000');
});
```

### Example with Dynamic Selection

You can implement logic to return different server URLs based on various criteria:

```javascript
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  // Route based on client IP, user-agent, or other criteria
  const clientIP = req.ip;
  
  let serverUrl;
  if (isInternalNetwork(clientIP)) {
    serverUrl = "https://immich-internal.local";
  } else {
    serverUrl = "https://immich-external.example.com";
  }
  
  res.json({ serverUrl });
});

app.listen(3000);
```

## Configuration

### Cache Duration

The cache duration can be configured using the `serverCacheDurationMinutes` store key. Default is 60 minutes.

To customize the cache duration, you can modify the value in the app settings:

```dart
await Store.put(StoreKey.serverCacheDurationMinutes, 120); // 2 hours
```

### Stored Data

The following data is stored when using distribution server mode:

- `distributionServerUrl`: The distribution server URL entered by the user
- `cachedServerEndpoint`: JSON-encoded cached server endpoint with timestamp
- `serverCacheDurationMinutes`: Cache duration in minutes (default: 60)

## User Interface

When the "Use Distribution Server" checkbox is enabled:
- The server URL input field label changes to "Distribution Server URL"
- The hint text updates accordingly
- The system validates the distribution server URL format

## Security Considerations

1. **HTTPS Only**: Both distribution and actual server URLs should use HTTPS
2. **Validation**: The client validates both the distribution server URL and the actual server URL before use
3. **Error Handling**: If the distribution server is unavailable, appropriate error messages are shown
4. **Cache Clearing**: When logging out, all cached server data is cleared

## Implementation Files

- `lib/models/server_distribution/cached_server_endpoint.model.dart` - Model for cached endpoint
- `lib/services/server_distribution.service.dart` - Service for distribution server communication
- `lib/services/auth.service.dart` - Updated to support distribution mode
- `lib/widgets/forms/login/login_form.dart` - Updated login UI with distribution checkbox
- `lib/domain/models/store.model.dart` - Added new store keys
