#==========
# Usage:
#   $0 
#
# Description:
#   Mount CIFS directory.
#
# External variables(Required):
#   LOCAL_MNT: Mount point to access remote target directory
# External variables(Optional):
#   DEBUG: If true, output debug message.
#==========
function cifs_unmount(){
  local isDebug=false
  if [ "${DEBUG-}" = "true" ]; then
    isDebug=true
  fi

  rc=0
  programSection=1
  $isDebug && echo "[${programSection}. Check wheter LOCAL_MNT environmental variable defined]"
  if [ -z "${LOCAL_MNT-}" ]; then
    echo "Environmental variable LOCAL_MNT wasn't defined" 1>&2
    return $programSection
  fi
  local localMountPoint=$LOCAL_MNT
  $isDebug && echo "LOCAL_MNT: $localMountPoint"


  programSection=2
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