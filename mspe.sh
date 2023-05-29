#!/bin/bash
# mspe - MSP-like tool for Postfix servers
# Nathan Paton <me@tchbnl.net>
# v0.1 (Updated 5/28/23)

# Nice text formatting
TEXT_BOLD="\e[1m"
TEXT_RESET="\e[0m"

# Help message
show_help() {
    echo -e "${TEXT_BOLD}mspe${TEXT_RESET} is an MSP-like tool for Postfix servers.

USAGE: mspe [--rotated|--rbl]
    --rotated                   Check rotated maillog files as well when fetching stats
    --rbl                       Check server IPs against common RBLs (no stats check)
    -h --help                   Show this message and exit
    -v --version                Show version information and exit

Without arguments (except --rotated) mspe fetches mail server stats from the current maillog (like msp.pl --auth)."
}

# Version information
VERSION="${TEXT_BOLD}mspe${TEXT_RESET} v0.1 (Updated 5/28/23)"

# Mail queue and log stats
# This is the equivalent of msp.pl --auth
check_stats() {
    echo -e "Fetching mail server stats...\n"

    # If --rotated is used, we search both the current and rotated maillogs
    # We also want to advise that this could take some time for a larger server
    if [[ "${USE_ROTATED}" = true ]]; then
        LOG_FILE=(/var/log/maillog /var/log/maillog-*)
    else
        LOG_FILE=(/var/log/maillog)
    fi

    # Get current mail queue size
    # Thanks Postfix for having a JSON output of the queue to make this a lot easier
    echo -e "⏳ ${TEXT_BOLD}Queue Size:${TEXT_RESET} $(postqueue -j | wc -l)"

    # Get authenticated senders (AKA actual email accounts)
    echo -e "\n✔️ ${TEXT_BOLD}Authenticated Senders:${TEXT_RESET}"
    grep sasl_username= "${LOG_FILE[@]}" | awk '{print $9}' | sed -E 's/^(sasl_username=)//' | sort | uniq -c | sort -rn

    # Get users that have sent mail via sendmail
    echo -e "\n🧔 ${TEXT_BOLD}User Senders:${TEXT_RESET}"
    grep uid= "${LOG_FILE[@]}" | awk '{print $8}' | sed -Ee 's/^(from=)//' -e 's/^<//' -e 's/>$//' | sort | uniq -c | sort -rn

    # Most common subjects in the maillog
    # Subject logging is disabled in a default Postfix install, but this will work if it's configured
    echo -e "\n📧 ${TEXT_BOLD}Top Email Subjects:${TEXT_RESET}"
    grep "warning: header Subject:" "${LOG_FILE[@]}" | sed -Ee 's/^.+(warning: header Subject:)\s//' -e 's/\s(from localhost).+$//' | sort | uniq -c | sort -rn
}

# RBL checks
# Equivalent to msp.pl --rbl --all
# TODO: Support custom RBLs (without editing this file)
check_rbls() {
    echo -e "Checking IPs in RBLs..."

    # Get our IPs
    # TODO: IPv6 support I swear I know
    IPS="$(hostname -I | xargs -n 1 | grep -Ev '^127.|^10.|^172.|^192.')"

    # Get our RBLs
    RBLS=("b.barracudacentral.org"
          "bl.spamcop.net"
          "dnsbl.sorbs.net"
          "zen.spamhaus.org")

    # And now we loop through each IP...
    for IP in ${IPS}; do
        echo -e "\n${TEXT_BOLD}${IP}:${TEXT_RESET}"

        # ... and loop further into checking each RBL
        for RBL in "${RBLS[@]}"; do
            # Check the IP against the DNS RBL and variablize it for after
            # It took me a while to realize I needed to reverse the IP. I never
            # said I was smart this is written in Bash.
            RESULT="$(dig +short "$(echo "${IP}" | rev)"."${RBL}")"

            # And there it is. Empty response means we're good.
            if [[ -z "${RESULT}" ]]; then
                echo -e "\t👍 ${RBL}"
            else
                echo -e "\t🚫 ${RBL}"
            fi
        done
    done
}

# Command line options
while [[ "${#}" -gt 0 ]]; do
    case "${1}" in
        --rotated)
            USE_ROTATED=true
            shift
            ;;

        --rbl|--rbls)
            check_rbls
            exit
            ;;

        -h|--help)
            show_help
            exit
            ;;

        -v|--version)
            echo -e "${VERSION}"
            exit
            ;;

        -*)
            echo -e "Not sure what '${1}' is supposed to be.\n"
            show_help
            exit
            ;;

        *)
            check_stats
            exit
            ;;
    esac
done

# We run stats if the non-stats options weren't called
check_stats
