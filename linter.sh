#######################################
# check ansible yaml using [ansible-lint](https://ansible-lint.readthedocs.io/en/latest/) and 
# output result to stdout
#
# Arguments:
#   File to check.
# External variables(Optional):
#   DEBUG: If true, output debug message.
# Returns:
#   If file to check does not exists, return 1.
#   If ansible-lint command does not exist, return 1.
#   If exists, return value of ansible-lint command.
#######################################
function linter_ansible(){
  local isDebug=false
  if [ "${DEBUG-}" = "true" ]; then
    isDebug=true
  fi

  rc=0
  targetFile="$1"
  $isDebug && echo "targetFile=$targetFile"

  echo "[Start linter for ansible]"
  if [ -f "$targetFile" ]; then
    command -v ansible-lint >/dev/null &&:; rc=$?
    $isDebug && echo "result of 'command -v ansible-lint': $rc"

    if [ "0" = "$rc" ]; then
      ansible-lint "$targetFile" &&:; rc=$?
      $isDebug && echo "result of 'ansible-lint $targetFile': $rc"
    else
      echo "ansible-lint command is not exists. Skipping..."
      return 1
    fi
  else
    "Target file '$targetFile' does not exists."
    return 1
  fi
  echo "[End linter for ansible]"

  return $rc
}

#######################################
# check docker-compose yaml file using 'config' option and output result to stdout
# Arguments:
#   File to check.
# External variables(Optional):
#   DEBUG: If true, output debug message.
# Returns:
#   If file to check does not exists, return 1.
#   If docker-compose command does not exist, retunr 1.
#   If exists, return value of docker-compose command.
#######################################
function linter_docker_compose(){
  local isDebug=false
  if [ "${DEBUG-}" = "true" ]; then
    isDebug=true
  fi

  rc=0
  targetFile="$1"
  $isDebug && echo "targetFile=$targetFile"

  echo "[Start linter for docker-compose.yml]"
  if [ -f "$targetFile" ]; then
    command -v docker-compose >/dev/null &&:;rc=$?
    isDebug && echo "result of 'command -v docker-compose': $rc"

    if [ "0" = "$rc" ];then
      docker-compose -f "$targetFile" config -q &&:; rc=$?
      isDebug && echo "result of 'docker-compose -f $targetFile config -q': $rc"
    else
      echo "docker-compose command is not exists. Skipping..."
      return 1
    fi
  else
    "Target file '$targetFile' does not exists."
    return 1
  fi
  echo "[End linter for ansible]"

  return $rc
}

#######################################
# check bash file using [shellcheck](https://github.com/koalaman/shellcheck) and 
# output result to stdout
# Arguments:
#   Directory to check.
#   Directories to exclude, separeted by comma. ex) */node_modules/*
# External variables(Optional):
#   DEBUG: If true, output debug message.
# Returns:
#   If shellcheck command does not exist, retunr 1.
#   If exists, return value of shellcheck command.
#######################################
function linter_shell(){
  local isDebug=false
  if [ "${DEBUG-}" = "true" ]; then
    isDebug=true
  fi

  rc=0
  targetDirectory="$1"
  excludingDirectories=()
  if [ -n "${INTERNAL_OPTIONS-}" ]; then
    IFS=', ' read -r -a excludingDirectories <<< $2
  fi
  if $isDebug; then
    echo "targetDirectory: $targetDirectory"
    nExcludingDirectories=${#excludingDirectories[@]}
    for (( i=0; i<${nExcludingDirectories}; i++));
    do
      echo "excludingDirectories[$i]: ${excludingDirectories[$i]}"
    done
  fi

  echo "[Start linter for bash]"
  findCommand="find $targetDirectory -name '*.sh'"
  for excludingDirectory in "${excludingDirectories[@]}"
  do
    findCommand="$findCommand -not -path  $excludingDirectory"
  done
  $isDebug && echo "findCommand: $findCommand"

  fileCount=$(eval "$findCommand | wc -l")
  $isDebug && echo "fileCount: $fileCount"
  if [ "0" != "$fileCount" ]; then
    command -v shellcheck >/dev/null &&:; rc=$?
    $isDebug && echo "result of 'command -v shellcheck': $rc"

    if [ "$rc" = "0" ]; then
      eval "$findCommand -exec shellcheck -x {} \; &&:"; rc=$? 
      $isDebug && echo "result of '$findCommand -exec shellcheck -x {} \;': $rc"
    else
      echo "Shellcheck command isn't exists. please check online.(https://www.shellcheck.net/)"
      echo "Target files are below"
      echo ""
      eval "$findComand -print"
      return 1
    fi
  else
    echo "Target files do not exist."
    return 1
  fi
  echo "[End linter for bash]"

  return $rc
}

#######################################
# check markdown file using [markdownlint](https://github.com/DavidAnson/markdownlint) and 
# output result to stdout
# Arguments:
#   Directory to check.
#   Directories to exclude, separeted by comma. ex) */node_modules/*
# External variables(Optional):
#   DEBUG: If true, output debug message.
# Returns:
#   If markdownlint command does not exist, retunr 1.
#   If exists, return value of markdownlint command.
#######################################
function linter_markdown(){
  local isDebug=false
  if [ "${DEBUG-}" = "true" ]; then
    isDebug=true
  fi

  rc=0
  targetDirectory="$1"
  excludingDirectories=()
  if [ -n "${INTERNAL_OPTIONS-}" ]; then
    IFS=', ' read -r -a excludingDirectories <<< $2
  fi
  if $isDebug; then
    echo "targetDirectory: $targetDirectory"
    nExcludingDirectories=${#excludingDirectories[@]}
    for (( i=0; i<${nExcludingDirectories}; i++));
    do
      echo "excludingDirectories[$i]: ${excludingDirectories[$i]}"
    done
  fi

  echo "[Start linter for markdown]"
  findCommand="find $targetDirectory -name \"\*.md\""
  for excludingDirectory in "${excludingDirectories[@]}"
  do
    findCommand="$findCommand -not -path  $excludingDirectory"
  done
  $isDebug && echo "findCommand: $findCommand"

  fileCount=$("$findCommand | wc -l")
  $isDebug && echo "fileCount: $fileCount"
  if [ "0" != "$fileCount" ]; then
    npx markdownlint --version >/dev/null 2>&1 &&:; rc=$?
    $isDebug && echo "result of 'npx markdownlint --version': $rc"

    if [ "$rc" = "0" ]; then
      eval "$findCommand -exec markdownlint -x {} \; &&:"; rc=$? 
      $isDebug && echo "result of '$findCommand -exec markdownlint -x {} \;': $rc"
    else
      echo "markdownlint command isn't exists. please check online.(https://dlaa.me/markdownlint/)"
      echo "Target files are below"
      echo ""
      eval "$findComand -print"
      return 1
    fi
  else
    echo "Target files do not exist."
    return 1
  fi
  echo "[End linter for markdown]"

  return $rc
}
