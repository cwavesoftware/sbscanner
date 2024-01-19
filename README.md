## Usage
> 1. Clone this repo and `$ cd sbscanner`.
> 2. Create .env file and paste the content below. Leave FARADAY_URL and REDIS_SERVER as is, fill in the remaining variables.
```
FARADAY_URL="http://faraday.server:5985"
REDIS_SERVER=redis
FARADAY_SUPERUSER_NAME=
FARADAY_SUPERUSER_EMAIL=
FARADAY_SUPERUSER_PASSWORD=
PGSQL_USER=
PGSQL_PASSWD=
PGSQL_DBNAME=
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
`$ docker compose build`
> 7. Finally, run the scan. **It's important to launch the scripts from the *bin* directory to avoid any errors:**
`$ cd bin && ./scan.sh <ips_input_file> <masscan_rate> <ports> <faraday_workspace> <make_diff> [ports_to_skip_notifications]`

**<*ips_input_file*> is the filename located in targets dir only, without the *./targets/* prefix e.g.:**

`$ ./scan.sh ips.txt 10000 0-65535 myscan no`

You'll have the results in the *out* folder and in [Faraday](http://localhost:5985)

