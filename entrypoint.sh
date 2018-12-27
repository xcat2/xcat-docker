#! /bin/bash

is_ubuntu=$(test -f /etc/debian_version && echo Y)
[[ -z ${is_ubuntu} ]] && logadm="root:" || logadm="syslog:adm"
chown -R ${logadm} /var/log/xcat/

if [[ -e "/etc/NEEDINIT"  ]]; then
    echo "initializing xCAT Tables..."
    xcatconfig -d

    echo "initializing networks table..."
    tabprune networks -a
    makenetworks

    echo "initializing loop devices..."
    # workaround for no loop device could be used by copycds
    for i in {0..7}
    do
        test -b /dev/loop$i || mknod /dev/loop$i -m0660 b 7 $i
    done

    rm -f /etc/NEEDINIT
fi


#restore the backuped db on container start to resume the service state
if [[ -d "/.dbbackup" ]]; then
        echo "xCAT DB backup directory \"/.dbbackup\" detected, restoring xCAT tables from /.dbbackup/..."
        restorexCATdb -p /.dbbackup/
        echo "finished xCAT Tables restore!"
fi

. /etc/profile.d/xcat.sh

cat /etc/motd
HOSTIPS=$(ip -o -4 addr show up|grep -v "\<lo\>"|xargs -I{} expr {} : ".*inet \([0-9.]*\).*")
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "welcome to Dockerized xCAT, please login with"
[[ -n "$HOSTIPS"  ]] && for i in $HOSTIPS; do echo "   ssh root@$i   "; done && echo "The initial password is \"cluster\""
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"


#read -p "press any key to continue..."
/bin/bash
