## Introduction

This is a simple docker container to build an ssh gateway or
hopping station.

## Usecases

Running this docker container you may support following use cases:

 * "forwarding only" gateway without login prompt and restrictions per user
   - mount /etc/user via external volume
   - set login shell to "/usr/local/bin/LoginSleep" for each user
   - write users firewall restrictions into users key file -- see 
	sshd_config man page to get more information about
          - PermitOpen="ip:port"
          - no-pty
          - ...
   - set global variable "LoginSleep" to configure session timeout
   - set global variable ```SSHD_OPTS="-o AllowTcpForwarding=yes"``` (other options could be appended)
 * special api host
   - create your own api command (e.g. shell or python script)
   - mount /etc/user via external volume and set this api command as login shell
   - more than one key per user are supported -- see below
 * run a "classic hopping station"
   - mount /data via external volume
   - set $HostKeys to     "/data/host-keys"
	here the private ssh host keys are persisted - restrict access!
   - set $HomeBase to     "/data/home"
	here the user home directories are persisted
   - set $UserDir to      "/data/user"
     this structure defines which users have to be created at startup and how
 * use this container to build other stuff on top, e.g. a version control system
   - create users svn and git via Dockerfile
   - install needed software (git and subversion) and configure it
   - persist host keys and home base via external volume and set $HomeBase / $HostKeys
   - keep /etc/users empty (fast startup)

Important for all cases:

* use variable SSHD_OPTS to change specific options
* Startup takes more time the more users have to be created.
* Startup time prolongs (and security is reduced) if ssh host key is not persistent -- so $HostKey is strongly recommended.
* If you use persistent user homes it is strongly recommended to set their uids.


## Configuration / features

You can control containers behaviour using following environment variables:

* RootKey:	this key will be distributed to root
* UserDir:	this directory describes the user to create at startup time
		and their properties (see below) -- default is /etc/user
* HomeBase:	is the home directory for the created users -- default is /home
* HostKeys:	is the place/directory of ssh host keys (in order to make them
		persistent) -- default is /etc/ssh
* LoginSleep:	if login shell /usr/local/bin/LoginSleep is used for some users
		this variable sets the global session timeout -- default is 1 hour
* SleepyTask:	there is one task that I could run for you (after sleepng X seconds)
		-- regularly:  e.g. >>60  /root/bin/sync_config.sh<<
		waits 60 seconds and starts a config synchronization script,
		waits 60 seconds and starts a config synchronization script,
		waits 60 seconds and starts a config synchronization script,
		...

$UserDir is used to define the users that have to be accessible via ssh and 
their parameters - each of that in a separate file:

    "$UserDir/<user>/key"		# key file (in openssh format)
    "$UserDir/<user>/uid"		# uid of the user (only a number)
    "$UserDir/<user>/shell"		# name of the login shell (has to exist)

The files uid and shell are optional while key file could be substituted by a directory
"key_build" with possibly more than one key inside an a prefix definition for each key:

    "$UserDir/<user>/key_build/"
    "$UserDir/<user>/key_build/subuser1.pub"	# key file (in openssh format)
    "$UserDir/<user>/key_build/subuser2.pub"	# key file (in openssh format)
    "$UserDir/<user>/key_build/_keyprefix"	# prefix for each key (see below)
    "$UserDir/<user>/uid"		# uid of the user (only a number)
    "$UserDir/<user>/shell"		# name of the login shell (has to exist)

If "_keyprefix" has a %u inside it will be substituted by name of the subuser, e.g.
"_keyprefix" could look like ```nopty,command="/path/to/api.script %u"```.
So if if "subuser1" login via ssh he will call ```api.script``` which gets ```subuser1```
as command line parameter and so could (for instance) show callers permissions. (Keep in mind: command line parameter of the api caller are stored by ssh in variable ```$SSH_ORIGINAL_COMMAND```.

## For Developers

...who like to extend this docker image, you may create files named

     /entry.add.*.sh

These files are sourced during startup right before starting sshd. It
is convenient to enforce correct start order name the scripts like 

     /entry.add.01-first-script.sh
     /entry.add.02-another-script.sh

