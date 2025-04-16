set -e
# --no-web-resources-cdn ensures canvaskit is local only for offline support https://github.com/flutter/flutter/issues/60069
# currently --wasm breaks the password hashing
(cd app && flutter build web --no-web-resources-cdn --pwa-strategy=offline-first)
firebase deploy --only hosting