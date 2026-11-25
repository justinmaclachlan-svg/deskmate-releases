# Bots run in your agent account (<you>-bots), never as you and never as root.
if [ "$(id -u)" != 0 ] && id "$(id -un)-bots" >/dev/null 2>&1; then
  DESKMATE_AGENT_USER="$(id -un)-bots"
  DESKMATE_AGENT_HOME="/home/$DESKMATE_AGENT_USER"
  DESKMATE_WORKSPACE="$DESKMATE_AGENT_HOME/work"
  DESKMATE_BOTS_DIR="$DESKMATE_AGENT_HOME/deskmate"
  export DESKMATE_AGENT_USER DESKMATE_AGENT_HOME DESKMATE_WORKSPACE DESKMATE_BOTS_DIR
fi
case ":$PATH:" in *:/opt/deskmate:*) ;; *) PATH="$PATH:/opt/deskmate"; export PATH ;; esac
