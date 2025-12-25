## Prerequisites
Before running the container, ensure you have:
- A `certs/` directory in your project root containing:
```
certs/
├── localhost.crt
└── localhost.key
```
- On how to generate these files on Windows: **https://confluence.it.ubc.ca/x/zIErGQ**
- On how to generate these files on Mac: to be updated 

## Configure Hostname Resolution
- On Windows: **https://confluence.it.ubc.ca/x/xIorGQ**
- On Mac: to be updated 
  
## Build the Containers
Run the following command from the project root:

```bash
docker compose up -d
```

Once the container is running, you can visit:

- **http://cms.test**
- **https://cms.test**

## Test if PHP is properly configured
Visit: 
- **https://cms.test/info.php** 
If PHP is working correctly, you should see the PHP information page.

## Test if web node can do CRUD operations on database container
Visit: 
- **https://cms.test/db-crud-test.php**
If the connection is working properly, you should see text that says "CRUD test PASSED"; otherwise you'd see "CRUD test FAILED". 
  
## NFS Architecture
The NFS configuration uses **NFS-Ganesha** in a Docker container to provide a persistent, compatible NFSv4 server that works reliably across platforms (including macOS).

### The "Sync Strategy" (macOS Compatibility)
To solve macOS filesystem limitations (lack of file handles support in Docker bind mounts) while retaining local development capabilities:
1.  **Dual Storage**: 
    -   Your local files (`./nfs/exports`) are mounted to `/staging` (Read-Only).
    -   Attributes-compatible storage is provided by a Docker Named Volume mapped to `/exports`.
2.  **Event-Driven Sync**:
    -   The `nfs` container runs `inotifywait` to watch `/staging`.
    -   When you save a file locally, it is instantly (<100ms) synced to the NFS export volume.
    -   This gives you the best of both worlds: **Native NFSv4 compatibility** and **instant local updates**.

**Key Requirements:**
1.  **Privileged Mode**: `nfs` container runs with `privileged: true` for NFS kernel capabilities.
2.  **Explicit Protocol Support**: We strictly use NFSv4 (disabled NFSv3 to avoid port randomisation issues).
3.  **Client Tracking**: `nfsdcld` handles the NFSv4 Grace Period.

**Port Usage:**
To ensure Docker networking reliability, we pin all RPC services to fixed ports:
- **111** (TCP/UDP): `rpcbind` (Port mapper)
- **2049** (TCP): `nfs` (Main data protocol)
- **20048** (TCP/UDP): `mountd` (Mount protocol, pinned manually in entrypoint)

**Troubleshooting:**
If the `web-node` says "NFS server not ready":
1.  Check logs: `docker compose logs nfs`
2.  Look for "Listening ports" output in the logs to ensure ports 111, 2049, and 20048 are open.
3.  Ensure `rpc.mountd` is running.
