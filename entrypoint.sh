#!/usr/bin/env bash

# --- Error Handling Configuration ---
# set -e: Exit immediately if a command exits with a non-zero status. (Replaced by explicit checks)
# set -u: Treat unset variables as an error when substituting.
# set -o pipefail: The return value of a pipeline is the status of the last command to exit with a non-zero status.
set -uo pipefail

# --- Configuration ---
KEY_BASE_DIR="/home/dev/host"
SSH_USER_HOME="/home/dev/.ssh"
PUBLIC_KEY_SRC="${KEY_BASE_DIR}/ssh_key_public"
PRIVATE_KEY_SRC="${KEY_BASE_DIR}/ssh_key_private"
AUTHORIZED_KEYS_FILE="${SSH_USER_HOME}/authorized_keys"
SSH_PRIVATE_KEY_DEST="${SSH_USER_HOME}/id_ed25519" # Standard name for SSH private key

# Global flag to track if SSH is enabled/configured correctly
SSH_ENABLED=true

# --- Helper Functions ---

# Function to log messages with a prefix
log() {
    # $@ correctly expands positional parameters, each as a separate word
    # when not quoted. Quoting "$@" ensures each parameter is treated as a separate word.
    printf "[INFO] %s\n" "$@"
}

error() {
    printf "[ERROR] %s\n" "$@" >&2
}

debug_log() {
    if [[ -n "${DEBUG}" ]]; then
        printf "[DEBUG] %s\n" "$@"
    fi
}

# Function to check the exit status of the last command and handle errors
# Usage: check_command "Optional description"
check_command() {
    local exit_status=$?
    local description="$1"
    if [[ ${exit_status} -ne 0 ]]; then
        error "${description:-Last command failed} with exit status ${exit_status}."
        SSH_ENABLED=false
    fi
}

# --- Core Logic Functions ---

# Sets up the SSH authorized_keys file from the public key
setup_ssh_keys() {
    log "Setting up SSH keys..."

    # Handle public key for authorized_keys
    if [[ -f "${PUBLIC_KEY_SRC}" ]]; then
        log "Copying public key from ${PUBLIC_KEY_SRC} to ${AUTHORIZED_KEYS_FILE}"
        cp "${PUBLIC_KEY_SRC}" "${AUTHORIZED_KEYS_FILE}"
        check_command "Failed to copy public key"

        chown dev:dev "${AUTHORIZED_KEYS_FILE}"
        check_command "Failed to set ownership for ${AUTHORIZED_KEYS_FILE}"

        chmod 400 "${AUTHORIZED_KEYS_FILE}"
        check_command "Failed to set permissions for ${AUTHORIZED_KEYS_FILE}"
    else
        error "Public SSH key not found at expected location: ${PUBLIC_KEY_SRC}"
        SSH_ENABLED=false
    fi

    # Handle private key
    if [[ -f "${PRIVATE_KEY_SRC}" ]]; then
        log "Copying private key from ${PRIVATE_KEY_SRC} to ${SSH_PRIVATE_KEY_DEST}"
        cp "${PRIVATE_KEY_SRC}" "${SSH_PRIVATE_KEY_DEST}"
        check_command "Failed to copy private key"

        chown dev:dev "${SSH_PRIVATE_KEY_DEST}"
        check_command "Failed to set ownership for ${SSH_PRIVATE_KEY_DEST}"

        chmod 400 "${SSH_PRIVATE_KEY_DEST}"
        check_command "Failed to set permissions for ${SSH_PRIVATE_KEY_DEST}"
    else
        error "Private SSH key not found at expected location: ${PRIVATE_KEY_SRC}"
        SSH_ENABLED=false
    fi

    # Final check on authorized_keys file existence and content
    if ! [[ -s "${AUTHORIZED_KEYS_FILE}" ]]; then
        error "SSH authorized_keys file is empty or does not exist after processing."
        SSH_ENABLED=false
    fi
}

# Starts the SSH daemon
start_sshd() {
    if [[ "${SSH_ENABLED}" = true ]]; then
        log "SSH keys processed successfully. Starting sshd server..."
        # Run sshd in the foreground
        exec /usr/sbin/sshd -D
    else
        error "SSH could not be fully configured. See previous messages."
        echo "Ensure both your public and private SSH keys are correctly mounted."
        echo "Public key should be at ${PUBLIC_KEY_SRC}"
        echo "Private key should be at ${PRIVATE_KEY_SRC}"

        if [[ -n "${DEBUG}" ]]; then
            debug_log "DEBUG mode enabled. Keeping container running with 'tail -f /dev/null'."
            exec tail -f /dev/null
        else
            error "Exiting container due to SSH configuration failure."
            exit 1
        fi
    fi
}

# --- Main Execution ---
main() {
    setup_ssh_keys
    start_sshd
}

# Execute the main function
main
