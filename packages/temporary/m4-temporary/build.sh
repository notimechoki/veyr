#!/usr/bin/env bash

set -Eeuo pipefail

veyr_pre_configure() {
    mkdir -p "${VEYR_SYSROOT}/usr/share"

    cat > "${VEYR_CONFIG_SITE}" <<'EOF'
ac_cv_func_posix_spawn_file_actions_addchdir=yes
ac_cv_func_posix_spawn_file_actions_addfchdir=yes
EOF
}

source "${VEYR_ROOT}/scripts/lib/temporary-autotools.sh"
