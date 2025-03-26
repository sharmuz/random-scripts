#!/usr/bin/env bash

# Copyright (c) 2021 Domino Data Lab Inc. All rights reserved.
#
# Sets up and launches Jupyter Notebook in the Domino workspace. The notebook
# will include all the kernels configured in the base image, but not a kernel
# derived from Domino's installation of Python.
#
# This scripts converts some kernel specifications to assure that they launch
# Pythons from the system, not from the injected Domino environment.

set -o nounset
set -o errexit

DOMINO_CONDA_DIR=/opt/domino/conda
#################### Configuring Jupyter kernels ############################

# Converts an executable name inside an IPython kernel specification to a
# full absolute path and writes a copy of the spec file with the new value
# to the user location.
#
# GLOBALS:
#         USER_KERNELS_HOME    typically "~/.local/share/jupyter/kernels".
# ARGUMENTS:
#         $1    Kernel name, e.g. "python2".
#         $2    Original kernel spec directory.
# OUTPUTS:
#         None to stdout.
# RETURNS:
#         0 if the conversion succeeded, non-zero otherwise.
convert_spec() {
    spec_path="$USER_KERNEL_HOME/$1"
    cp -rf "$2" "$spec_path" 2> /dev/null
    spec_file="$spec_path/kernel.json"
    # Extracts ??? from '... "argv" [ "???" ...'
    old_cmd=$(cat "$spec_file" | tr "\r\n" "  " | \
        sed -n 's;.*"argv": *\[ *"\([^"]*\)".*;\1;p')
    if [ -z "$old_cmd" ]; then
        echo >&2 "WARNING: Invalid kernelspec \"$1\""
        return 1
    fi
    if ! grep -q "^python[0-9.]*$" <<< "$old_cmd"; then
        # Do not need to resolve commands more complex than 'python*'
        return 0
    fi
    new_cmd=$(command -v "$old_cmd")
    if [ -z "$new_cmd" ]; then
        echo >&2 "WARNING: Cannot resolve path in kernelspec \"$1\""
        return 1
    fi
    # Replaces quoted $old_cmd -> $new_cmd between "argv" and a closing bracket.
    sed -i "/\"argv\"/,/]/{s;\"$old_cmd\";\"$new_cmd\";}" "$spec_file"
}

# Makes a kernel available to Domino Jupyter Notebook.
#
# GLOBALS:
#         ALL_KERNELS    Whitelisted kernels.
# ARGUMENTS:
#         $1    Kernel name, e.g. "python2".
#         $2    Kernel spec directory.
# OUTPUTS:
#         None to stdout.
# RETURNS:
#         0.
register_kernel() {
    if (! grep -q "^python.*$" <<< "$1") || convert_spec "$1" "$2"; then
        ALL_KERNELS+="'$1',"
    fi
    return 0
}

USER_KERNEL_HOME="$HOME/.local/share/jupyter/kernels"
mkdir -p "$USER_KERNEL_HOME"

# Running comma-separated list of whitelisted kernels.
ALL_KERNELS=

# We must use system Jupyter, which may not be always available.
for jupbin in $(find / -type f -executable -name jupyter 2>/dev/null); do
    # Converts an output of 'jupyter kernelspec list' command to
    # comma-separated tuples '<kernel-name>,<kernelspec-path>'.
    # The original format includes superfluous whitespaces.
    for line in $("$jupbin" kernelspec list 2>/dev/null | tail -n +2 | \
                    sed -n 's/^ *\([[:graph:]]*\)  *\([[:graph:]]*\) *$/\1,\2/p'); do
            IFS="," read name path <<< "$line"
            register_kernel "$name" "$path"
    done
done
echo "Available kernels: $ALL_KERNELS"

#################### Creating Jupyter configuration file ###################

BASE_URL="/$DOMINO_PROJECT_OWNER/$DOMINO_PROJECT_NAME/notebookSession/$DOMINO_RUN_ID"
CONF_FILE="$HOME/.jupyter/jupyter_lab_config.py"
mkdir -p $(dirname "$CONF_FILE")

cat > "$CONF_FILE" << EOF
#c = get_config()
# Lab has access to all files in the environment
c.NotebookApp.notebook_dir='/'
# Lab starts in the domino working dir
#c.NotebookApp.default_url='/lab/tree${DOMINO_WORKING_DIR:-/mnt}'
c.LabApp.default_url = '/lab/tree${DOMINO_WORKING_DIR:-/mnt}'
c.ServerApp.preferred_dir = '${DOMINO_WORKING_DIR}'
# Routing, networking and acccess
c.NotebookApp.base_url='${BASE_URL}/'
c.NotebookApp.tornado_settings={'headers': {'Content-Security-Policy': 'frame-ancestors *'}, 'static_url_prefix': '${BASE_URL}/static/'}
c.NotebookApp.token=u''
c.NotebookApp.iopub_data_rate_limit=10000000000
# The default cell execution timeout in nbconvert is 30 seconds, set it to a year
c.ExecutePreprocessor.timeout=365*24*60*60
# Only allow kernels that come from the sanitized list we have processed
#c.KernelSpecManager.allowed_kernelspecs={${ALL_KERNELS:-''}}
#c.KernelSpecManager.ensure_native_kernel=False
c.ContentsManager.allow_hidden=True
EOF

#################### Launching the notebook #################################

exec env SHELL=/bin/bash "${DOMINO_CONDA_DIR}/bin/jupyter-lab" \
        --config="$CONF_FILE" \
        --no-browser \
        --ip="0.0.0.0" 2>&1
