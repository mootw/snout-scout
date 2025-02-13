set -e
(cd app && flutter build web --wasm)
firebase deploy --only hosting