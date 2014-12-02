#!/bin/bash
#
# Nagios NRPE plugin to restart, reload a service and ensure its port is
# listening on specified ports
#

ST_OK=0
ST_WR=1
ST_CR=2
ST_UK=3

AUTHOR="Rohit Gupta - @rohit01"
PROGNAME=`basename $0`
VERSION="Version 1.0,"

print_version() {
    echo "$PROGNAME: $VERSION $AUTHOR"
}

print_help() {
    echo "$PROGNAME is a custom Nagios plugin to restart any init service"
    echo "and ensure it is listening to the given TCP/UDP port. To be used"
    echo "as a event for process checks in Shinken/Nagios"
    echo ""
    echo "Usage: $PROGNAME -s <service name> [-p <port no> -t <udp/tcp>]"
    echo ""
    echo "Options:"
    echo "  -s/--servicename)"
    echo "     Init Service to be restarted. Mandarory option."
    echo "     If this is a comma separated value, the first available service"
    echo "     will be selected"
    echo "  -g/--grepnames)"
    echo "     The string to grep for process check. Comma separated values"
    echo "     Default: servicename (value passed)"
    echo "  -p/--ports)"
    echo "     Verify if servie is listening to given port[s]. Pass value"
    echo "    'anyport' if you it it picks up any random port for listening"
    echo "     Default: Not set"
    echo "  -t/--connectiontype)"
    echo "     Port type on which service listens"
    echo "     Possible values: tcp, udp, {tcp,udp}. Default: tcp,udp"
    echo "  -f/--force)"
    echo "     Force restart of service even if it is already running"
    echo "     Default: true [true/yes/y]"
    echo "  -k/--killservice)"
    echo "     Force kill the service before using restart command"
    echo "     Default: false [false/no/n]"
    echo "  -w/--waitforport)"
    echo "     Wait in no of seconds to declare process restart failure"
    echo "     Default: 1"
    echo "  -n/--nretry)"
    echo "     No of retry to restart the service properly"
    echo "     Default: 10"
    echo "  -h/--help)"
    echo "     Print this help message & exit"
    echo "  -v/--version)"
    echo "     Print version of this script & exit"
    echo ""
    echo "Examples:"
    echo "   $PROGNAME -s nginx -p 80,443 -t tcp"
}

## Set defaults for optional arguments
ports=''
connectiontype='tcp,udp'
force='true'
killservice='false'
waitforport='1'
nretry='10'


while test -n "$1"; do
    case "$1" in
        --help|-h)
            print_help
            exit $ST_UK
            ;;
        --version|-v)
            print_version
            exit $ST_UK
            ;;
        --servicename|-s)
            servicename=$2
            shift
            ;;
        --grepnames|-g)
            grepnames=$2
            shift
            ;;
        --ports|-p)
            ports=$2
            shift
            ;;
        --connectiontype|-t)
            connectiontype=$2
            shift
            ;;
        --force|-f)
            force=$2
            shift
            ;;
        --killservice|-k)
            killservice=$2
            shift
            ;;
        --waitforport|-w)
            waitforport=$2
            shift
            ;;
        --nretry|-n)
            nretry=$2
            shift
            ;;
        *)
            echo "Unknown argument: '$1'"
            echo ""
            print_help
            exit $ST_UK
            ;;
        esac
    shift
done

######## Validate arguments passed ########
if echo ${servicename} | grep "^$" | grep -v grep | grep -v ${PROGNAME} \
        >/dev/null; then
    echo "Mandatory option -s/--servicename not specified"
    exit $ST_UK
fi
if echo ${grepnames} | grep "^\s*$" | grep -v grep | grep -v ${PROGNAME} \
        >/dev/null; then
    grepnames="${servicename}"
fi
if [ ! -f "/etc/init.d/${servicename}" ]; then
    for filename in $(echo "${servicename}" | sed "s/,/ /g"); do
        if [ -f "/etc/init.d/${filename}" ]; then
            servicename="${filename}"
            break
        fi
    done
    if [ ! -f "/etc/init.d/${servicename}" ]; then
        echo "'/etc/init.d/${servicename}' file not found. Package not installed"
        exit $ST_UK
    fi
fi
if (echo ${ports} | grep -v -e "^$" -e "^[0-9,]*$" | grep -v grep \
        | grep -v ${PROGNAME} >/dev/null) && [ "X${ports}" != 'Xanyport' ]; then
    echo "Invalid value: '${ports}' for option -p/--ports. Possible values:" \
         "integer separated by comma "
    exit $ST_UK
fi
if echo ${connectiontype} | grep -v -e "^tcp,udp$" -e "^tcp$" -e "^udp$" \
        >/dev/null; then
    echo "Invalid value: '${connectiontype}' for option -t/--connectiontype." \
         "Possible values: tcp, udp, {tcp,udp}. Default: tcp,udp"
    exit $ST_UK
fi
if echo ${force} | tr '[:upper:]' '[:lower:]' | grep -v -e "^true$" \
        -e "^yes$" -e "^y$" -e "^false$" -e "^no$" -e "^n$" >/dev/null; then
    echo "Invalid value: '${force}' for option -f/--force." \
         "Possible values: true/yes/y, false/no/n"
    exit $ST_UK
fi
if echo ${killservice} | tr '[:upper:]' '[:lower:]' | grep -v -e "^true$" \
        -e "^yes$" -e "^y$" -e "^false$" -e "^no$" -e "^n$" >/dev/null; then
    echo "Invalid value: '${killservice}' for option -k/--killservice." \
         "Possible values: true/yes/y, false/no/n"
    exit $ST_UK
fi
if (echo ${waitforport} | grep -v -e "^[0-9]*$" | grep -v grep \
        | grep -v ${PROGNAME} >/dev/null); then
    echo "Invalid value: '${waitforport}' for option -w/--waitforport. " \
         "Possible values: Positive Integer (no of seconds)"
    exit $ST_UK
fi
if (echo ${nretry} | grep -v -e "^$" -e "^[0-9]*$" | grep -v grep \
        | grep -v ${PROGNAME} >/dev/null) && [ "X${nretry}" != 'Xanyport' ]; then
    echo "Invalid value: '${nretry}' for option -n/--nretry. Possible values:" \
         "positive integer"
    exit $ST_UK
fi
###########################################

# Global Variables
LOCK_FILENAME="/tmp/._restart_service_${servicename}_1855.lock"
TIMEOUT='120'                                        # 120 seconds
LISTENING='0'
PARTIALLY_LISTENING='1'
NOT_LISTENING='2'
NOT_CONFIGURED='3'
RUNNING='0'
PARTIALLY_RUNNING='1'
NOT_RUNNING='2'
exit_status=${ST_OK}

if [ -f ${LOCK_FILENAME} ]; then
    last_timestamp=$(tail -n 1 ${LOCK_FILENAME})
    current_timestamp=$(date +%s)
    delay=$(expr ${current_timestamp} - ${last_timestamp} | grep "^[0-9]*$" \
            || echo ${TIMEOUT}9 )
    if [ ${delay} -lt ${TIMEOUT} ]; then
        echo "UNKNOWN - The script is already running !"
        exit ${ST_UK}
    fi
fi
# Add current timestamp in lockfile
date +%s > $LOCK_FILENAME

## Set port type filter ##
if [ "X${connectiontype}" = 'Xtcp' ]; then
    type_filter='t'
elif [ "X${connectiontype}" = 'Xudp' ]; then
    type_filter='u'
elif [ "X${connectiontype}" = 'Xtcp,udp' ]; then
    type_filter='tu'
else
    type_filter='tu'
fi


check_port() {
    if [ "X${ports}" = "Xanyport" ]; then
        netstat -ln${type_filter} | grep "^.*${ports}.*$" >/dev/null
        if [ $? -ne 0 ]; then
            echo "${NOT_LISTENING}"
        else
            echo "${LISTENING}"
        fi
    else
        TEMP_PORT_CHECK_FILE="/tmp/._restart_service_${servicename}_${RANDOM}.port"
        echo '' > ${TEMP_PORT_CHECK_FILE}
        echo ${ports} | tr ',' '\n' | while read port_no; do
            if [ "X${port_no}" = "X" ]; then
                continue
            fi
            message=$(cat ${TEMP_PORT_CHECK_FILE} | sed 's/^ *//g' | sed 's/ *$//g')

            netstat -ln${type_filter} | tr -s " " | cut -d " " -f 4 \
                | grep ":$port_no$" >/dev/null
            if [ $? -ne 0 ]; then
                if [ "X${message}" = "X" ]; then
                    echo ${NOT_LISTENING} > ${TEMP_PORT_CHECK_FILE}
                elif [ "X${message}" = "X${LISTENING}" ]; then
                    echo ${PARTIALLY_LISTENING} > ${TEMP_PORT_CHECK_FILE}
                fi
            else
                if [ "X${message}" = "X" ]; then
                    echo ${LISTENING} > ${TEMP_PORT_CHECK_FILE}
                elif [ "X${message}" = "X${NOT_LISTENING}" ]; then
                    echo ${PARTIALLY_LISTENING} > ${TEMP_PORT_CHECK_FILE}
                fi
            fi
        done
        message=$(cat ${TEMP_PORT_CHECK_FILE} | sed 's/^ *//g' | sed 's/ *$//g')
        if [ "X${message}" = "X" ]; then
            echo "${NOT_CONFIGURED}"
        else
            echo "${message}"
        fi
        rm -f ${TEMP_PORT_CHECK_FILE}
    fi
}


check_process() {
    TEMP_PROCESS_CHECK_FILE="/tmp/._restart_service_${servicename}_${RANDOM}.process"
    echo '' > ${TEMP_PROCESS_CHECK_FILE}
    echo ${grepnames} | tr ',' '\n' | while read grep_string; do
        if [ "X${grep_string}" = "X" ]; then
            continue
        fi
        message=$(cat ${TEMP_PROCESS_CHECK_FILE} | sed 's/^ *//g' | sed 's/ *$//g')
        ps aux | grep "${grep_string}" | grep -v grep | grep -v ${PROGNAME} \
            >/dev/null
        if [ $? -ne 0 ]; then
            if [ "X${message}" = "X" ]; then
                echo ${NOT_RUNNING} > ${TEMP_PROCESS_CHECK_FILE}
            elif [ "X${message}" = "X${RUNNING}" ]; then
                echo ${PARTIALLY_RUNNING} > ${TEMP_PROCESS_CHECK_FILE}
            fi
        else
            if [ "X${message}" = "X" ]; then
                echo ${RUNNING} > ${TEMP_PROCESS_CHECK_FILE}
            elif [ "X${message}" = "X${NOT_RUNNING}" ]; then
                echo ${PARTIALLY_RUNNING} > ${TEMP_PROCESS_CHECK_FILE}
            fi
        fi
    done
    message=$(cat ${TEMP_PROCESS_CHECK_FILE} | sed 's/^ *//g' | sed 's/ *$//g')
    if [ "X${message}" = "X" ]; then
        echo "UNKNOWN - invalid grepnames argument: '${grepnames}'. Script" \
             " error"
        exit ${ST_UK}
    else
        echo "${message}"
    fi
    rm -f ${TEMP_PROCESS_CHECK_FILE}
}


kill_running_service() {
    TEMP_KILL_SERVICE_FILE="/tmp/._restart_service_${servicename}_${RANDOM}.kill.service"
    echo '' > ${TEMP_KILL_SERVICE_FILE}
    if echo "${servicename}" | grep -v "^\s*$" >/dev/null; then
        ps aux | grep "${servicename}" | grep -v grep | grep -v ${PROGNAME} \
        | tr -s " " | cut -d " " -f 2 | while read pid
        do
            kill -9 ${pid} >/dev/null || true
            echo '[Killed service]' > ${TEMP_KILL_SERVICE_FILE}
        done
    fi
    if [ "X${service_kill_message}" = 'X' ]; then
        service_kill_message=$(cat ${TEMP_KILL_SERVICE_FILE} | sed 's/^ *//g' | sed 's/ *$//g')
    fi
    rm -f $TEMP_KILL_SERVICE_FILE
}


kill_running_process_in_port() {
    TEMP_PORT_KILL_FILE="/tmp/._restart_service_${servicename}_${RANDOM}.kill.port"
    echo "${ports}" | tr ',' '\n' | while read port_no; do
        if [ "X${port_no}" = "X" ]; then
            continue
        fi
        netstat -lnp${type_filter} | grep -v grep | grep -v ${PROGNAME} \
        | tr -s " " | cut -d " " -f 4,7 | grep ":${port_no} .*$" \
        | cut -d" " -f 2 | cut -d"/" -f 1 | while read pid
        do
            kill -9 ${pid} >/dev/null || true
            echo '[Killed process in Port]' > ${TEMP_PORT_KILL_FILE}
        done
    done
    if [ "X${port_kill_message}" = 'X' ]; then
        port_kill_message=$(cat ${TEMP_PORT_KILL_FILE} | sed 's/^ *//g' | sed 's/ *$//g')
    fi
    rm -f $TEMP_PORT_KILL_FILE
}


restart_service() {
    restart_command="/etc/init.d/${servicename} restart"
    if echo "${killservice}" | tr '[:upper:]' '[:lower:]' \
            | grep -e "^true$" -e "^yes$" -e "^y$" >/dev/null; then
        kill_running_service
        kill_running_service
    fi
    if echo "${force}" | tr '[:upper:]' '[:lower:]' \
            | grep -e "^true$" -e "^yes$" -e "^y$" >/dev/null; then
        ${restart_command} >/dev/null || true
        executed_restart_command='true'
        sleep "${waitforport}"
    fi
    exit_status=${ST_CR}
    for i in $(seq ${nretry}); do
        port_result="$(check_port)"
        process_result="$(check_process)"
        if ( [ "X${port_result}" = "X${LISTENING}" ] \
                || [ "X${port_result}" = "X${NOT_CONFIGURED}" ] ) \
                && [ "X${process_result}" = "X${RUNNING}" ]; then
            if [ "X${exit_status}" != "X${ST_WR}" ]; then
                exit_status=${ST_OK}
            fi
            break
        elif ([ "X${port_result}" = "X${LISTENING}" ] \
                || [ "X${port_result}" = "X${PARTIALLY_LISTENING}" ] ) \
                && ( [ "X${process_result}" = "X${NOT_RUNNING}" ] \
                ||   [ "X${process_result}" = "X${PARTIALLY_RUNNING}" ] ); then
            kill_running_process_in_port
            exit_status=${ST_WR}
        fi
        ${restart_command} >/dev/null || true
        executed_restart_command='true'
        sleep "${waitforport}"
    done
}

###########################################################################
######################## EXECUTE THE TEST #################################
###########################################################################

restart_service

rm -f $LOCK_FILENAME
if [ "X${executed_restart_command}" != 'Xtrue' ]; then
    echo "OK - ${service_kill_message}${port_kill_message} '${servicename}'" \
         " is already running. Not restarted"
    exit ${ST_OK}
elif [ "X${exit_status}" = "X${ST_OK}" ]; then
    echo "OK - ${service_kill_message}${port_kill_message} '${servicename}'" \
         " restarted successfully"
    exit ${ST_OK}
elif [ "X${exit_status}" = "X${ST_WR}" ]; then
    echo "WARNING - ${service_kill_message}${port_kill_message}" \
        " '${servicename}' restarted successfully with warnings"
    exit ${ST_WR}
elif [ "X${exit_status}" = "X${ST_CR}" ]; then
    echo "CRITICAL - ${service_kill_message}${port_kill_message}Proper" \
         " restart of service '${servicename}' failed"
    exit ${ST_CR}
else
    echo "UNKNOWN - ${service_kill_message}${port_kill_message}" \
         " unknown result for restart of '${servicename}' service"
    exit ${ST_UK}
fi
