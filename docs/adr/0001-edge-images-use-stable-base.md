---
status: accepted
date: 2026-11-20
---

# Edge images use a stable Alpine base

## Context and Problem Statement

A PHP version reaches the Alpine edge repository before any stable Alpine release ships it. To offer that version early, the project publishes `-edge` tags, such as `8.6-edge`. How should such an image be built?

## Considered Options

- The newest stable Alpine release as the base, with only the PHP packages from edge.
- `alpine:edge` as the base image, so every package, from musl and openssl to nginx, comes from edge. This looks simpler, and it was chosen once by accident (8.6-edge in #81).

## Decision Outcome

Chosen option: the newest stable Alpine release as the base, with only the PHP packages from edge, because only PHP needs to be ahead. With `alpine:edge`, the whole system moves with edge, which changes daily and does not get the security process of a stable release.

An `-edge` image uses `FROM alpine:<major>.<minor>` and installs only the `phpXX-*` packages from edge, through `apk add --repository`.

- PHP comes from `edge/community` when it is there, and from `edge/testing` when it is not. When a package moves from testing to community, the Dockerfile moves with it.
- When the edge PHP packages need a library the stable base does not have, the build stays red. The last good image stays on Docker Hub until Alpine resolves it. The image does not switch to `alpine:edge`, and it does not pull individual libraries from edge either.
- Once a stable Alpine release ships the PHP version, a regular tag is added. The `-edge` tag keeps building, still with PHP from edge, until the maintainer removes it. There is no fixed period and no announcement: users should move to the regular tag as soon as it exists.

### Consequences

- Good, because nginx and the system libraries in an edge image get the same security updates as the regular images.
- Good, because moving from `8.x-edge` to `8.x` keeps the same Alpine base; only the origin of PHP changes.
- Bad, because packages in `edge/testing` are built against edge libraries, so an edge image can stop building when edge moves ahead of the stable base. The build matrix uses `fail-fast: false`, so a red edge build does not stop the regular images from being pushed.
- Neutral: CI rejects any Dockerfile whose base image is not `alpine:<major>.<minor>`.
