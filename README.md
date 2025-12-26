# Local Development Docker Stack

A Docker-based local development environment that replicates the production infrastructure:
- **Load Balancer** (Nginx) with sticky sessions
- **Two Web Nodes** (Apache + PHP-FPM on Rocky Linux)
- **NFS Server** (Shared storage for web nodes)
- **Primary/Secondary Database** (MariaDB with replication)

## Architecture

```
                    [Client Browser]
                          |
                          v (https://cms.test)
                    [Load Balancer]
                     (Nginx:443)
                          |
          +---------------+---------------+
          |                               |
          v                               v
    [web-node-1]                    [web-node-2]
    (Apache+PHP)                    (Apache+PHP)
          |                               |
          +---------------+---------------+
                          |
                          v
                    [NFS Server]
                  (Shared /www_data)

    [db-primary] <--replication--> [db-secondary]
```

## Prerequisites

Before running the containers, ensure you have:

### 1. SSL Certificates
A `web-node/certs/` directory containing:
```
web-node/certs/
├── localhost.crt
└── localhost.key
```
- On how to generate these files on Windows: **https://confluence.it.ubc.ca/x/zIErGQ**
- On how to generate these files on Mac: to be updated

### 2. Environment File
Copy `.env.example` to `.env` and configure as needed:
```bash
cp .env.example .env
```

### 3. Configure Hostname Resolution
Add `cms.test` to your hosts file pointing to `127.0.0.1`:
- On Windows: **https://confluence.it.ubc.ca/x/xIorGQ**
- On Mac: to be updated

## Build and Run

```bash
docker compose up -d
```

Once the containers are running, visit:
- **https://cms.test** - Main application (via load balancer)

## Load Balancer and Sticky Sessions

### How It Works

The Nginx load balancer distributes traffic between two identical web nodes using **cookie-based sticky sessions**:

1. **First Request (New Session)**:
   - Client visits `https://cms.test`
   - Nginx routes to either `web-node-1` or `web-node-2` (round-robin)
   - The selected web node sets a `SERVERID` cookie with its name
   - Response includes: `Set-Cookie: SERVERID=web-node-1`

2. **Subsequent Requests (Existing Session)**:
   - Client sends request with `Cookie: SERVERID=web-node-1`
   - Nginx reads the cookie and routes to `web-node-1`
   - Session remains "sticky" to that node

### Testing Sticky Sessions

1. Open **https://cms.test** in Chrome
2. Open DevTools (F12) → Network tab → Click any request → Headers
3. Look for `X-Served-By: web-node-1` (or `web-node-2`) in response headers
4. Refresh the page multiple times - should stay on the **same node**
5. Open **https://cms.test** in Firefox or an Incognito window
6. Check `X-Served-By` header - may be a **different node**
7. That new session will also be sticky to its assigned node

### Viewing the SERVERID Cookie

1. Open DevTools (F12) → Application tab → Cookies → `https://cms.test`
2. Look for `SERVERID` cookie with value `web-node-1` or `web-node-2`

### Health Check Endpoints

- **Load Balancer**: `https://cms.test/lb-health` - Returns "load-balancer: healthy"
- **Web Nodes**: `https://cms.test/health.php` - Returns node name and status

## Test Pages

### PHP Configuration
Visit **https://cms.test/info.php** to see the PHP information page.

### Database CRUD Operations
Visit **https://cms.test/db-crud-test.php** to test database connectivity.
- "CRUD test PASSED" = Connection working
- "CRUD test FAILED" = Check database configuration

## NFS Architecture

The NFS configuration uses **NFS-Ganesha** in a Docker container to provide a persistent, compatible NFSv4 server that works reliably across platforms (including macOS).

### The "Sync Strategy" (macOS Compatibility)

To solve macOS filesystem limitations (lack of file handles support in Docker bind mounts) while retaining local development capabilities:

1. **Dual Storage**:
   - Your local files (`./nfs/exports`) are mounted to `/staging` (Read-Only)
   - Attributes-compatible storage is provided by a Docker Named Volume mapped to `/exports`

2. **Event-Driven Sync**:
   - The `nfs` container runs `inotifywait` to watch `/staging`
   - When you save a file locally, it is instantly (<100ms) synced to the NFS export volume
   - This gives you the best of both worlds: **Native NFSv4 compatibility** and **instant local updates**

### Key Requirements

1. **Privileged Mode**: `nfs` container runs with `privileged: true` for NFS kernel capabilities
2. **Explicit Protocol Support**: We strictly use NFSv4 (disabled NFSv3 to avoid port randomisation issues)
3. **Client Tracking**: `nfsdcld` handles the NFSv4 Grace Period

### Port Usage

To ensure Docker networking reliability, we pin all RPC services to fixed ports:
- **111** (TCP/UDP): `rpcbind` (Port mapper)
- **2049** (TCP): `nfs` (Main data protocol)
- **20048** (TCP/UDP): `mountd` (Mount protocol, pinned manually in entrypoint)

## Troubleshooting

### NFS Issues

If the web nodes say "NFS server not ready":
1. Check logs: `docker compose logs nfs`
2. Look for "Listening ports" output in the logs to ensure ports 111, 2049, and 20048 are open
3. Ensure `rpc.mountd` is running

### Load Balancer Issues

If you can't reach `https://cms.test`:
1. Check load balancer logs: `docker compose logs load-balancer`
2. Verify web nodes are running: `docker compose ps`
3. Test health endpoint: `curl -k https://cms.test/lb-health`

### Sticky Sessions Not Working

If requests are not sticky:
1. Ensure cookies are enabled in your browser
2. Check that `SERVERID` cookie is being set (DevTools → Application → Cookies)
3. Verify `X-Served-By` header is present in responses
4. Check Nginx logs: `docker compose logs load-balancer`

### View Container Logs

```bash
# All containers
docker compose logs

# Specific container
docker compose logs load-balancer
docker compose logs web-node-1
docker compose logs web-node-2
docker compose logs nfs
docker compose logs db-primary
```

## Network Architecture

| Network | Purpose | Internal |
|---------|---------|----------|
| `app_net` | Load balancer external access | No |
| `web_net` | Load balancer ↔ Web nodes | Yes |
| `db_net` | Web nodes ↔ Database | Yes |
| `db_secondary_net` | Database replication | Yes |
| `nfs_net` | Web nodes ↔ NFS server | Yes |
