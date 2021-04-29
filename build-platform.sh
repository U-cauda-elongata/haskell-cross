#!/bin/sh

set -o errexit -o nounset -o xtrace

ghc="${1}"
target="${2}"
cabal=3.4.0.0

case "${target}" in
aarch64-linux-gnu)
    dist_target=aarch64-unknown-linux
    ;;
arm-linux-gnueabihf)
    dist_target=arm-unknown-linux
    ;;
*)
    dist_target="${target}"
    ;;
esac

cd "$(dirname "${0}")"

tmp="$(mktemp -d)"

curl -sSL "https://github.com/U-cauda-elongata/haskell-cross/releases/download/ghc-${ghc}/ghc-${ghc}-${dist_target}.tar.xz" -o "${tmp}/ghc.tar.xz"
tar -C "${tmp}" -xJf "${tmp}/ghc.tar.xz"
cd "${tmp}/ghc-${ghc}"
build="$(uname -m)-$(uname -s | tr '[:upper:]' '[:lower:]')"
./configure --prefix="${tmp}/usr" --build="${build}" --host="${build}" --target="${target}"
make install
cd "${OLDPWD}"

curl -sSL "https://downloads.haskell.org/~cabal/cabal-install-${cabal}/cabal-install-${cabal}-x86_64-ubuntu-16.04.tar.xz" \
| tar -C "${tmp}/usr" -xJ ./cabal
curl -sSL https://get.haskellstack.org/ | sh -s -- -d "${tmp}/usr/bin"

git clone --depth=1 --no-tags 'https://github.com/haskell/haskell-platform.git' "${tmp}/haskell-platform"
cd "${tmp}/haskell-platform"
CABAL_DIR="${tmp}/.cabal" cabal new-update
CABAL_DIR="${tmp}/.cabal" PATH="${tmp}/usr/bin:${PATH}" ./platform.sh -f "-j$(($(nproc)+1))" \
    "${tmp}/ghc.tar.xz" "${tmp}/usr/bin/cabal" "${tmp}/usr/bin/stack"
cd "${OLDPWD}"

rm -rf "${tmp}"
