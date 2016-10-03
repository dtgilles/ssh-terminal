#!/bin/bash
[ "$1" = -x ] && shift && set -x
##### global variables
##### UserDir  (default is /etc/user)
##### HomeBase (default is /home)
##### LoginSleep        time to sleep, executing login shell "LoginSleep"
#####                   default=3600
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
#
#  The files uid and shell are optional and key file could be substituted by a directory
#  "key_build" with possibly more than one key inside an a prefix definition for each key:
#
#      "$UserDir/<user>/key_build/"
#      "$UserDir/<user>/key_build/subuser1.pub"    # key file (in openssh format)
#      "$UserDir/<user>/key_build/subuser2.pub"    # key file (in openssh format)
#      "$UserDir/<user>/key_build/_keyprefix"      # prefix for each key (see below)
#      "$UserDir/<user>/key_build/"        # key file (in openssh format)
#      "$UserDir/<user>/uid"               # uid of the user (only a number)
#      "$UserDir/<user>/shell"             # name of the login shell (has to exist)
#
#  If "_keyprefix" has a %u inside it will be substituted by name of the subuser, e.g.
#  "_keyprefix" could look like 'nopty,command="/usr/local/bin/show_app_permissions %u"'.
#  So if if either "subuser1" or "subuser2" login via ssh they will see their own
#  permissions, because of the personalized forced command.
#
UserDir="${UserDir:-/etc/user}"
HomeBase="${HomeBase:-/home}"

##### if there are some users defined in $UserDir
##### then create them (if they aren't already existing)
if [ -d "$UserDir" ]
   then
      [ -n "$HomeBase"         ] &&    home="-b $HomeBase"
      for u in $(ls "$UserDir")
         do
            d="$UserDir/$u"
            if [ -f "$d/key"      ]
               then
                  keyfile="$d/key"
               elif [ -d "$d/key_build" ]; then
                  keyfile=$(mktemp /tmp/key.$$.XXXXXXXXXX)
                  for f in "$d/key_build"/*.pub
                     do
                        subuser=$(basename "$f" .pub)
                        prefix=$(sed "s/%u/$subuser/g; s/$/ /" "$d/key_build/_keyprefix")
                        sed "/^ssh-/  s|^|${prefix# }|" "$f" >> $keyfile
                     done \
                  > $keyfile
               else
                  continue
               fi
	    if ! getent passwd "$u" >/dev/null
               then
	          uid=""
	          shell=""
	          [ -f "$d/uid"      ] &&     uid="-u  `cat $d/uid`"
	          [ -f "$d/shell"    ] &&   shell="-s  `cat $d/shell`"
	          [ -f "$d/Groups"   ] &&  Groups="-G  `cat $d/Groups`"
                  useradd -g ssh $uid $shell $home -m "$u"
               fi
            mkdir -p "$HomeBase/$u/.ssh"
            cp "$keyfile" "$HomeBase/$u/.ssh/authorized_keys"
            chmod 755     "$HomeBase/$u/.ssh"
            chmod 644     "$HomeBase/$u/.ssh/authorized_keys"
            if [ -d "$UserDir/$u/"priv ]
               then
                  cp "$UserDir/$u/"priv/id_* "$HomeBase/$u/.ssh"
                  chmod 600                  "$HomeBase/$u/.ssh/"id_*
                  chown "$u"                 "$HomeBase/$u/.ssh/"id_*
               fi
         done
      rm -f /tmp/key.$$.*
   fi
exit 0
