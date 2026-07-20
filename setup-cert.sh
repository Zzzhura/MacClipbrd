#!/bin/bash
# Creates a stable self-signed Code Signing certificate "MacClipbrd Dev" in the
# login keychain and trusts it for code signing. Run once. Signing with this
# identity keeps a stable app identity across rebuilds, so macOS remembers the
# Accessibility permission and stops re-prompting.
set -e

NAME="MacClipbrd Dev"
PW="macclipbrd"
DIR="$HOME/Library/Application Support/MacClipbrd"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"
mkdir -p "$DIR"

if security find-identity -p codesigning | grep -q "$NAME"; then
    echo "Identity '$NAME' already exists — nothing to do."
    exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Generating certificate…"
openssl req -x509 -newkey rsa:2048 -keyout "$TMP/key.pem" -out "$TMP/cert.pem" \
    -days 3650 -nodes -subj "/CN=$NAME" \
    -addext "basicConstraints=critical,CA:false" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=critical,codeSigning" 2>/dev/null

openssl pkcs12 -export -legacy \
    -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES -macalg sha1 \
    -inkey "$TMP/key.pem" -in "$TMP/cert.pem" -out "$TMP/cert.p12" \
    -name "$NAME" -passout pass:$PW 2>/dev/null

echo "Importing into login keychain…"
security import "$TMP/cert.p12" -k "$KEYCHAIN" -P "$PW" -A >/dev/null

cp "$TMP/cert.pem" "$DIR/MacClipbrdDev.cer"
echo "Trusting for code signing (может появиться окно с паролем)…"
security add-trusted-cert -p codeSign -k "$KEYCHAIN" "$DIR/MacClipbrdDev.cer"

echo
security find-identity -p codesigning | grep "$NAME" && echo "OK: identity ready."
