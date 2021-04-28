#!/bin/sh

set -o errexit -o nounset -o xtrace

ghc="${1}"
target="${2}"

tmp="$(mktemp -d)"

mkdir -p "${tmp}/stage0"
curl -sSL "https://downloads.haskell.org/~ghc/${ghc}/ghc-${ghc}-x86_64-deb10-linux.tar.xz" \
| tar -C "${tmp}/stage0" -xJ
cd "${tmp}/stage0/ghc-${ghc}"
./configure --prefix="${tmp}/usr"
make install
cd "${OLDPWD}"

curl -sSL "https://downloads.haskell.org/~ghc/${ghc}/ghc-${ghc}-src.tar.xz" \
| tar -C "${tmp}" -xJ "ghc-${ghc}"
cd "${tmp}/ghc-${ghc}"
cat <<EOF > mk/build.mk
BuildFlavour = perf-cross
HADDOCK_DOCS = NO
INTEGER_LIBRARY = integer-simple
Stage1Only = YES
WITH_TERMINFO = NO
EOF
GHC="${tmp}/usr/bin/ghc" ./configure --target="${target}"
make "-j$(($(nproc)+1))"
mkdir -p "${OLDPWD}/dist"
make binary-dist BINARY_DIST_DIR="${OLDPWD}/dist"
cd "${OLDPWD}"

rm -rf "${tmp}"
