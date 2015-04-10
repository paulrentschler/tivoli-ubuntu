#!/usr/bin/env bash
#
# Use the Vagrant virtual machine to convert the IBM Tivoli backup client
# software from RPM files to DEB files for installing on Ubuntu-based systems.
#

# define some constants
GITHUB_ISSUE_URL="http://www.github.com/paulrentschler"
IBM_CLIENT_DOWNLOAD_URL="http://www-01.ibm.com/support/docview.wss?uid=swg21239415"
TSM_VERSION_ID_STRING="TIVsm-API64-"
GSK_VERSION_ID_STRING="gskcrypt64-"

# define values for the DEBIAN/control files
MAINTAINER="Paul Rentschler <paul@rentschler.ws>"
TIV_API_DESC="the API - IBM Tivoli Storage Manager API"
TIV_BA_DESC="the Backup Archive client - IBM Tivoli Storage Manager Client"
GSK_CRYPT_DESC="IBM GSKit Cryptography Runtime"
GSK_SSL_DESC="IBM GSKit SSL Runtime With Acme Toolkit"






# install the Alien package for converting RPM packages to DEB format
apt-get update > /dev/null
apt-get install -y alien > /dev/null

# determine the filename of the RPM-based tar file
cd /vagrant
for filename in *.tar; do
    if [[ ! -e "$filename" ]]; then continue; fi
    rpm_tar_file=$filename
    break
done

# error if no RPM-based tar file could be found
if [ -z ${rpm_tar_file+x} ]; then
    echo "+--------------------------------------------------------------"
    echo "| ERROR:"
    echo "| No tar file with the RPM installation files could be found!"
    echo "|"
    echo "| You can fix this by:"
    echo "|   1. destroying the virtual machine by typing:"
    echo "|        vagrant destroy"
    echo "|   2. downloading the RPM-based client install files from:"
    echo "|        $IBM_CLIENT_DOWNLOAD_URL"
    echo "|   3. putting the downloaded tar file in this directory"
    echo "|   4. starting the process again by typing:"
    echo "|        vagrant provision"
    echo "+--------------------------------------------------------------"
    exit
fi

# indicate the tar file with the RPM files being used
echo "+--------------------------------------------------------------"
echo "| Creating DEBs out of the RPMs found in:"
echo "|   $rpm_tar_file"
echo "|"
echo "| Now would be a good time for a coffee break, this is going"
echo "| to take a few minutes to complete."
echo "+--------------------------------------------------------------"

# clean up a previous attempt before starting
if [[ -e /usr/local/src/tivoli ]]; then
    rm -rf /usr/local/src/tivoli
fi

# create a place to work
mkdir /usr/local/src/tivoli
chown vagrant:vagrant /usr/local/src/tivoli
cd /usr/local/src/tivoli

# untar the RPM files
cp /vagrant/$rpm_tar_file ./
tar -xvf $rpm_tar_file > /dev/null

# use Alien to unpack the RPM files
alien -g TIVsm-API64.x86_64.rpm > /dev/null 2&>1
alien -g TIVsm-BA.x86_64.rpm > /dev/null 2&>1
alien -g gskcrypt64-*.linux.x86_64.rpm > /dev/null 2&>1
alien -g gskssl64-*.linux.x86_64.rpm > /dev/null 2&>1

# get the version number for the TSM files (TIVsm-API64 and TIVsm-BA)
for filename in ${TSM_VERSION_ID_STRING}*; do
    if [[ ! -e "$filename" ]]; then continue; fi
    tsm_version=$filename
    break
done
if [ -z ${tsm_version+x} ]; then
    echo "+--------------------------------------------------------------"
    echo "| ERROR:"
    echo "| Could not determine the version number of the"
    echo "| TSM-related files!"
    echo "|"
    echo "| There should be a directory named something like:"
    echo "|   '${TSM_VERSION_ID_STRING}6.3.2'"
    echo "| in the /usr/local/src/tivoli directory."
    echo "|"
    echo "| Fixing this will require a change to the code, you can"
    echo "| fix the code yourself (pull requests appreciated) or "
    echo "| submit an issue here:"
    echo "|   $GITHUB_ISSUE_URL"
    echo "+--------------------------------------------------------------"
    exit
fi
tsm_version="${tsm_version/${TSM_VERSION_ID_STRING}/}"

# get the version number for the GSKit files (gskcrypt64 and gskssl64)
for filename in ${GSK_VERSION_ID_STRING}*; do
    if [[ ! -e "$filename" ]]; then continue; fi
    gsk_version=$filename
    break
done
if [ -z ${gsk_version+x} ]; then
    echo "+--------------------------------------------------------------"
    echo "| ERROR:"
    echo "| Could not determine the version number of the"
    echo "| GSKit-related files!"
    echo "|"
    echo "| There should be a directory named something like:"
    echo "|   '${GSK_VERSION_ID_STRING}8.0'"
    echo "| in the /usr/local/src/tivoli directory."
    echo "|"
    echo "| Fixing this will require a change to the code, you can"
    echo "| fix the code yourself (pull requests appreciated) or "
    echo "| submit an issue here:"
    echo "|   $GITHUB_ISSUE_URL"
    echo "+--------------------------------------------------------------"
    exit
fi
gsk_version="${gsk_version/${GSK_VERSION_ID_STRING}/}"

# rename the 'debian' directories to 'DEBIAN'
mv TIVsm-API64-${tsm_version}/debian TIVsm-API64-${tsm_version}/DEBIAN
mv TIVsm-BA-${tsm_version}/debian TIVsm-BA-${tsm_version}/DEBIAN
mv gskcrypt64-${gsk_version}/debian gskcrypt64-${gsk_version}/DEBIAN
mv gskssl64-${gsk_version}/debian gskssl64-${gsk_version}/DEBIAN

# add execute permissions to the postinst script
chmod 755 TIVsm-API64-${tsm_version}/DEBIAN/postinst
chmod 755 TIVsm-BA-${tsm_version}/DEBIAN/postinst
chmod 755 gskcrypt64-${gsk_version}/DEBIAN/postinst
chmod 755 gskssl64-${gsk_version}/DEBIAN/postinst

# fix the information in the ./DEBIAN/control files
cat > TIVsm-API64-${tsm_version}/DEBIAN/control <<EOL
Source: tivsm-api
Section: alien
Priority: extra
Maintainer: ${MAINTAINER}
Package: tivsm-api
Architecture: amd64
Depends:
Description: ${TIV_API_DESC}
Version: ${tsm_version}

EOL
cat > TIVsm-BA-${tsm_version}/DEBIAN/control <<EOL
Source: tivsm-ba
Section: alien
Priority: extra
Maintainer: ${MAINTAINER}
Package: tivsm-ba
Architecture: amd64
Depends:
Description: ${TIV_BA_DESC}
Version: ${tsm_version}

EOL
cat > gskcrypt64-${gsk_version}/DEBIAN/control <<EOL
Source: gskcrypt64
Section: alien
Priority: extra
Maintainer: ${MAINTAINER}
Package: gskcrypt64
Architecture: amd64
Depends:
Description: ${GSK_CRYPT_DESC}
Version: ${gsk_version}

EOL
cat > gskssl64-${gsk_version}/DEBIAN/control <<EOL
Source: gskssl64
Section: alien
Priority: extra
Maintainer: ${MAINTAINER}
Package: gskssl64
Architecture: amd64
Depends:
Description: ${GSK_SSL_DESC}
Version: ${gsk_version}

EOL

# create the DEB packages
dpkg -b TIVsm-API64-${tsm_version}
dpkg -b TIVsm-BA-${tsm_version}
dpkg -b gskcrypt64-${gsk_version}
dpkg -b gskssl64-${gsk_version}

# create the DEB packages filename
deb_tar_file=${rpm_tar_file/.tar/-ubuntu.tar.gz}

# tar and gzip the DEB packages for retrieval
tar -cz *.deb > /vagrant/${deb_tar_file}

# completion message
echo "+--------------------------------------------------------------"
echo "| Conversion COMPLETE!"
echo "|"
echo "| The DEB packages are in the file:"
echo "|   ${deb_tar_file}"
echo "|"
echo "| Happy installing!"
echo "+--------------------------------------------------------------"
