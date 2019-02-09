#%include std/syntax-extensions.sh

$%function pplug:ports:applymode(mode *p_ports) {
    local port

    for port in "${p_ports[@]}"; do
        ufw "${mode[@]}" "${port[@]}"
    done
}

$%function pplug:ports:useports(*p_portsvar) {
    if [[ -n "$*" ]]; then
        p_portsvar=("$@")
    else
        p_portsvar=("${DEFAULT_PORTS[@]}")
    fi
}

