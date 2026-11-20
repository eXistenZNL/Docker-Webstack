# 1. Edge images use a stable Alpine base

## Status

Accepted

## Context

A PHP version reaches the Alpine edge repository before any stable Alpine release ships it. To offer that version early, the project publishes `-edge` tags, such as `8.6-edge`.

There are two ways to build such an image:

- Use `alpine:edge` as the base image. Every package, from musl and openssl to nginx, then comes from edge.
- Use the newest stable Alpine release as the base and install only the PHP packages from edge.

The first option looks simpler, and it was chosen once by accident (8.6-edge in #81). It means the whole system moves with edge, which changes daily and does not get the security process of a stable release. Only PHP needs to be ahead; nothing else in the image does.

## Decision

An `-edge` image is based on the newest stable Alpine release, `FROM alpine:<major>.<minor>`. Only the `phpXX-*` packages come from edge, through `apk add --repository`.

- PHP comes from `edge/community` when it is there, and from `edge/testing` when it is not. When a package moves from testing to community, the Dockerfile moves with it.
- When the edge PHP packages need a library the stable base does not have, the build stays red. The last good image stays on Docker Hub until Alpine resolves it. The image does not switch to `alpine:edge`, and it does not pull individual libraries from edge either.
- Once a stable Alpine release ships the PHP version, a regular tag is added. The `-edge` tag keeps building, still with PHP from edge, until the maintainer removes it. There is no fixed period and no announcement: users should move to the regular tag as soon as it exists.

## Consequences

- nginx and the system libraries in an edge image get the same security updates as the regular images.
- Moving from `8.x-edge` to `8.x` keeps the same Alpine base; only the origin of PHP changes.
- Packages in `edge/testing` are built against edge libraries, so an edge image can stop building when edge moves ahead of the stable base. The build matrix uses `fail-fast: false`, so a red edge build does not stop the regular images from being pushed.
- CI rejects any Dockerfile whose base image is not `alpine:<major>.<minor>`.
