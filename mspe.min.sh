mspe() {
TEXT_BOLD="\e[1m"
TEXT_RESET="\e[0m"
show_help() {
echo -e "${TEXT_BOLD}mspe${TEXT_RESET} is an MSP-like tool for Postfix servers.

USAGE: mspe [--rotated|--rbl]
    --rotated                   Check rotated maillog files as well when fetching stats
    --rbl                       Check server IPs against common RBLs (no stats check)
    -h --help                   Show this message and exit
    -v --version                Show version information and exit

Without arguments (except --rotated) mspe fetches mail server stats from the current maillog (like msp.pl --auth)."
}
VERSION="${TEXT_BOLD}mspe${TEXT_RESET} v0.1 (Updated 6/11/23)"
check_stats() {
echo -e "Fetching mail server stats...\n"
if [[ "${USE_ROTATED}" = true ]]; then
LOG_FILE=(/var/log/maillog /var/log/maillog-*)
else
LOG_FILE=(/var/log/maillog)
fi
echo -e "⏳ ${TEXT_BOLD}Queue Size:${TEXT_RESET} $(postqueue -j | wc -l)"
echo -e "\n✔️ ${TEXT_BOLD}Authenticated Senders:${TEXT_RESET}"
grep sasl_username= "${LOG_FILE[@]}" | awk '{print $9}' | sed -E 's/^(sasl_username=)//' | sort | uniq -c | sort -rn
echo -e "\n🧔 ${TEXT_BOLD}User Senders:${TEXT_RESET}"
grep uid= "${LOG_FILE[@]}" | awk '{print $8}' | sed -Ee 's/^(from=)//' -e 's/^<//' -e 's/>$//' | sort | uniq -c | sort -rn
echo -e "\n📧 ${TEXT_BOLD}Top Email Subjects:${TEXT_RESET}"
grep "warning: header Subject:" "${LOG_FILE[@]}" | sed -Ee 's/^.+(warning: header Subject:)\s//' -e 's/\s(from localhost).+$//' | sort | uniq -c | sort -rn
}
check_rbls() {
echo -e "Checking IPs in RBLs..."
IPS="$(hostname -I | xargs -n 1 | grep -Ev '^127.|^10.|^172.|^192.')"
RBLS=("b.barracudacentral.org"
"bl.spamcop.net"
"dnsbl.sorbs.net"
"zen.spamhaus.org")
for IP in ${IPS}; do
echo -e "\n${TEXT_BOLD}${IP}:${TEXT_RESET}"
for RBL in "${RBLS[@]}"; do
RESULT="$(dig +short "$(echo "${IP}" | awk -F '.' '{print $4 "." $3 "." $2 "." $1}')"."${RBL}")"
if [[ -z "${RESULT}" ]]; then
echo -e "\t👍 ${RBL}"
else
echo -e "\t🚫 ${RBL}"
fi
done
done
}
while [[ "${#}" -gt 0 ]]; do
case "${1}" in
--rotated)
USE_ROTATED=true
shift
;;
--rbl|--rbls)
check_rbls
return
;;
-h|--help)
show_help
return
;;
-v|--version)
echo -e "${VERSION}"
return
;;
-*)
echo -e "Not sure what '${1}' is supposed to be.\n"
show_help
return
;;
*)
check_stats
return
;;
esac
done
check_stats
}
