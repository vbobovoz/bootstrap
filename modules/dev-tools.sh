#!/usr/bin/env bash

# Official Linux releases. macOS uses Homebrew. Existing compatible tools stay.
readonly NODE_VERSION="26.13.0"
readonly GO_VERSION="1.27.3"
readonly HELM_VERSION="4.3.1"
readonly TREE_SITTER_VERSION="0.27.1"

linux_tool_arch() {
    case "$(uname -m)" in
        x86_64) printf '%s\n' amd64 ;;
        aarch64|arm64) printf '%s\n' arm64 ;;
        *) die "Unsupported Linux architecture: $(uname -m)" ;;
    esac
}

node_version_ok() {
    local current
    current="$(node --version 2>/dev/null || true)"
    [[ "$current" != *-* ]] && version_at_least "${current#v}" "$NODE_VERSION"
}

install_node() {
    if [[ "$DISTRO" == ubuntu ]]; then
        install_ubuntu_node
    elif [[ "$DISTRO_FAMILY" == macos ]]; then
        pkg_install nodejs
        if ! node_version_ok; then brew upgrade node; fi
    else
        pkg_install nodejs npm
    fi
    hash -r
    node_version_ok || die "Node.js ${NODE_VERSION}+ is required; an older Node may be first on PATH (check nvm/asdf/mise)"
    command_exists npm || die "npm is missing from PATH"
    ok "Node.js $(node --version) / npm $(npm --version)"
}

install_ubuntu_node() {
    local arch tmp checksum target node_arch
    arch="$(linux_tool_arch)"
    tmp="$(mktemp -d)"
    if ! node_version_ok; then
        node_arch="$arch"
        [[ "$arch" != amd64 ]] || node_arch=x64
        case "$arch" in
            amd64) checksum="5848553868b402d3fabb5b09270649977780a390f832155721025a08b5104455" ;;
            arm64) checksum="439e9c438acdf6a6ffe47418da709153d66c4bed812e30a473faacb107dd2791" ;;
        esac
        target="/opt/bootstrap/node-${NODE_VERSION}"
        download_verified "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${node_arch}.tar.gz" "$checksum" "$tmp/node.tar.gz"
        run_sudo mkdir -p "$target" /usr/local/bin
        run_sudo tar -xzf "$tmp/node.tar.gz" -C "$target" --strip-components=1
        run_sudo ln -sfn "$target/bin/node" /usr/local/bin/node
        run_sudo ln -sfn "$target/bin/npm" /usr/local/bin/npm
        run_sudo ln -sfn "$target/bin/npx" /usr/local/bin/npx
    fi

    rm -rf "$tmp"
    hash -r
}

install_ubuntu_dev_tools() {
    install_node
    local arch tmp checksum target ts_arch current
    arch="$(linux_tool_arch)"
    tmp="$(mktemp -d)"

    current="$(go version 2>/dev/null | awk '{sub(/^go/, "", $3); print $3}' || true)"
    if ! version_at_least "$current" 1.26.0; then
        case "$arch" in
            amd64) checksum="65efbc80fdc1fa2cd2631cad5b481777a68e8725f34e89f50fc6ac714e379b40" ;;
            arm64) checksum="a06e99309dbcbdca1a8ccd2282c3ee146e55930886e26b4f1193269587165f49" ;;
        esac
        target="/opt/bootstrap/go-${GO_VERSION}"
        download_verified "https://go.dev/dl/go${GO_VERSION}.linux-${arch}.tar.gz" "$checksum" "$tmp/go.tar.gz"
        run_sudo mkdir -p "$target"
        run_sudo tar -xzf "$tmp/go.tar.gz" -C "$target" --strip-components=1
        run_sudo ln -sfn "$target/bin/go" /usr/local/bin/go
        run_sudo ln -sfn "$target/bin/gofmt" /usr/local/bin/gofmt
    fi

    if ! command_exists helm; then
        case "$arch" in
            amd64) checksum="0403a88ae20913d11b10a2467b50087721fea7581736da6b9d3992f5357fe54b" ;;
            arm64) checksum="8cf8f66ecbc252ac8f7f06cca68aba88508ddfde3a6a34feb1678ad1694b4f88" ;;
        esac
        download_verified "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${arch}.tar.gz" "$checksum" "$tmp/helm.tar.gz"
        tar -xzf "$tmp/helm.tar.gz" -C "$tmp"
        run_sudo install -m 0755 "$tmp/linux-${arch}/helm" /usr/local/bin/helm
    fi

    current="$(tree-sitter --version 2>/dev/null | awk '{print $2}' || true)"
    if ! version_at_least "$current" 0.26.1; then
        ts_arch="$arch"
        [[ "$arch" != amd64 ]] || ts_arch=x64
        case "$arch" in
            amd64) checksum="d01042f94ba3d6827ddc9788e235f75d8366431be42bdf90ade534d960c98b7d" ;;
            arm64) checksum="404be5d54a4955571c4067c21d4699660eab3a534cefb0659341b207f7139ec5" ;;
        esac
        download_verified "https://github.com/tree-sitter/tree-sitter/releases/download/v${TREE_SITTER_VERSION}/tree-sitter-linux-${ts_arch}.gz" "$checksum" "$tmp/tree-sitter.gz"
        gzip -dc "$tmp/tree-sitter.gz" > "$tmp/tree-sitter"
        run_sudo install -m 0755 "$tmp/tree-sitter" /usr/local/bin/tree-sitter
    fi

    hash -r
    rm -rf "$tmp"
    node_version_ok || die "Node.js ${NODE_VERSION}+ must be first on PATH"
    version_at_least "$(go version | awk '{sub(/^go/, "", $3); print $3}')" 1.26.0 || die "Go 1.26+ must be first on PATH"
    version_at_least "$(tree-sitter --version | awk '{print $2}')" 0.26.1 || die "Tree-sitter CLI 0.26+ must be first on PATH"
}
