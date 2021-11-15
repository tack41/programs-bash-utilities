#==========
# Usage:
#   $0 [local2remote]
#
# Description:
#   Copy file from local/remote to remote local by accessing remote with cifs.
#
# Options:
#   loca2remote    If this option is specified, it copies from local to remote.
#                  Otherwise, it copies from remote to local.
# 
# External variables(Required):
#   REMOTE_DIR: Remote target directory path
#   LOCAL_MNT: Mount point to access remote target directory
#   LOCAL_DIR: local target directory path
#   FILES_TO_COPY: File names to copy.If there are multiple files, specify them separated by commas.
# External variables(Optional):
#   CIFS_ID: ID to access remote directory. If not specified, it access without authentication.
#   CIFS_PW: Password to access remote directory.
#   DEBUG: If true, output debug message.
#==========
function cifs_copy(){
  local isDebug=false
  if [ "${DEBUG-}" = "true" ]; then
    isDebug=true
  fi


  rc=0
  programSection=1
  $isDebug && echo "[${programSection}. Decide direction to copy from first argument]"
  local fromLocalToRemote=false
  if [ $# -ge 1 ]; then
    if [ "$1" = "local2remote" ]; then
      fromLocalToRemote=true
    fi
  fi
  $isDebug && echo "fromLocalToRemote: $fromLocalToRemote"


  programSection=2
  $isDebug && echo "[${programSection}. Check wheter REMOTE_DIR environmental variable defined]"
  if [ -z "${REMOTE_DIR-}" ]; then
    echo "Environmental variable REMOTE_DIR wasn't defined" 1>&2
    return $programSection
  fi
  local remoteDirectory=$REMOTE_DIR
  $isDebug && echo "REMOTE_DIR: $remoteDirectory"


  programSection=3
  $isDebug && echo "[${programSection}. Check wheter LOCAL_MNT environmental variable defined]"
  if [ -z "${LOCAL_MNT-}" ]; then
    echo "Environmental variable LOCAL_MNT wasn't defined" 1>&2
    return $programSection
  fi
  local localMountPoint=$LOCAL_MNT
  $isDebug && echo "LOCAL_MNT: $localMountPoint"


  programSection=4
  $isDebug && echo "[${programSection}. Check wheter LOCAL_DIR environmental variable defined]"
  if [ -z "${LOCAL_DIR-}" ]; then
    echo "Environmental variable LOCAL_DIR wasn't defined" 1>&2
    return $programSection
  fi
  local localDirectory=$LOCAL_DIR
  $isDebug %% echo "LOCAL_DIR: $localDirectory"


  programSection=5
  $isDebug && echo "[${programSection}. Check wheter FILES_TO_COPY environmental variable defined]"
  local filesToCopy=()
  if [ -z "${FILES_TO_COPY-}" ]; then
    echo "Environmental variable FILES_TO_COPY wasn't defined" 1>&2
    return $programSection
  else
    IFS=', ' read -r -a filesToCopy <<< $FILES_TO_COPY
  fi
  $isDebug && echo "FILES_TO_COPY: ${filesToCopy[@]}"


  programSection=6
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
  $isDebug && echo "cifsCredentialSpecified: $cifsCredentialSpecified, CIFS_ID: $cifsID, CIFS_PW: $cifsPassword"


  programSection=7
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


  programSection=8
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


  programSection=9
  $isDebug && echo "[${programSection}. Mount remote directory]"
  if $cifsCredentialSpecified; then
    mount -t cifs -o username=${cifsID},password=${cifsPassword},vers=3.0,sec=ntlmsspi,domain=${cifsDomain} $remoteDirectory $localMountPoint 1>/dev/null &&:
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


  programSection=10
  $isDebug && echo "[${programSection}. Copy files]"
  for fileToCopy in "${filesToCopy[@]}"
  do
    if $fromLocalToRemote; then
      cp ${localDirectory}/${fileToCopy} ${localMountPoint}/${fileToCopy} 1>/dev/null &&:
      rc=$?
    else
      cp ${localMountPoint}/${fileToCopy} ${localDirectory}/${fileToCopy} 1>/dev/null &&:
      rc=$?
    fi
    if [[ $rc -ne 0 ]]; then
      echo "Failed to copy '${fileToCopy}': $rc" 1>&2
      return $programSection
    else
      $isDebug && echo "Succeeded to copy '${fileToCopy}"
    fi
  done


  programSection=11
  $isDebug && echo "[${programSection}. Unount Remote directory]"
  umount $localMountPoint 1>/dev/null &&:
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "Failed to unmount remote directory: $rc" 1>&2
    return $programSection
  else
    $isDebug && echo "Succeeded to unmount remote directory"
  fi

  return 0
}
