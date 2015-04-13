# Create Ubuntu install files for IBM Tivoli (TSM) Backup Client

IBM supports Debian-based Linux distributions (i.e., Debian, Ubuntu) on a
["best effort" basis with support limitations](http://www-01.ibm.com/support/docview.wss?uid=swg21417165)
but does not provide Debian-format installation packages.

There are several documents out there that explain the process of converting
the RPM packages IBM provides into DEB packages that will install on
Debian-based (i.e., Debian, Ubuntu) systems. To simplify the process, this
project provides a Vagrant-based Ubuntu virtual server that has all the
scripting necessary to convert the RPM-based client files downloaded from IBM
into DEB-based packages ready to install on Ubuntu.

**NOTE:** This has only been tested with the v6.3.2 client on Ubuntu 14.04 LTS.


## Requirements

* [VirtualBox](https://www.virtualbox.org/)
* [Vagrant](https://www.vagrantup.com/)
* [IBM TSM Backup Client RPMs](http://www-01.ibm.com/support/docview.wss?uid=swg21239415)

VirtualBox is a free virtualization software available for Windows, Mac OS X,
and Linux which will allow for the creation of a temporary Ubuntu machine on
your computer that will be used to convert the files.

Vagrant is a free system creation and configuration management application
available for Windows, Mac OS X, and Linux that allows for the scripted creation
of the temporary Ubuntu machine running under VirtualBox and for executing the
scripting that converts the RPM packages to DEB packages.


## Converting the client files

1. Download and install VirtualBox

1. Download and install Vagrant

1. Clone this repository into a directory on your computer

        git clone https://github.com/paulrentschler/tivoli-ubuntu

1. Download the TSM client files into the directory where the repository was cloned. The filename should be something similar to:

        6.3.2.0-TIV-TSMBAC-LinuxX86.tar

1. From the command line in the directory where the repository was cloned type:

        vagrant up

1. The temporary Ubuntu machine will be created and the client files converted. This takes a while (approx 5-15 minutes). When complete, there will be a new file in the directory where the repository was cloned who's filename should be something similar to:

        6.3.2.0-TIV-TSMBAC-LinuxX86-Ubuntu.tar.gz

1. This new file contains the TSM client files in DEB format. You can move this file somewhere else then issue the following command at the command line in the directory where the repository was cloned to delete the temporary Ubuntu machine:

        vagrant destroy

1. You can delete the repository directory as it is no longer needed.


### Converting additional client versions

If you want to convert additional client versions, don't issue the "vagrant
destroy" command but instead follow these steps:

1. Delete the *.tar and *.tar.gz files in the directory where the repository was cloned.

1. Download the new TSM client version into the directory where the repository was cloned.

1. From the command line in the directory where the repository was cloned type:

        vagrant provision

1. The existing Ubuntu machine will be used to convert these new client files. The process will not take as long as before. When complete, the new *.tar.gz file will be in the directory where the repository was cloned like before.


## Installing the DEB packages

With the DEB packages created, copy the file to the Ubuntu server you want to
install them on and decompress the file:

    cd /usr/local/src
    sudo mkdir tivoli
    cd tivoli
    cp ~/6.3.2.0-TIV-TSMBAC-LinuxX86-Ubuntu.tar.gz /usr/local/src/tivoli
    sudo tar -zxvf 6.3.2.0-TIV-TSMBAC-LinuxX86-Ubuntu.tar.gz

Then install the DEB packages:

    sudo dpkg -i TIVsm-API64-6.3.2.deb
    sudo dpkg -i TIVsm-BA-6.3.2.deb
    sudo dpkg -i gskcrypt64-8.0
    sudo dpkg -i gskssl64-8.0

The client is now installed in the _/opt/tivoli_ directory.

Tell linux where to find the Tivoli library files:

    sudo vi /etc/ld.so.conf.d/tivoli.conf

This creates a new file that should contain:

    /opt/tivoli/tsm/client/api/bin64
    /usr/local/ibm/gsk8_64/lib64

Then update the database:

    sudo ldconfig

Create the language symlink:

    cd /opt/tivoli/tsm/client/ba/bin
    sudo ln -s ../../lang/EN_US EN_US


### Test the installation

Executing:

    sudo dsmc

Should result in:

    ANS0990W Options file '/opt/tivoli/tsm/client/ba/bin/dsm.opt' could not be found. Default option values will be used.
    ANS1035S Options file '/opt/tivoli/tsm/client/ba/bin/dsm.sys' could not be found, or it cannot be read.


### Configuring the client

Create the _dsm.opt_ file:

    cd /opt/tivoli/tsm/client/ba/bin
    sudo cp dsm.opt.smp dsm.opt
    sudo vi dsm.opt

The file should contain the following:

    ************************************************************************
    * IBM Tivoli Storage Manager                                           *
    ************************************************************************
    * This file contains an option you can use to specify the TSM
    * server to contact if more than one is defined in your client
    * system options file (dsm.sys).  Copy dsm.opt.smp to dsm.opt.
    * If you enter a server name for the option below, remove the
    * leading asterisk (*).
    ************************************************************************

    Servername        <name of your TSM server>
    COMPRESSALWAYS    NO
    ARCHSYMLINKASFILE NO

    * Uncomment the next line to backup all local directories except what is excluded in tsm.exclude.list
    *DOMain            ALL-LOCAL

    * Uncomment the next lines to backup some key directories except waht is excluded in tsm.exclude.list
    *DOMain            /etc
    *DOMain            /var/log

Then create the _dsm.sys_ file:

    sudo cp dsm.sys.smp dsm.sys
    sudo vi dsm.sys

The file should contain the following:

    ************************************************************************
    * IBM Tivoli Storage Manager                                           *
    ************************************************************************
    * This file contains the minimum options required to get started
    * using TSM.  Copy dsm.sys.smp to dsm.sys. In the dsm.sys file,
    * enter the appropriate values for each option listed below and
    * remove the leading asterisk (*) for each one.
    *
    * If your client node communicates with multiple TSM servers, be
    * sure to add a stanza, beginning with the SERVERNAME option, for
    * each additional server.
    ************************************************************************

    Servername       <name of your TSM server>
    USERS            <username doing the backups>
    SCHEDLOGNAME     "/var/log/dsmsched.log"
    ERRORLOGNAME     "/var/log/dsmerror.log"
    INCLEXCL         /opt/tivoli/tsm/client/ba/bin/tsm.exclude.list
    TCPWINDOWSIZE    1024
    TCPBUFFSIZE      512
    COMPRESSION      YES
    PASSWORDDIR      /opt/tivoli/tsm/client/ba/bin/
    PASSWORDACCESS   GENERATE
    NODENAME         <FQDN of this machine>
    COMMmethod       TCPip
    TCPPort          1500
    TCPServeraddress <name of your TSM server>

Create the backup list of include/exclude files:

    sudo vi tsm.exclude.list

The file should contain roughly this list to backup the /backup and
/usr/local/scripts directories:

    ************************************************************************
    * IBM Tivoli Storage Manager                                           *
    *                                                                      *
    * Include/exclude file to specify what to backup (tsm.exclude.list)    *
    ************************************************************************
    *
    *  Lines starting with an asterisk (*) are comments.
    *  "..." means zero or more subdirectories.
    *  "*" means all files in a directory.
    *
    *  Statements are processed from the bottom of the file to the top.
    *  Files cannot be included from an Exclude.Dir path.
    *
    ************************************************************************

    * These are good exclusions for all linux servers
    EXCLUDE /opt/tivoli/tsm/client/ba/bin/dsmaudit.log
    EXCLUDE /opt/tivoli/tsm/client/ba/bin/dsmerror.log
    EXCLUDE /opt/tivoli/tsm/client/ba/bin/dsmsched.log
    EXCLUDE /opt/tivoli/tsm/client/ba/bin/dsmwebcl.log
    EXCLUDE /var/log/dsmaudit.log
    EXCLUDE /var/log/dsmerror.log
    EXCLUDE /var/log/dsmsched.log
    EXCLUDE /var/log/dsmwebcl.log
    EXCLUDE.DIR "/var/cache"


## Problems and/or improvements

If you run into a problem with the process,
[create an issue](https://github.com/paulrentschler/tivoli-ubuntu/issues)
on GitHub.

If you have an improvement or bug fix, pull requests are welcome.


## Credits

Special thanks to the following resources that were used in constructing the
conversion methodology for the scripts.

* [Basis for the entire process](http://www.rocko.me/?p=82)
* [Additional information on installing the DEB packages](http://open-systems.ufl.edu/ubuntu_client)
* [Assistance with the newer 6.3.x client versions](https://kb.berkeley.edu/page.php?id=27401)
