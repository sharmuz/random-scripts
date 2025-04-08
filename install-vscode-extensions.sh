#!/usr/bin/env bash

declare -a extensions

extensions=(
    # Python
    "python ms-python 2025.3.2025032601"
    "vscode-pylance ms-python 2025.3.103"
    "jupyter ms-toolsai 2025.2.0"
    "ruff charliermarsh 2025.22.0"
    "autodocstring njpwerner 0.6.1"
    # Git & GitHub
    "git-graph mhutchie 1.30.0"
    "better-git-line-blame mk12 0.2.14"
    "copilot GitHub 1.291.0"
    "copilot-chat GitHub 0.25.1"
    # Markup, scripting and data
    "rainbow-csv mechatroner 3.18.0"
    "vscode-yaml redhat 1.17.0"
    "even-better-toml tamasfe 0.21.2"
    "shell-format foxundermoon 7.2.5"
    "quarto quarto 1.119.0"
    # Other
    "theme-dracula dracula-theme 2.25.1"
)

for x in "${extensions[@]}"; do
    read -a myext <<<$x

    ext_name=${myext[0]}
    ext_pub=${myext[1]}
    ext_ver=${myext[2]}
    ext_url=https://${ext_pub}.gallery.vsassets.io/_apis/public/gallery/publisher/${ext_pub}/extension/${ext_name}/${ext_ver}/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage

    curl -fsSL -o ${ext_name}.vsix $ext_url
    code-server --install-extension ${ext_name}.vsix
    rm ${ext_name}.vsix
done
