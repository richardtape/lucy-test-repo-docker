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
The NFS configuration in this repo uses the **Kernel NFS Server** within a Docker container. This setup mimics a production NAS/NFS appliance.

**Key Requirements:**
1.  **Privileged Mode**: The `nfs` container runs with `privileged: true` because it needs to mount kernel filesystems (`rpc_pipefs`, `nfsd`) inside the container.
2.  **Explicit Protocol Support**: We strictly use NFSv4 (`rpc.nfsd -V 4 -N 3`).
3.  **Client Tracking**: We run `nfsdcld` to handle the NFSv4 Grace Period. If this daemon fails, clients may hang for 90s on boot.

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
