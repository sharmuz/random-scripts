#!/usr/bin/env bash
SETTINGS_DIR=${DOMINO_WORKING_DIR}/.vscode

# Add vscode user setting file only if it doesn't exist
# Add in DOMINO_WORKING_DIR so it persists across sessions
if [ ! -f "${SETTINGS_DIR}/settings.json" ]; then

	sudo mkdir -p $SETTINGS_DIR
	sudo chown -R domino:domino ${SETTINGS_DIR}
	curl -fsSL -o ${SETTINGS_DIR}/settings.json https://raw.githubusercontent.com/sharmuz/random-scripts/refs/heads/master/vscode-settings.json

fi

code-server ${DOMINO_WORKING_DIR} --user-data-dir ${SETTINGS_DIR} --auth none --bind-addr 0.0.0.0:8888 --extensions-dir ${HOME}/.local/share/code-server/extensions --disable-telemetry
