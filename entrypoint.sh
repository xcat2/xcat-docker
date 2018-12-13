#! /bin/bash

is_ubuntu=$(test -f /etc/debian_version && echo Y)
[[ -z ${is_ubuntu} ]] && logadm="root:" || logadm="syslog:adm"
chown -R ${logadm} /var/log/xcat/

#/dev/loop0 and /dev/loop1 will be occupied by docker by default
#create a loop device if there is no free loop device inside container
losetup -f >/dev/null 2>&1 || (
  maxloopdev=$(losetup -a|awk -F: '{print $1}'|sort -f -r|head -n1);
  maxloopidx=$[${maxloopdev/#\/dev\/loop}];
  mknod /dev/loop$[maxloopidx+1] -m0660 b 7 $[maxloopidx+1] && echo "no free loop device inside container,created a new loop device /dev/loop$[maxloopidx+1]..."
)

if [[ -e "/etc/NEEDINIT"  ]]; then
    echo "initializing xCAT Tables..."
    xcatconfig -d

    echo "initializing networks table..."
    tabprune networks -a
    makenetworks

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
