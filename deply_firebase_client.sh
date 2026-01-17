set -e
# --no-web-resources-cdn ensures canvaskit is local only for offline support https://github.com/flutter/flutter/issues/60069
(cd app && flutter build web --no-web-resources-cdn --pwa-strategy=offline-first --wasm)
firebase deploy --only hosting