#==========
# Usage:
#   $0 
#
# Description:
#   Mount CIFS directory.
#
# External variables(Required):
#   REMOTE_DIR: Remote target directory path
#   LOCAL_MNT: Mount point to access remote target directory
# External variables(Optional):
#   CIFS_ID: ID to access remote directory. If not specified, it access without authentication.
#   CIFS_PW: Password to access remote directory.
#   CIFS_DOMAIN: Active Directory domain name.
#   DEBUG: If true, output debug message.
#==========
function cifs_mount(){
  local isDebug=false
  if [ "${DEBUG-}" = "true" ]; then
    isDebug=true
  fi


  rc=0
  programSection=1
  $isDebug && echo "[${programSection}. Check wheter REMOTE_DIR environmental variable defined]"
  if [ -z "${REMOTE_DIR-}" ]; then
    echo "Environmental variable REMOTE_DIR wasn't defined" 1>&2
    return $programSection
  fi
  local remoteDirectory=$REMOTE_DIR
  $isDebug && echo "REMOTE_DIR: $remoteDirectory"


  programSection=2
  $isDebug && echo "[${programSection}. Check wheter LOCAL_MNT environmental variable defined]"
  if [ -z "${LOCAL_MNT-}" ]; then
    echo "Environmental variable LOCAL_MNT wasn't defined" 1>&2
    return $programSection
  fi
  local localMountPoint=$LOCAL_MNT
  $isDebug && echo "LOCAL_MNT: $localMountPoint"


  programSection=3
  $isDebug && echo "[${programSection}. Check wheter CIFS_ID,CIFS_PW,CIFS_DOMAIN environmental variable defined]"
  local cifsID=""
  local cifsPassword=""
  local cifsDomain=""
  local cifsCredentialSpecified=false
  if [ -n "${CIFS_ID-}" ]; then
    cifsCredentialSpecified=true
    cifsID=$CIFS_ID
    if [ -n "${CIFS_PW-}" ]; then
      cifsPassword=$CIFS_PW
    fi
    if [ -n "${CIFS_DOMAIN-}" ]; then
      cifsDomain=$CIFS_DOMAIN
    fi
  fi
  $isDebug && echo "cifsCredentialSpecified: ${cifsCredentialSpecified}, CIFS_ID: ${cifsID}, CIFS_PW: ${cifsPassword}, CIFS_DOMAIN: ${cifsDomain}"


  programSection=4
  $isDebug && echo "[${programSection}. Create mount point directory if not exists]"
  if [ ! -d $localMountPoint ]; then
    mkdir -p $localMountPoint 1>/dev/null &&:
    rc=$?
    if [[ $rc -ne 0 ]]; then
      echo "Failed to create mount point directory'${localMountPoint}': $rc" 1>&2
      return $programSection
    else
      $isDebug && echo "Succeeded to create mount point directory"
    fi
  else
    $isDebug && echo "Mount point directory alread exists. Skipping: ${localMountPoint}"
  fi


  programSection=5
  $isDebug && echo "[${programSection}. Unmount directory if already mounted]"
  mount | grep $localMountPoint &&:
  mounted=$?
  if [ $mounted -eq 0 ]; then
    umount $localMountPoint 1>/dev/null &&:
    rc=$?
    if [[ $rc -ne 0 ]]; then
      echo "Failed to unmount point directory '${localMountPoint}': $rc" 1>&2
      return $programSection
    else
      $isDebug && echo "Succeeded to unmount point directory"
    fi
  else
    $isDebug && echo "Directory was not mounted. Skipping: ${localMountPoint}}"
  fi


  programSection=6
  $isDebug && echo "[${programSection}. Mount remote directory]"
  if $cifsCredentialSpecified; then
    mount -t cifs -o username=${cifsID},password=${cifsPassword},sec=ntlmsspi,vers=3.0,domain=${cifsDomain} $remoteDirectory $localMountPoint 1>/dev/null &&:
    rc=$?
  else
    mount -t cifs $remoteDirectory $localMountPoint 1>/dev/null &&:
    rc=$?
  fi 
  if [[ $rc -ne 0 ]]; then
    echo "Failed to mount remote directory: $rc" 1>&2
    return $programSection
  else
    $isDebug && echo "Succeeded to mount remote directory"
  fi


  return 0
}
