## Introduction

This is a docker container to build an ssh jump host that records login sessions
in order to replay them live or later on. It is based on general ssh hopping
dtgilles/sshgw.

## How to use it

 * in general:
   - you SHOULD activate ssh agent forwarding by setting environment variable

       SSHD_OPTS="-o AllowAgentForwarding=yes"

   - you SHOULD NOT activate tcp or x11 forwarding (deactivated by default)
   - you SHOULD review folloging variables:
     - CheckScriptSeconds:    interval to check / handle script logs
     - PossibleScripts:       number of prepared script logs
     - LoginScriptLogDir:     location of persistent session protocolls (this should be a persistent mount)
   - you SHOULD set following variables (see dtgilles/sshgw), e.g.:

       UserDir=/data/user
       HostKeys=/data/sshd

   - you COULD set variable SleepyTask to update user + keys or cleanup script-logs
 * for each login user you...:
   - ...should set command to "/usr/local/bin/script_login -u %u" in key_dir/_keyprefix
   - ...should persist keys in $Userdir/<user>/_keydir/<keyname>.pub
   - ...should not set login shell -- keep default (bash)
   - ...could allow agent forwarding
   - ...should neighter allow X11 forwarding nor PortForwarding 
   - ...should review the script-logs regularly / ideally monitor them

