#!/bin/bash
[ "$1" = -x ] && shift && set -x
##### global variables
##### UserDir  (default is /etc/user)
##### HomeBase (default is /home)
##### HostKeys (default is /etc/ssh, -- if there are no keys, they will be generated)
##### LoginSleep        time to sleep, executing login shell "LoginSleep"
#####                   default=3600
##### SSHD_OPTS         here you can define additional options for ssh daemon
##### RootKey           here you can define one initial root key
##### LOGFILE           defines absolute path of logfile (realized by sshd option -E)
#####                   if not set (default) regarding sshd option is "-e"
#
#  $UserDir could be external mounted directory
#  using this dir you can simply define the users
#  that have to be accessible via ssh and
#  you may define some of their parameters
#  like uid and so on....:
#
#  "$UserDir/<user>/key"	key file (in openssh format)
#  "$UserDir/<user>/uid"	uid of the user (only a number)
#  "$UserDir/<user>/shell"	name of the login shell (has to exist)
#  "$UserDir/<user>/iptables"	iptables rules (for definition see your iptables script)
UserDir="${UserDir:-/etc/user}"
HomeBase="${HomeBase:-/home}"
HostKeys="${HostKeys:-/etc/ssh}"
LoginSleep="${LoginSleep:-3600}"

echo "LoginSleep=$LoginSleep" >/etc/default/LoginSleep
if [ "$RootKey" != "" ]
   then
      mkdir -p              /root/.ssh
      (echo "$RootKey"; cat /root/.ssh/authorized_keys 2>/dev/null) | sort -u > /tmp/root.key || exit 2
      cat /tmp/root.key   > /root/.ssh/authorized_keys             && rm   -f   /tmp/root.key
   fi
if [ -z "$LOGFILE" ]				##### if variable is not set
   then
      SSHD_OPTS="-e ${SSHD_OPTS}"		##### then log to `docker logs`
   else
      SSHD_OPTS="-E ${LOGFILE} ${SSHD_OPTS}"	##### else use the given Logfile
      mkdir -p "${LOGFILE%/*}"			##### and create needed log directory
   fi
if [ "${SleepyTask}" != "" ]
   then
      (
         read sec task <<< "$SleepyTask"
         [ "${sec#*[^0-9]}" = "$sec" ] || exit 4 ##### sec must be the time to sleep (in seconds)
         while sleep "$sec"                      ##### this is an endless loop:
             do                                  #####  - sleep a while...
                eval "$task"                     #####  - ...and execute a single task
             done
      ) &
   fi

case "$1"
   in
      ""|sshd)  : ;;
      *)        exec $*;;
   esac

# check for keyfiles // copy or generate them
# append the list of keys to sshd_config
hostkeys=`ls "${HostKeys}"/*_key 2>/dev/null`
if [ "${#hostkeys}" = 0 ]
   then
      dpkg-reconfigure -f noninteractive openssh-server
      if [ "${HostKeys}" != /etc/ssh ]
         then
            cp -p /etc/ssh/*_key     "${HostKeys}/."
            cp -p /etc/ssh/*_key.pub "${HostKeys}/."
         fi
      hostkeys=`ls "${HostKeys}"/*_key`
   fi
sed -i /^HostKey/d  /etc/ssh/sshd_config
for f in ${hostkeys}
   do
      echo "HostKey $f"
   done \
>> /etc/ssh/sshd_config

##### if there are some users defined in $UserDir
##### then create them (if they aren't already existing)
if [ -d "$UserDir" ]
   then
      [ -n "$HomeBase"         ] &&    home="-b $HomeBase"
      for u in $(ls "$UserDir")
         do
            d="$UserDir/$u"
            [ -f "$d/key"      ]          || continue
	    getent passwd "$u" >/dev/null && continue
	    uid=""
	    shell=""
	    [ -f "$d/uid"      ] &&     uid="-u  `cat $d/uid`"
	    [ -f "$d/shell"    ] &&   shell="-s  `cat $d/shell`"
	    [ -f "$d/Groups"   ] &&  Groups="-G  `cat $d/Groups`"
            useradd -g ssh $uid $shell $home -m "$u"
            mkdir -p "$HomeBase/$u/.ssh"
            cp "$d/key" "$HomeBase/$u/.ssh/authorized_keys"
            chmod 755   "$HomeBase/$u/.ssh"
            chmod 644   "$HomeBase/$u/.ssh/authorized_keys"
         done
   fi

##### if there is an iptables script definned, then call it and send it to background
if [ -f "$IpTables" ] && [ -x "$IpTables" ]
   then
      "$IpTables" start &
   fi

[ -f /etc/default/ssh  ] && source /etc/default/ssh
[ -f /etc/defaults/ssh ] && source /etc/defaults/ssh   ##### for compatibility purposes
##### final destination
exec /usr/sbin/sshd -D ${SSHD_OPTS}
