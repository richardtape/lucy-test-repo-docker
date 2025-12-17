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
  
## To Do
- set up NFS machine 

