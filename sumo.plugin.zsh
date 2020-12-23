#####################################################################
# Init
#####################################################################

export SUMOLOGIC_API_ENDPOINT="https://api.au.sumologic.com/api"

unset SUMO_DEBUG

function sumo-del () {
  local PTH=""

  if [[ -n "${1}" ]]; then
    PTH="/${1}"
  fi

  if [[ -n "${SUMO_DEBUG}" ]]; then
    logger warn "Delete to api ${PTH}"
  fi

  curl --request DELETE \
       --silent \
       --header 'Accept: application/json' \
       --user ${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY} \
       "${SUMOLOGIC_API_ENDPOINT}${PTH}"
}

function sumo-get () {
  local PTH="" #${1:-""}
  local QRY="" #${2:-""}

  if [[ -n "${1}" ]]; then
    PTH="/${1}"
  fi

  if [[ -n "${2}" ]]; then
    QRY="?${2}"
  fi

  if [[ -n "${SUMO_DEBUG}" ]]; then
    logger warn "Get to api ${PTH}"
  fi

  curl --request GET \
       --silent \
       --header 'Accept: application/json' \
       --user ${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY} \
       "${SUMOLOGIC_API_ENDPOINT}${PTH}${QRY}"
}

function sumo-post () {
  local PTH=${1:-""}
  local DTA=${2:-"{}"}

  if [[ -n "${1}" ]]; then
    PTH="/${1}"
  fi

  if [[ -n "${SUMO_DEBUG}" ]]; then
    logger warn "Post to api ${PTH}"
  fi

  curl --request POST \
       --silent \
       --header 'Content-type: application/json' \
       --header 'Accept: application/json' \
       --user ${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY} \
       --data $DTA \
       "${SUMOLOGIC_API_ENDPOINT}${PTH}"
}

function sumo () {
  [[ $# -gt 0 ]] || {
    _sumo::help
    return 1
  }

  local command="$1"
  shift

  (( $+functions[_sumo::$command] )) || {
    _sumo::help
    return 1
  }

  _sumo::$command "$@"
}

function _sumo {
  local -a cmds subcmds
  cmds=(
    'help:Usage information'
    'init:Initialisation information'
    'user:Manage Users'
    'content:Manage Content'
    'folder:Manage Folders'
    'search:Search Jobs'
  )

  if (( CURRENT == 2 )); then
    _describe 'command' cmds
  elif (( CURRENT == 3 )); then
    case "$words[2]" in
      user) subcmds=(
        'list:list all the users'
        )
        _describe 'command' subcmds ;;
      folder) subcmds=(
        'global:show global folder'
        'personal:show personal folder'
        'show:show folder by id'
        )
        _describe 'command' subcmds ;;
      content) subcmds=(
        'path:show content by path'
        'show:show content by id'
        )
        _describe 'command' subcmds ;;
      search) subcmds=(
        'last-15m:Search over the last 15 minutes'
        'last-30m:Search over the last 30 minutes'
#        'today:Search over the the current day'
        )
        _describe 'command' subcmds ;;
    esac
  fi

  return 0
}

compdef _sumo sumo

function _sumo::help {
    cat <<EOF
Usage: sumo <command> [options]

Available commands:

  user
  folder
  content
  search

EOF
}

function _sumo::init {
  echo "============================================="
  echo "Create a new access id and key pair and export\n  SUMOLOGIC_ACCESSID=<access_id>\n  SUMOLOGIC_ACCESSKEY=<access_key>"
  echo "============================================="
  open "https://service.au.sumologic.com/ui/#/preferences"
}

#####################################################################
# User
#####################################################################

function _sumo::user () {
  (( $# > 0 && $+functions[_sumo::user::$1] )) || {
    cat <<EOF
Usage: sumo user <command> [options]

Available commands:

  list

EOF
    return 1
  }

  local command="$1"
  shift

  _sumo::user::$command "$@"
}

function _sumo::user::list () {
  sumo-get "/v1/users"
}

#####################################################################
# Folder
#####################################################################

function _sumo::folder () {
  (( $# > 0 && $+functions[_sumo::folder::$1] )) || {
    cat <<EOF
Usage: sumo folder <command> [options]

Available commands:

  global          Show the global folder
  personal        Show the personal folder
  show     [id]   Show the folder with id

EOF
    return 1
  }

  local command="$1"
  shift

  _sumo::folder::$command "$@"
}

function _sumo::folder::global () {
  sumo-get "v2/content/folders/global"
}

function _sumo::folder::personal () {
  sumo-get "v2/content/folders/personal"
}

function _sumo::folder::show () {
  sumo-get "v2/content/folders/${1:-"0000000000000000"}"
}

#####################################################################
# Content
#####################################################################

function _sumo::content () {
  (( $# > 0 && $+functions[_sumo::content::$1] )) || {
    cat <<EOF
Usage: sumo content <command> [options]

Available commands:

  path   [id]
  show   [id]
  export [id]
  status [id] [job]
  result [id] [job]

EOF
    return 1
  }

  local command="$1"
  shift

  _sumo::content::$command "$@"
}

function _sumo::content::path () {
  sumo-get "v2/content/${1:-"0000000000000000"}/path"
}

function _sumo::content::show () {
  sumo-get "v2/content/path" \
           "path=$(sumo content path ${1:-"0000000000000000"} | jq -r ".path" | sed -e 's/ /%20/g')"
}

function _sumo::content::export () {
  sumo-post "v2/content/${1:-"0000000000000000"}/export" "{}"
}

function _sumo::content::status () {
  sumo-get "v2/content/${1:-"0000000000000000"}/export/${2:-"0000000000000000"}/status"
}

function _sumo::content::result () {
  sumo-get "v2/content/${1:-"0000000000000000"}/export/${2:-"0000000000000000"}/result"
}

#####################################################################
# Search
#####################################################################

function _sumo::search () {
  (( $# > 0 && $+functions[_sumo::search::$1] )) || {
    cat <<EOF
Usage: sumo search <command> [options]

Available commands:

  last-15m   [sourcename] [query]
  last-30m   [sourcename] [query]
  today     [sourcename] [query]

EOF
    return 1
  }

  local command="$1"
  shift

  _sumo::search::$command "$@"
}

function sumo-search () {

  local SRT_DATE=${1:-$( date -v-5M "+%Y-%m-%dT%H:%M:%S" )}
  local END_DATE=${1:-$( date -v-5M "+%Y-%m-%dT%H:%M:%S" )}
  local SOURCE_NAME=${3:-"sourcename"}
  local QUERY_STRING=${4:-""}

  local QRY="_sourcename = \\\"${SOURCE_NAME}\\\" ${QUERY_STRING}"

  local DATA="{
    \"query\":           \"${QRY}\",
    \"from\":            \"${SRT_DATE}\",
    \"to\":              \"${END_DATE}\",
    \"timeZone\":        \"Australia/Melbourne\",
    \"byReceiptTime\":    true
  }"

  local JOB=$( sumo-post "v1/search/jobs" $DATA )
  local ID=$( echo ${JOB} | jq -r ".id" )

  local STATUS="RUNNING"
  local COUNT=0

  while [ "${STATUS}" = "RUNNING" ]
  do

    local RESULT=$( sumo-get "v1/search/jobs/${ID}" )
    case $(echo ${RESULT} | jq -r ".state") in
      "NOT STARTED")
        STATUS="RUNNING"
        ;;
      "GATHERING RESULTS")
        STATUS="RUNNING"
        ;;
      "FORCE PAUSED")
        STATUS="COMPLETE"
        ;;
      "DONE GATHERING RESULTS")
        STATUS="COMPLETE"
        COUNT=$(echo ${RESULT} | jq -r ".messageCount")
        ;;
      "CANCELLED")
        STATUS="COMPLETE"
        ;;
      *)
        STATUS="COMPLETE"
        ;;
    esac

    sleep 1

  done

  local MESSAGES=$( sumo-get "v1/search/jobs/${ID}/messages" "offset=0&limit=${COUNT}" )
  local DELETED=$( sumo-del "v1/search/jobs/${ID}" )

  echo "${MESSAGES}" | sed -e 's/\\\\"/\\\\\\"/g'
}

function _sumo::search::last-15m () {
  local SRT_DATE=$( date -v-15M "+%Y-%m-%dT%H:%M:%S" )
  local END_DATE=$( date "+%Y-%m-%dT%H:%M:%S" )
  sumo-search ${SRT_DATE} ${END_DATE} "$@"
}

function _sumo::search::last-30m () {
  local SRT_DATE=$( date -v-30M "+%Y-%m-%dT%H:%M:%S" )
  local END_DATE=$( date "+%Y-%m-%dT%H:%M:%S" )
  sumo-search ${SRT_DATE} ${END_DATE} "$@"
}
