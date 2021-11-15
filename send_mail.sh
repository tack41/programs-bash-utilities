#==========
# Usage:
#   $0 [local2remote]
#
# Description:
#   Send mail. 
#   first argument is used as mail body.
#   Install Heirloom mailx or s-nail in advance.
#
# Options:
# 
# External variables(Required):
#   MAIL_FROM: 
#   MAIL_TO:
#   MAIL_SUBJECT:
# External variables(Optional):
#   MAIL_ATTACHMENTS: Attachment files. In the case of multiple files, specify them separated by commas.
#   INTERNAL_OPTIONS: like 'smtp=smtp://example.com:25'. In the case of multiple files, specify them separated by commas.
#   DEBUG: If true, output debug message.
#==========
function send_mail() {
  local isDebug=false
  if [ "${DEBUG-}" = "true" ]; then
    isDebug=true
  fi

  rc=0
  programSection=1
  $isDebug && echo "[${programSection}. Get mail body from first argument]" 
  local mailBody=
  if [ $# -ge 1 ]; then
    mailBody="$1"
    $isDebug && echo "mailBody='$1'" 
  fi


  programSection=2
  $isDebug && echo "[${programSection}. Check wheter MAIL_FROM environmental variable defined]"
  if [ -z "${MAIL_FROM-}" ]; then
    echo "Environmental variable MAIL_FROM wasn't defined" 2>&1
    return $programSection
  fi
  local mailFrom=$MAIL_FROM
  $isDebug && echo "MAIL_FROM: $mailFrom"


  programSection=3
  $isDebug && echo "[${programSection}. Check wheter MAIL_TO environmental variable defined]"
  if [ -z "${MAIL_TO-}" ]; then
    echo "Environmental variable MAIL_TO wasn't defined" 2>&1
    return $programSection
  fi
  local mailTo=$MAIL_TO
  $isDebug && echo "MAIL_TO: $mailTo"


  programSection=4
  $isDebug && echo "[${programSection}. Check wheter MAIL_SUBJECT environmental variable defined]"
  if [ -z "${MAIL_SUBJECT-}" ]; then
    echo "Environmental variable MAIL_SUBJECT wasn't defined" 1>&2
    return $programSection
  fi
  local mailSubject=$MAIL_SUBJECT
  $isDebug && echo "MAIL_SUBJECT: $MAIL_SUBJECT"


  programSection=5
  $isDebug && echo "[${programSection}. Check wheter MAIL_ATTACHMENTS environmental variable defined]"
  local mailAttachments=()
  if [ -n "${MAIL_ATTACHMENTS-}" ]; then
    IFS=', ' read -r -a mailAttachments <<< $MAIL_ATTACHMENTS
  fi
  $isDebug && echo "MAIL_ATTACHMENTS: ${mailAttachments[@]}"


  programSection=6
  $isDebug && echo "[${programSection}. Check wheter INTERNAL_OPTIONS environmental variable defined]"
  local internalOptions=()
  if [ -n "${INTERNAL_OPTIONS-}" ]; then
    IFS=', ' read -r -a internalOptions <<< $INTERNAL_OPTIONS
  fi
  $isDebug && echo "INTERNAL_OPTIONS: ${internalOptions[@]}"


  programSection=7
  $isDebug && echo "[${programSection}. Create command string to send mail]"
  local mailCommand=
  which s-nail > /dev/null 2>&1 &&:
  snail_exists=$?
  which mailx > /dev/null 2>&1 &&:
  mailx_exists=$?
  if [ $snail_exists -eq 0 ]; then
    mailCommand="s-nail -s '${mailSubject}' -r ${mailFrom}"
  elif [ $mailx_exists -eq 0 ]; then    
    mailCommand="mailx -s '${mailSubject}' -r ${mailFrom}"
  else
    echo "Niether Heirloom mailx or s-nail is installed" 2>&1
    return $programSection
  fi
  for attachment in "${mailAttachments[@]}"
  do
    mailCommand="${mailCommand} -a ${attachment}"
  done
  for internalOption in "${internalOptions[@]}"
  do
    mailCommand="${mailCommand} -S ${internalOption}"
  done
  mailCommand="$mailCommand ${mailTo}"
  $isDebug && echo "mailCommand: $mailCommand"

  programSection=8
  $isDebug && echo "[${programSection}. Execute command string to send mail]"
  echo $mailBody | eval $mailCommand
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "Failed to execute command string to send mail '${mailCommand}': $rc" 2>&1
    return $programSection
  fi


  return 0
}