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
- On Windows: to be updated
- On Mac: to be updated 
  
## Build the Docker Image
Run the following command from the project root:

```bash
docker build -t rockyapache .
```
## Run the HTTPS-Enabled Container
Use this command to launch the container:

```bash
docker run -d   -p 80:80   -p 443:443   --name mycontainer   -v ./certs/localhost.crt:/etc/pki/tls/certs/localhost.crt:ro   -v ./certs/localhost.key:/etc/pki/tls/private/localhost.key:ro   rockyapache
```
Once the container is running, you can visit:

- **http://cms.test**
- **https://cms.test**
  
## To Do
- Set up Apache to only accept HTTPS requests (redirect HTTP to HTTPS) via config files
- PHP
- Database container
- Docker compose file 
