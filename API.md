# API Documentation

OneTimeSecret provides a REST API for programmatic secret management.

## Base URL

```
https://your-domain.com/api/v1
```

## Authentication

### API Key Authentication

Include your API key in the Authorization header:

```bash
Authorization: ApiKey YOUR_API_KEY_HERE
```

### JWT Token Authentication

Include JWT token in the Authorization header:

```bash
Authorization: Bearer YOUR_JWT_TOKEN_HERE
```

## Endpoints

### Create Secret

Create a new one-time secret.

**Endpoint:** `POST /secrets`

**Request Body:**
```json
{
  "secret": {
    "content": "string (required)",
    "passphrase": "string (optional)",
    "ttl": 3600,
    "max_views": 1,
    "recipient": "email@example.com (optional)",
    "metadata": {}
  }
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "key": "abc123xyz",
    "url": "https://your-domain.com/secret/abc123xyz",
    "expires_at": "2025-01-02T12:00:00Z",
    "max_views": 1
  }
}
```

**Example:**
```bash
curl -X POST https://your-domain.com/api/v1/secrets \
  -H "Content-Type: application/json" \
  -d '{
    "secret": {
      "content": "My secret API key: sk_test_123456",
      "ttl": 3600,
      "max_views": 1
    }
  }'
```

### Get Secret Metadata

Retrieve metadata about a secret without revealing its content.

**Endpoint:** `GET /secrets/:key/metadata`

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "key": "abc123xyz",
    "created_at": "2025-01-01T12:00:00Z",
    "expires_at": "2025-01-02T12:00:00Z",
    "max_views": 1,
    "views_count": 0,
    "state": "active",
    "has_passphrase": false
  }
}
```

**Example:**
```bash
curl https://your-domain.com/api/v1/secrets/abc123xyz/metadata
```

### Reveal Secret

Retrieve and reveal a secret's content. This increments the view count.

**Endpoint:** `POST /secrets/:key`

**Request Body:**
```json
{
  "passphrase": "string (required if secret has passphrase)"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "content": "My secret API key: sk_test_123456",
    "views_remaining": 0,
    "state": "burned"
  }
}
```

**Example:**
```bash
curl -X POST https://your-domain.com/api/v1/secrets/abc123xyz \
  -H "Content-Type: application/json" \
  -d '{"passphrase": ""}'
```

### Burn Secret

Immediately destroy a secret, making it inaccessible.

**Endpoint:** `DELETE /secrets/:key`

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Secret burned successfully"
}
```

**Example:**
```bash
curl -X DELETE https://your-domain.com/api/v1/secrets/abc123xyz
```

### List User Secrets

List all secrets created by the authenticated user.

**Endpoint:** `GET /secrets`

**Authentication:** Required (API Key or JWT)

**Query Parameters:**
- `limit` (optional, default: 50): Number of results
- `offset` (optional, default: 0): Pagination offset

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "key": "abc123xyz",
      "created_at": "2025-01-01T12:00:00Z",
      "expires_at": "2025-01-02T12:00:00Z",
      "max_views": 1,
      "views_count": 1,
      "state": "burned"
    }
  ]
}
```

**Example:**
```bash
curl https://your-domain.com/api/v1/secrets?limit=10&offset=0 \
  -H "Authorization: ApiKey YOUR_API_KEY"
```

## Error Responses

### Not Found (404)
```json
{
  "success": false,
  "error": "Secret not found"
}
```

### Unauthorized (401)
```json
{
  "success": false,
  "error": "Invalid passphrase"
}
```

### Gone (410)
```json
{
  "success": false,
  "error": "Secret is no longer accessible"
}
```

### Unprocessable Entity (422)
```json
{
  "success": false,
  "error": "Content exceeds maximum size"
}
```

### Too Many Requests (429)
```json
{
  "success": false,
  "error": "Rate limit exceeded. Please try again later."
}
```

## Rate Limiting

- **Anonymous**: 60 requests per minute per IP
- **Authenticated**: 100 requests per minute per user

Rate limit information is included in response headers:
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 59
X-RateLimit-Reset: 1609459200
```

## Code Examples

### Python

```python
import requests

# Create secret
response = requests.post(
    'https://your-domain.com/api/v1/secrets',
    json={
        'secret': {
            'content': 'My secret data',
            'ttl': 3600,
            'max_views': 1
        }
    }
)
data = response.json()
secret_url = data['data']['url']

# Reveal secret
response = requests.post(
    f'https://your-domain.com/api/v1/secrets/{data["data"]["key"]}',
    json={'passphrase': ''}
)
secret_content = response.json()['data']['content']
```

### JavaScript

```javascript
// Create secret
const createResponse = await fetch('https://your-domain.com/api/v1/secrets', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    secret: {
      content: 'My secret data',
      ttl: 3600,
      max_views: 1
    }
  })
});

const { data } = await createResponse.json();
const secretUrl = data.url;

// Reveal secret
const revealResponse = await fetch(
  `https://your-domain.com/api/v1/secrets/${data.key}`,
  {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ passphrase: '' })
  }
);

const { data: secretData } = await revealResponse.json();
console.log(secretData.content);
```

### cURL

```bash
# Create secret
SECRET_RESPONSE=$(curl -s -X POST https://your-domain.com/api/v1/secrets \
  -H "Content-Type: application/json" \
  -d '{"secret":{"content":"My secret","ttl":3600}}')

SECRET_KEY=$(echo $SECRET_RESPONSE | jq -r '.data.key')

# Reveal secret
curl -s -X POST https://your-domain.com/api/v1/secrets/$SECRET_KEY \
  -H "Content-Type: application/json" \
  -d '{"passphrase":""}' | jq -r '.data.content'
```

## GraphQL API

OneTimeSecret also provides a GraphQL endpoint at `/api/graphql`.

### Example Query

```graphql
query GetSecret($key: String!) {
  secret(key: $key) {
    key
    createdAt
    expiresAt
    maxViews
    viewsCount
    state
  }
}
```

### Example Mutation

```graphql
mutation CreateSecret($input: SecretInput!) {
  createSecret(input: $input) {
    key
    url
    expiresAt
  }
}
```

Variables:
```json
{
  "input": {
    "content": "My secret",
    "ttl": 3600,
    "maxViews": 1
  }
}
```

### GraphiQL Playground

Visit `/api/graphiql` in your browser to explore the GraphQL API interactively.
