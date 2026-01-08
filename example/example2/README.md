# Example 2: OpenFGA Ruby SDK (Environment + Client Credentials)

This example shows a minimal script (`main.rb`) that uses the OpenFGA Ruby SDK with environment-driven configuration. It relies on a local `.env` file in this directory. The script will exit early if `.env` is missing.

This example specifically tests using OpenFGA with OAuth2 client credentials flow, and so a token issuer is expected.

## 1. Prerequisites

- Ruby (3.x recommended; uses `bundler/inline` so you don’t need a separate Gemfile install step).
- Docker (to run an OpenFGA server locally) OR access to an existing OpenFGA deployment.

## 2. Start OpenFGA (Local Dev)

Quick start with Docker (latest image):

```bash
docker run -p 8080:8080 \
  --name openfga \
  openfga/openfga:latest run
```

Or you can use `make start-openfga` from the root of this repo.

To stop/remove later:

```bash
docker rm -f openfga
```

Or you can use `make stop-openfga` from the root of this repo.

## 3. Create a Store and Authorization Model

You need a Store ID and Authorization Model ID to run this example. You can obtain them by:

1. Calling the API directly (e.g. with curl) to create a store and write a model; or
2. Using the OpenFGA dashboard / CLI (if available in your environment).

Minimal API sequence (adjust payload to your model):

```bash
# Create store
curl -s -X POST http://localhost:8080/stores \
  -H 'Content-Type: application/json' \
  -d '{"name":"Example2 Store"}' | jq -r '.id'

# Write authorization model (replace TYPE_DEFS JSON as needed)
STORE_ID=...        # output from previous command
MODEL_PAYLOAD='{"schema_version":"1.1","type_definitions":[]}'

curl -s -X POST http://localhost:8080/stores/$STORE_ID/authorization-models \
  -H 'Content-Type: application/json' \
  -d "$MODEL_PAYLOAD" | jq -r '.authorization_model_id'
```

Set the resulting `STORE_ID` and `authorization_model_id` values into your `.env`.

## 4. Set Up Environment File

A template file `.env.example` is provided. See below for explanations of each variable:

```dotenv
FGA_API_URL=http://localhost:8080
FGA_STORE_ID=
FGA_MODEL_ID=
FGA_CLIENT_ID=
FGA_CLIENT_SECRET=
FGA_API_TOKEN_ISSUER=
FGA_API_AUDIENCE=
```

| Environment Variable   | Required                    | Description                                            | Example Value                          | Notes                                                                           |
|------------------------|-----------------------------|--------------------------------------------------------|----------------------------------------|---------------------------------------------------------------------------------|
| `FGA_API_URL`          | Yes                         | Base URL of the OpenFGA API the SDK connects to.       | `http://localhost:8080`                | Must include scheme; use HTTPS in production.                                   |
| `FGA_STORE_ID`         | Yes                         | ID of the store holding your authorization data.       | `01HABCDEF123XYZ4567`                  | Returned from `POST /stores`. Cannot be blank.                                  |
| `FGA_MODEL_ID`         | Yes                         | ID of the authorization model to target.               | `01HMODELID789XYZ1234`                 | Returned from writing a model (`POST /stores/{store_id}/authorization-models`). |
| `FGA_CLIENT_ID`        | If using client credentials | OAuth2 client identifier for token retrieval.          | `my-openfga-client`                    | Leave empty to skip auth token flow.                                            |
| `FGA_CLIENT_SECRET`    | If using client credentials | Secret paired with the client ID.                      | `supersecretvalue`                     | Treat as sensitive; do not commit.                                              |
| `FGA_API_TOKEN_ISSUER` | If using client credentials | OAuth2 token endpoint / issuer URL.                    | `https://auth.example.com/oauth/token` | Some IdPs call this the issuer or token URL.                                    |
| `FGA_API_AUDIENCE`     | If using client credentials | Audience / resource the access token is requested for. | `https://api.openfga.example.com`      | Omit if your IdP doesn’t require an audience.                                   |

Copy it to `.env` and fill in the required fields.

```bash
cp .env.example .env
# Edit .env in your editor and populate:
# FGA_STORE_ID=...
# FGA_MODEL_ID=...
```

## 5. Run the Example

From this directory (`example/example2`):

```bash
ruby main.rb
```

Or from the root of the repo:

```bash
make run-example2
```

On success, you will see output like:
```
[dotenv] Loaded environment from /path/to/example2/.env
[env] Loaded FGA_* variables:
[env]   FGA_API_URL="http://localhost:8080"
...
Starting OpenFGA Ruby SDK Client Credentials Example
Refreshing access token from <token issuer>
Obtained new access token, expires at 2025-10-21 10:48:06 UTC
OpenFGA Ruby SDK Client Credentials Example completed
```

If `.env` is missing or a required variable is empty you’ll get an early exit or a runtime error. Ensure `FGA_STORE_ID` and `FGA_MODEL_ID` are not blank.

## 6. Troubleshooting

| Issue                  | Cause                                     | Fix                                                                     |
|------------------------|-------------------------------------------|-------------------------------------------------------------------------|
| `No .env found`        | Missing file                              | Copy `.env.example` to `.env` and populate values.                      |
| Connection test failed | Server not running or wrong `FGA_API_URL` | Start OpenFGA locally or correct the URL.                               |
| 401 / auth errors      | Incomplete client credential fields       | Provide all four OAuth-related env vars or remove the client id/secret. |
| Empty store/model IDs  | Not set in `.env`                         | Fill in `FGA_STORE_ID` and `FGA_MODEL_ID`.                              |

## 7. Modifying Correlation IDs

The script uses the `ulid` gem (via `ULID.generate`) for correlation IDs. If you prefer standard UUIDs, change occurrences of `ULID.generate` to `SecureRandom.uuid` and remove the `ulid` gem line plus `require 'ulid'`.

---

Feel free to adjust the authorization model or extend the script with additional API calls (write tuples, checks, etc.).

