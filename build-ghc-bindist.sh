#!/bin/sh

set -o errexit -o nounset -o xtrace

ghc="${1:-9.0.1}"
target="${2}"

tmp="$(mktemp -d)"

curl -sSL "https://downloads.haskell.org/~ghc/${ghc}/ghc-${ghc}-x86_64-deb10-linux.tar.xz" \
| tar -C "${tmp}" -xJ
cd "${tmp}/ghc-${ghc}"
./configure --prefix="${tmp}/usr"
make install
cd "$OLDPWD"

curl -sSL "https://downloads.haskell.org/~ghc/${ghc}/ghc-${ghc}-src.tar.xz" \
| tar -xJ
cd "ghc-${ghc}"
cat <<EOF > mk/build.mk
Stage1Only = YES
HADDOCK_DOCS = NO
INTEGER_LIBRARY = integer-simple
WITH_TERMINFO = NO
EOF
GHC="${tmp}/usr/bin/ghc" ./configure --target="${target}"
make "-j$(($(nproc)+1))"
cd "$OLDPWD"

mkdir -p dist
tar -cJf "dist/ghc-${ghc}-x86_64-linux-gnu-${target}.tar.xz" "ghc-${ghc}"
