# source me from the project root...

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

PROJ_ROOT=$SCRIPT_DIR

export NKEYS_PATH=${PROJ_ROOT}/vault/.nkeys
export NSC_HOME=${PROJ_ROOT}/vault
