## Usage
**IMPORTANT**: You must have Faraday set up in order to use this tool.
> 0. Install Faraday - check https://github.com/cosmin91ro/faraday.
> 1. Clone this repo and `$ cd sbscanner`.
> 2. Create .env file and define the following environment variables. Set FARADAY_URL accordingly in case you changed the Faraday hostname during step 0. Leave REDIS_SERVER as it is.
```
FARADAY_URL=http://faraday.server:5985
FARADAY_USER=
FARADAY_PASSWORD=
REDIS_SERVER=redis
```
> 3. Define notify settings in *notify-config.yml* if you want to get notifications. Check https://github.com/projectdiscovery/notify if you need help
> 4. Create directory structure:
`$ mkdir targets && mkdir out`
> 5. Create a file inside *targets* directory. Add your targets there. You can add one IP / range on each line
```
$ echo 172.16.5.40 >> targets/ips.txt
$ echo 192.168.1.0/24 >> targets/ips.txt
...
```
> 6. Build services:
`$ docker-compose build`
> 7. Finally, run the scan. **It's important to launch the scripts from the *bin* directory to avoid any errors:**
`$ cd bin && ./scan.sh <target_file> <masscan_rate> <ports>`

**<*target_file*> is the filename located in targets dir only, without the *./targets/* prefix e.g.:**

`$ ./scan.sh ips.txt 10000 0-65535`

First run will do a baseline scan and save the results in the database, without sending any notifications. Subsequents scans will send notifications accordingly.

You'll have the results in *out* folder and in notifications channels if configured. An UI is currently Work In Progress. 

