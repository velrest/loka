FROM alpine:3.20
COPY --from=dxflrs/garage:v1.0.1 /garage /usr/local/bin/garage
