set -e
(cd app && flutter build web --no-web-resources-cdn)
firebase deploy --only hosting