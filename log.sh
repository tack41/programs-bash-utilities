#==========
# Usage:
#   $0 message
#
# Description:
#   This script output argument to log and stdout.
#   If 'LOG_FILE' environment variavle defined, this also output log file defined path
#
# External variables(Optional):
#   LOG_FILE: path of log file
#==========
function log(){
  if [ -n "${LOG_FILE-}" ]; then
    echo -e "$(date '+%Y-%m-%dT%H:%M:%S') (${BASH_SOURCE[1]##*/}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $@" | tee -a ${LOG_FILE}
  else
    echo -e "$(date '+%Y-%m-%dT%H:%M:%S') (${BASH_SOURCE[1]##*/}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $@"
  fi
}

#==========
# Usage:
#   $0 message
#
# Description:
#   This script output argument to log and stderr.
#   If 'LOG_FILE' environment variavle defined, this also output log file defined path
#
# External variables(Optional):
#   LOG_FILE: path of log file
#==========
function loge(){
  if [ -n "${LOG_FILE-}" ]; then
    dateNow=$(date '+%Y-%m-%dT%H:%M:%S')
    echo -e "$(date '+%Y-%m-%dT%H:%M:%S') (${BASH_SOURCE[1]##*/}:${BASH_LINENO[0]}:${FUNCNAME[1]})!ERROR! $@" |tee -a ${LOG_FILE} 1>&2
  else
    echo -e "$(date '+%Y-%m-%dT%H:%M:%S') (${BASH_SOURCE[1]##*/}:${BASH_LINENO[0]}:${FUNCNAME[1]})!ERROR! $@" 1>&2
  fi
}
