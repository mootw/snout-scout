# Use latest stable channel SDK.
FROM dart:stable AS build

WORKDIR /app
COPY . .

#get dependencies 
RUN cd snout_db && dart pub get
RUN cd server && dart pub get


RUN dart compile exe server/lib/server.dart -o server/server

# Build minimal serving image from AOT-compiled `/server`
# and the pre-built AOT-runtime in the `/runtime/` directory of the base image.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/server/server /app/server/

# Start server.
EXPOSE 6749
CMD ["/app/server/server"]
