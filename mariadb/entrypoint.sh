#!/bin/bash
cd /home/container || { echo "Could not change to /home/container directory! Exiting."; exit 1; }


# Check for end-of-life marker
if [ "${YOLK_EOL_NAG_WARNING+x}" ]; then
	echo "======================================================================"
	echo "DEPRECATION WARNING:"
	echo "This version of MariaDB has been marked as end-of-life."
	echo "Please migrate to a supported version as soon as possible to ensure"
	echo "continued security updates and support."
	echo "This image will be removed/disabled in the near future."
	echo "======================================================================"

	echo "Execution will continue in ${YOLK_EOL_NAG_DELAY:-10} seconds..."
	sleep "${YOLK_EOL_NAG_DELAY:-10}"
fi


# Make internal Docker IP address available to processes.
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Determine correct executables to use
if which mariadbd-safe > /dev/null ; then
	MARIADBD_EXECUTABLE="mariadbd"
	MARIADB_INSTALLDB_EXECUTABLE="mariadb-install-db"
	MARIADB_UPGRADE_EXECUTABLE="mariadb-upgrade"
	MARIADB_ADMIN_EXECUTABLE="mariadb-admin"
	MARIADB_EXECUTABLE="mariadb"

else
	MARIADBD_EXECUTABLE="mysqld"
	MARIADB_INSTALLDB_EXECUTABLE="mysql_install_db"
	MARIADB_UPGRADE_EXECUTABLE="mysql_upgrade"
	MARIADB_ADMIN_EXECUTABLE="mysqladmin"
	MARIADB_EXECUTABLE="mysql"
fi

export MARIADB_EXECUTABLE


# Setup NSS Wrapper - Some valiables already set in the Dockerfile
USER_ID=$(id -u)
GROUP_ID=$(id -g)
export USER_ID GROUP_ID
envsubst < /passwd.template > "${NSS_WRAPPER_PASSWD}"
envsubst < /group.template > "${NSS_WRAPPER_GROUP}"
if [ -f  /usr/lib/libnss_wrapper.so ]; then
	export LD_PRELOAD=/usr/lib/libnss_wrapper.so
else
	export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libnss_wrapper.so
fi


# Ensure required folders exist
mkdir -p "$HOME/run/mysqld"
mkdir -p "$HOME/log/mysql"
mkdir -p "$HOME/mysql"


# Only run install db if the database is not setup
if [ ! -f "$HOME/mysql/user.frm" ] ; then
	echo "Database not setup - running initial setup"
	$MARIADB_INSTALLDB_EXECUTABLE --datadir="$HOME/mysql"
fi


echo "Starting MariaDB server in recovery mode..."
$MARIADBD_EXECUTABLE --datadir="$HOME/mysql" &
PID=$!

echo "Waiting for MariaDB to start/recover..."

while true; do
    if $MARIADB_ADMIN_EXECUTABLE ping --silent > /dev/null 2>&1 ; then
        echo "MariaDB is ready."
        break
    fi

    if ! kill -0 "$PID" 2>/dev/null; then
        echo "MariaDB process exited unexpectedly."
        wait "$PID"
        exit 1
    fi

    echo "MariaDB is still recovering..."
    sleep 10
done

# Check if an upgrade is needed
if $MARIADB_UPGRADE_EXECUTABLE -u container --check-if-upgrade-is-needed --silent ; then
	echo "Running database upgrade..."
	$MARIADB_UPGRADE_EXECUTABLE -u container
	echo "Database upgrade completed."
else
	echo "No database upgrade needed."
fi


# Replace Startup Variables
MODIFIED_STARTUP=$(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
eval ${MODIFIED_STARTUP}

# Incase we reach here without the server being asked to stop, ask it now
echo "Stopping MariaDB server..."
$MARIADB_ADMIN_EXECUTABLE -u container shutdown --silent

# Wait for the server to stop
wait $PID > /dev/null 2>&1
