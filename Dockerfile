# TODO Flutter sdk is required for now: https://github.com/google/webcrypto.dart/issues/192
# This dockerfile needs to be rebuilt from the ground up once this issue is resolved.
# reference commit 1ae3f381b6f84d5bd6b5e76a7f3530c536f83b50

FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY . .

#get dependencies 
RUN cd snout_db && flutter pub get
RUN cd server && flutter pub get

RUN dart compile exe server/bin/server.dart -o server/server

# Build minimal serving image from AOT-compiled `/server`
# and the pre-built AOT-runtime in the `/runtime/` directory of the base image.
FROM debian:stable-slim
# COPY --from=build /runtime/ /
COPY --from=build /app/server/server /app/server/

# Start server.
EXPOSE 6749
CMD ["/app/server/server"]
