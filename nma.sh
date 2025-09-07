#!/bin/bash

ALVO=$1

if [ -z "$ALVO" ]; then
    echo "⚠️  Uso: $0 <alvo>"
    exit 1
fi

# Rodar nmap com saída XML
XML=$(mktemp)
nmap -sV -oX "$XML" "$ALVO" > /dev/null

# Converter XML para JSON
cat "$XML" | python3 -c 'import sys, xmltodict, json; print(json.dumps(xmltodict.parse(sys.stdin.read()), indent=2))'

rm "$XML"
