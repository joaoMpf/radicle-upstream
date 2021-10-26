#!/bin/bash

# Copyright © 2021 The Radicle Upstream Contributors
#
# This file is part of radicle-upstream, distributed under the GPLv3
# with Radicle Linking Exception. For full terms see the included
# LICENSE file.

source ci/env.sh

log-group-start "Installing yarn dependencies"
yarn install --immutable
log-group-end

if [[ "${RUNNER_OS:-}" == "macOS" ]]; then
	log-group-start "Packaging, notarizing and uploading app binaries"
	(
    # TODO setup notarization
		# export NOTARIZE=true
		# export APPLE_ID="rudolfs@monadic.xyz"
		# export APPLE_ID_PASSWORD="@keychain:AC_PASSWORD"
		# export CSC_NAME="Monadic GmbH (35C27H9VL2)"
		time yarn dist
	)
	log-group-end
else
	log-group-start "Packaging and uploading app binaries"
	time yarn dist
	log-group-end
fi
