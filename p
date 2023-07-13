#!/bin/bash

# The file the stores the name of the current projects
CURRENT_PROJECTS_FILE="$HOME/.current_projects"

# Development directory that holds all the project folders
DEV_DIR="$HOME/dev"

# A python script that parses the .catapult.yml file and returns the command to run
PARSE_YAML_SCRIPT="$HOME/parse_yaml.py"

# Name of the configuration file that will be present in each project folder
CONFIG_FILE=".catapult.yml"

# Name of the code window
CODE_WINDOW="code"

# Name of the background window
BG_WINDOW="bg"

# Name of the keys in the .catapult.yml file
UP_KEY="up"
DOWN_KEY="down"
BG_KEY="bg"

# Name of the code editor to use
CODE_EDITOR="nvim"

function run() {
	# Allow support for parallel projects with the -p flag.
	# This is useful when we don't want to stop whatever project is already running
	local parallel=0
	if [[ $1 == "-p" ]]; then
		parallel=1
		shift
	fi
	if [[ "${parallel}" -eq 0 ]]; then
		stop
	fi
	
	project_to_attach=""
	for project in "$@"; do
		local project_dir="${DEV_DIR}/${project}"
		local config_file="${project_dir}/${CONFIG_FILE}"

		if [ ! -d "${project_dir}" ]; then
			echo "Project ${1} does not exist."
			return 1
		fi

		if [ ! -f "${config_file}" ]; then
			echo "${confing_file} file for project ${1} does not exist."
			return 1
		fi

		# Running the "up" command to initialize the project
		local run_command=$(python3 "${PARSE_YAML_SCRIPT}" "${config_file}" "${UP_KEY}")
		echo "Running ${run_command}..."
		cd "${project_dir}" && eval "${run_command}"

		# Check for tmux session and create it if doesn't exist
		tmux has-session -t="${project}" 2>/dev/null
		if [ $? != 0 ]; then
			tmux new-session -d -s "${project}"
			echo "Created new tmux session ${project}."
		else
			echo "Tmux session ${project} already exists."
		fi

		# Create a new window for background processes in the session and send commands to it
		# We create a new vertical pane for every entry
		tmux list-windows -t="${project}" | grep -q "${BG_WINDOW}"
		if [ $? != 0 ]; then
			tmux new-window -n "${BG_WINDOW}" -t="${project}"
			local bg_commands=$(python3 "${PARSE_YAML_SCRIPT}" "${config_file}" "${BG_KEY}")
			IFS=$'\n'
			for cmd in $bg_commands
			do
				echo "Running ${cmd}..."
				tmux split-window -h -t="${project}:${BG_WINDOW}"
				tmux send-keys -t="${project}:${BG_WINDOW}" "${cmd}" ENTER
			done
			tmux kill-pane -t="${project}:${BG_WINDOW}.0"  # Remove the first, empty pane
			tmux select-pane -t="${project}:${BG_WINDOW}.0"
		else
			echo "Tmux window ${project}:${BG_WINDOW} already exists."
		fi

		echo "${project}" >> "${CURRENT_PROJECTS_FILE}"

		# Create the base window for the code editor, and focus it
		tmux rename-window -t="${project}:0" "${CODE_WINDOW}"
		tmux send-keys -t="${project}:${CODE_WINDOW}" "${CODE_EDITOR} ." ENTER
		tmux select-window -t"${project}:${CODE_WINDOW}"

		project_to_attach="${project}"
	done

	if [[ -n "${project_to_attach}" ]]; then
		tmux attach-session -t="${project_to_attach}"
	fi
}

function stop() {
	local current_projects=$(cat "${CURRENT_PROJECTS_FILE}")

	if [[ -n "${current_projects}" ]]; then
		for project in ${current_projects}; do
			if [[ -d "${DEV_DIR}/${project}" ]]; then
				local down_command=$(python3 "${PARSE_YAML_SCRIPT}" "${DEV_DIR}/${project}/${CONFIG_FILE}" "${DOWN_KEY}")

				if [[ -n "${down_command}" ]]; then
					echo "Running ${down_command}..."
					cd "${DEV_DIR}/${project}" && eval "${down_command}"
				fi

				tmux kill-session -t="${project}"
				echo "Stopped ${project}."
			else
				echo "Project ${project} does not exist."
			fi
		done
	else
		echo "No projects running."
	fi

	echo "" > "${CURRENT_PROJECTS_FILE}"
}

"$@"
