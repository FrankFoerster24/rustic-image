#!/usr/bin/env bash

_error()
{
	echo "Error at: ${1} while executing '${2}'" >&2
}

trap '_error "${LINENO}" "${BASH_COMMAND}"' ERR

set -euo pipefail

main()
{
	apt-get update
	
	case "${TARGETPLATFORM}" in
		"linux/arm64")
			target="aarch64-unknown-linux-musl"
			CC="aarch64-linux-gnu-gcc"
			export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER="${CC}"
			apt-get -y install g++-aarch64-linux-gnu
			;;
		"linux/amd64")
			target="x86_64-unknown-linux-musl"
			CC="x86_64-linux-gnu-gcc"
			export CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER="${CC}"
			apt-get -y install g++-x86-64-linux-gnu
			;;
		"linux/arm/v7")
			target="armv7-unknown-linux-musleabihf"
			CC="arm-linux-gnueabihf-gcc"
			export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_LINKER="${CC}"
			apt-get -y install gcc-arm-linux-gnueabihf
			;;
		*)
			echo "Unsupported target: ${TARGETPLATFORM}" >&2
			exit 1
			;;
	esac
	export CC

	rustup target add "${target}"
	cargo build --release --target "${target}"

	cp -vi "/src/target/${target}/release/rustic" /
}

main "$@"
