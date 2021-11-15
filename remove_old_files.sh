#==========
# Usage:
#   $0 
#
# Description:
#   Arrange files containing a specific string specifyed by the FILENAME_PART environment in order by file name, and delete older files.
#   Deletes files that exceed the number specified by the FILE_MAX variable in directory specifyed by the FILE_DIR variable.
#   If the FILE_MAX variable is not specified, files exceeding 8 will be deleted.
#
# External variables(Required):
#   FILE_DIR: Directory path which includes filess to delete.
#   FILENAME_PART: String to be included by target file as filename.
# External variables(Optional):
#   FILE_MAX: Number to delete files over. If not specified, using '8'.
#   DRY_RUN: If true, the deletion process will not be performed.
#   DEBUG: If defined, output debug message.
#==========
function remove_old_files(){
  local isDebug=false
  if [ "${DEBUG-}" = "true" ]; then
    isDebug=true
  fi
  local isRealRun=true
  if [ "${DRY_RUN-}" = "true" ]; then
    isRealRun=false
  fi
  
  programSection=1
  $isDebug && echo "[${programSection}. Check wheter FILE_DIR environmental variable defined]"
  if [ -z "${FILE_DIR-}" ]; then
    echo "Required environment variable FILE_DIR is not defined" 1>&2
    return $programSection
  fi
  local fileDir=$FILE_DIR
  $isDebug && echo "FILE_DIR: $fileDir"


  programSection=2
  $isDebug && echo "[${programSection}. Check wheter FILENAME_PART environmental variable defined]"
  if [ -z "${FILENAME_PART-}" ]; then
    echo "Required environment variable FILENAME_PART is not defined" 1>&2
    return $programSection
  fi
  local filenamePart=$FILENAME_PART
  $isDebug && echo "FILENAME_PART: $filenamePart"


  programSection=3
  $isDebug && echo "[${programSection}. Determine Number to delete files over]"
  local fileMax=8
  if [ -n "${FILE_MAX-}" ]; then
    fileMax=$FILE_MAX
  fi
  $isDebug && echo "FILE_MAX: $fileMax"


  programSection=4
  $isDebug && echo "[${programSection}. Get filename list sorted]"
  local targetFiles=()
  targetFiles=(`ls ${fileDir}|sort -r|grep ${filenamePart}`)
  $isDebug && echo "targetFiles: ${targetFiles[*]}"
  $isDebug && echo "Number of targetFiles: ${#targetFiles[@]}"


  programSection=5
  $isDebug && echo "[${programSection}. Remove older files]"
  for ((i=$fileMax; i<${#targetFiles[@]}; i++)); do
    $isRealRun && rm ${FILE_DIR}/${targetFiles[i]} &&:
    rc=$?
    if [ $rc -eq 0 ]; then
      $isDebug && echo "Removed: ${FILE_DIR}/${targetFiles[i]}"
    else 
      echo "An error occurred while deleting ${FILE_DIR}/${targetFiles[i]}: $rc" 1>&2
      echo "Continue processing" 1>&2
    fi
  done

  return 0
}
