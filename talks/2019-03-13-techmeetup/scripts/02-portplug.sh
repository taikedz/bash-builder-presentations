#!/usr/bin/env bash

set -euo pipefail

DEFAULT_PORTS=(80 8080 25)

die() {
    echo "$*"
    exit 1
}

main() {
    # Safe dereference, shift generates the error
    local mode="${1:-}"; shift ||
        die "No mode (on/off) specified"

    local port                                          
                                                        
    if [[ "$mode" = on ]]; then                         
        mode=(deny)                                     
    elif [[ "$mode" = off ]]; then                      
        mode=(delete deny)                              
    else                                                
        die "Invalid mode '$mode' specified"             
    fi                                                  
                                                        
    for port in "${DEFAULT_PORTS[@]}"; do               
        ufw "${mode[@]}" "$port"                        
    done                                                 
}                                                        
                                                      
main "$@"                                               

