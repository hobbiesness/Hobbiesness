#!/bin/sh

SLING_HOME=/opt/bitnami/apache-sling
SLING_BINARY=/opt/bitnami/apache-sling/org.apache.sling.launchpad-6-standalone.jar
SLING_PID=/opt/bitnami/apache-sling/sling.pid
export SLING_PID
SLING_STATUS=""
ERROR=0
PID=""

cd $SLING_HOME

start_sling() {
    is_sling_running
    RUNNING=$?
    if [ $RUNNING -eq 1 ]; then
        echo "$0 $ARG: sling (pid $PID) already running"
    else
	rm -f $SLING_PID
	java -jar $SLING_BINARY &
	if [ $? -eq 0 ];  then
            echo "$0 $ARG: sling started"
            echo $! > $SLING_PID
	else
            echo "$0 $ARG: sling could not be started"
            ERROR=1
	fi
    fi
}

stop_sling() {
    is_sling_running
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        echo "$0 $ARG: $SLING_STATUS"
        exit
    fi
    kill -15 $PID
    sleep 2
    is_sling_running
    RUNNING=$?
    COUNTER=4
    while [ $RUNNING -ne 0 ] && [ $COUNTER -ne 0 ]; do
        COUNTER=`expr $COUNTER - 1`
        sleep 2
        is_sling_running
        RUNNING=$?
    done
    if [ $RUNNING -eq 0 ]; then
        echo "$0 $ARG: sling stopped"
        rm -f $SLING_PID
        sleep 3
    else
        echo "$0 $ARG: sling could not be stopped"
        ERROR=2
    fi
}

get_pid() {
    PID=""
    PIDFILE=$1
    # check for pidfile
    if [ -f $PIDFILE ] ; then
        PID=`cat $PIDFILE`
    fi
}

get_sling_pid() {
    get_pid $SLING_PID
    if [ ! $PID ]; then
        return
    fi
}

is_service_running() {
    PID=$1
    if [ "x$PID" != "x" ] && kill -0 $PID 2>/dev/null ; then
        RUNNING=1
    else
        RUNNING=0
    fi
    return $RUNNING
}

is_sling_running() {
    get_sling_pid
    is_service_running $PID
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        SLING_STATUS="sling not running"
    else
        SLING_STATUS="sling already running"
    fi
    return $RUNNING
}

cleanpid() {
    rm -f $SLING_PID
}

if [ "x$1" = "xstart" ]; then
    start_sling
    sleep 2
elif [ "x$1" = "xstop" ]; then
    stop_sling
    sleep 2
elif [ "x$1" = "xstatus" ]; then
    is_sling_running
    echo $SLING_STATUS
elif [ "x$1" = "xcleanpid" ]; then
    cleanpid
fi

exit $ERROR