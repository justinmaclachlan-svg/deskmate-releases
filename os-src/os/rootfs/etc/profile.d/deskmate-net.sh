# Bots' accounts reach the internet only through the allowed-sites gate on this
# computer (see: deskmate-os net). Programs find it with these.
case "$(id -un 2>/dev/null)" in
  *-bots)
    HTTPS_PROXY=http://127.0.0.1:8888; HTTP_PROXY=$HTTPS_PROXY; https_proxy=$HTTPS_PROXY; http_proxy=$HTTPS_PROXY
    NO_PROXY=localhost,127.0.0.1,::1; no_proxy=$NO_PROXY; NODE_USE_ENV_PROXY=1
    export HTTPS_PROXY HTTP_PROXY https_proxy http_proxy NO_PROXY no_proxy NODE_USE_ENV_PROXY ;;
esac
