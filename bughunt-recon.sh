#!/bin/bash

# Get domain for parameter script
DOMAIN=$1

echo "# Started scan on domain = $DOMAIN | Date = $(date)"

# Get all subdomains using subfinder
echo "# Get subdomains using subfinder"
subfinder -recursive -silent -all -t 200 -d $DOMAIN >> subs

# Get subdomains using assetfinder
echo "# Get subdomains using assetfinder"
assetfinder --subs-only $DOMAIN >> subs

echo "# Get subdomains using amass"
amass enum -passive -norecursive -noalts -d $DOMAIN >> subs

echo "# Get subdomains using sublist3r"
sublist3r -d $DOMAIN -n -t 200 >> subs

# Get subdomains using CERT.SH
echo "# Get subdomains using CERT.SH"
curl -s "https://crt.sh/?q=%25.$DOMAIN&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | anew >> subs

# Get subdomains using bruteforce
echo "# Get subdomains using bruteforce"
for sub in $(cat /home/quintanilha/SecLists/Discovery/DNS/subdomains-top1million-5000.txt); do host $sub.$DOMAIN >> subs-bruterecon; done
#for sub in $(cat ~/SecLists/Discovery/DNS/namelist.txt); do host $sub.$DOMAIN >> subs-bruterecon; done

# Clean "not found" subdomains
echo "# Clean 'not found' subdomains"
cat subs-bruterecon | grep -vi refused | grep -vi "not found" | awk '{print $1}' | sort -u >> subs


# Remove duplicates
echo "# Remove duplicates"
cat subs | anew | sort -u >> subs-uniq

# Remove subs file and rename unique subs to subs again
echo "# Remove subs file and rename unique subs to subs again"
rm subs
mv subs-uniq subs

# Do "host" on each subdomain and get only subdomains with aliases (important for subdomains takeover)
echo "# Do "host" on each subdomain and get only subdomains with aliases (important for subdomains takeover)"
for sub in $(cat subs); do host $sub | grep -i "alias" | sort -u >> subs-alias; done 

# Get only alive subdomains
echo "# Get only alive subdomains"
cat subs | httpx -silent -timeout 15 -follow-redirects -no-fallback >> subs-alive

# Scan alive subdomains with all Nuclei templates
#echo "# Scan alive subdomains with all Nuclei templates"
#nuclei -l subs-alive -t ~/nuclei-templates -silent -o nuclei-scan-subs

# End of script
echo "# End of scan of domain = $DOMAIN | Date = $(date)"
