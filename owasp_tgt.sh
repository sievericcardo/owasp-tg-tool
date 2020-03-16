#!/bin/bash

##############################################################################
#                   OWASP Penetration Testing Guide script                   #
##############################################################################
#           This program is distributed under the "GPLv3" License            #
##############################################################################
# The purpose of this script is to provide a full-functioning  set of tools  #
# script to test a system and web application against the various test from  #
# the OWASP Penetration Testing Guide. I will try to make it working as much #
# as possible from bash only without using external programs written in C or #
# Python. Note that lots of tests cannot be automated and require a tester.  #
# The complete set of information needed are provided with the showhelp info #
##############################################################################

header()
{
    echo "OWASP Testing Guide script tool"
    echo "GPLv3"
    echo
}

showhelp()
{
    header
    echo 'Usage: owasp_tg [OPTIONS]'
    echo
    echo 'OPTIONS:'
    echo '-h   | --help: Show this help screen. Install java before apache.'
    echo '-s   | --scan (ip or url) [OPTIONS]: Scan the system for disclosure' \
            ' of information'
    echo '       -P | --plain-http: check the system for info on port 80'
    echo '       -S | --secure-http: check the system for info on port 443'
    echo '-r   | --robots (ip or url): check the system for the presence of' \
            ' robots.txt file or sitemap.xml file'
    echo '-c   | --crawler (ip or url): try to enumerate all possible link' \
            ' inside the web application'
    echo '-n   | --nmap-scanning (ip or url): execute a complete nmap scan' \
            ' against the web application for possible open ports or detection'
    echo '-nS  | --nmap-scripting (ip or url) (port): check the given url' \
            ' for the given port against all nmap scripting for possible' \
            ' vulnerabilities'

}


# We need super user privileges to execute the script
user_id=$(id -u)

if [ "$user_id" != "0" ]; then
    echo "You need super user priviliges for this."
    exit
fi

# Install dependencies
# TODO: implement a feature to check os style and install accordingly
apt-get install nmap

# Decalare the various option for nc
declare -a http_var=("HEAD" "GET" "POST" "DELETE" "OPTIONS" "TRACE")

# Get the length of the array
array_length=${#http_var[@]}

# Remove possible existing file and re-create them
rm -f /tmp/nc_80_res.txt
rm -f /tmp/nc_443_res.txt
touch /tmp/nc_80_res.txt
touch /tmp/nc_443_res.txt

# Scanner for simple http web ports
scan_http()
{
    # Loop through the http variable array for the various netcat commands
    for (( i=1; i<${array_length}+1; i++ ));
    do
        # Set the options from the array
        option=${http_var[$i-1]}

        # Create the tmp string containing the result of the nmap-ncat command
        # targeting the http site
        tmp=`printf $option' / HTTP/1.1\r\n\r\n' | nc "$1" 80`

        # In case I found a 200 message I will save it into the file
        if [ `echo tmp | grep 200` > 1 ]
        then
            echo $option" got a result" >> /tmp/nc_80_res.txt
            echo "" >> /tmp/nc_80_res.txt
            printf $option' / HTTP/1.1\r\n\r\n' | nc "$1" 80 >> /tmp/nc_80_res.txt
            echo "" >> /tmp/nc_80_res.txt
        fi
    done
}

# Scanner for https web apps. We need to use nmap for this purpose
scan_https()
{
    # Loop through the http variable array for the various netcat commands
    for (( i=1; i<${array_length}+1; i++ ));
    do
        # Set the options from the array
        option=${http_var[$i-1]}

        # Create the tmp string containing the result of the nmap-ncat command
        # targeting the https site
        tmp=`printf $option' / HTTP/1.1\r\nHost: '$1'\r\n\r\n' | ncat --ssl $1 443`

        # In case I found a 200 message I will save it into the file
        if [ `echo $tmp | grep -c '200'` -ge 1 ]
        then
            echo $option" got a result" >> /tmp/nc_443_res.txt
            echo "" >> /tmp/nc_443_res.txt
            printf $option' / HTTP/1.1\r\nHost: '$1'\r\n\r\n' | ncat --ssl $1 443 >> /tmp/nc_443_res.txt
            echo "" >> /tmp/nc_443_res.txt
        fi
    done
}

# Check for presence of robots or sitemaps
r_s_check()
{
    # Check for robots file
    if [ `wget $1'/robots.txt' | grep -c '200'` -ge 1 ]
    then
        wget $1'/robots.txt' > /tmp/robots.txt
    fi

    # Check for sitemaps
    if [ `wget $1'/sitemap.xml' | grep -c '200'` -ge 1 ]
    then
        wget $1'/sitemap.xml' > /tmp/sitemap.txt
    fi
}

# Web app crawler
web_crawler()
{
    # Wget options used
    # -E gets the extension of the file
    # -p gets all the pages requisites
    # -r for recursiveness
    # -U to make it like a call from Mozilla (or other chosen browser)
    # -e to disable robots
    #
    # --no-clobber to avoid overwriting any existing file
    # --convert-links to make it offline links
    # --spider to behave like a web spider (instead of downloading the page
    #           we will only check if they exists)
    #
    # Credits to https://tinyurl.com/bash-crawler for the reference
    #
    # Extra check wir dirbuster might be a good practice
    wget --no-clobber --convert-links --random-wait -r -p --level 1 \
        -E -e robots=off -U mozilla --spider $1 > /tmp/web_crawler.txt
}

port_scanning()
{
    # Using nmap to check the whole system
    #
    # -vv for verbosity
    # -Pn to treat all hosts as online
    # -A to enable OS detection, version detection, script scanning and tracert
    # -sS for stealth scan syn scan (might still be detected)
    # -T4 timing template (0 - 5 where 5 is fastest, 0 is slowest)
    # -p- all tcp ports
    # -oN output as normal nmap output
    nmap -vv -Pn -A -sS -T4 -p- -oN /tmp/nmap_scan.txt $1
}

nmap_script_scanning()
{
    # Check specific port on system against nmap scripts
    nmap -vv -p $2 --script=all $1
}

while [ "$1" ]; do
    case $1 in
        '-h' | '--help' | '?' )
            showhelp
            exit
            ;;
        '--scan' | '-s' )
            case $3 in
                '-P' | '--plain-http' )
                    scan_http "$2"
                    exit
                    ;;
                '-S' | '--secure-http' )
                    scan_https "$2"
                    exit
                    ;;
            esac
            # By deafult we will check the plain txt
            scan_http "$2"
            exit
            ;;
        '--robots' | '-r' )
            r_s_check "$2"
            exit
            ;;
        '--crawler' | '-c' )
            web_crawler "$2"
            exit
            ;;
        '--nmap-scanning' | '-n' )
            port_scanning "$2"
            exit
            ;;
        '--nmap-scripting' | '-nS' )
            nmap_script_scanning $1 $2
            exit
            ;;
    esac

    shift
done
