# AGENTS.md

Docker base images for PHP web applications: Nginx and PHP-FPM on Alpine Linux, supervised by s6-overlay, published as `existenz/webstack` on Docker Hub. The supported versions are the `*.Dockerfile` files in the root and the matrix in `.github/workflows/build-containers.yml`.

## Building and testing

`make` is the wrapper, and CI uses it too. Every target takes `TAG`, the Dockerfile name without `.Dockerfile`, and `MODE`, either `default` or `rootless`:

```bash
make all TAG=8.5 MODE=rootless   # build, start, test, stop, clean
```

The container listens on host port 8080 in both modes. `make test` checks the health status, the PHP version and the user PHP-FPM runs as. `run-tests-local.sh` runs every version in every mode.

## Dockerfile layout

A Dockerfile has three stages: `base` installs everything, `default` adds port 80 and its health check, and `rootless` strips the user directives, moves nginx to port 8080 and hands the writable paths to `nobody`. `MODE` picks the stage with `--target`, and a rootless image is tagged `<TAG>-rootless`. A build without `--target` produces the rootless image.

The configuration files come from `files/general` (nginx, shared by all versions) and `files/phpXX` (PHP-FPM pool and the s6 service). PID and temp files live in `/tmp`, so the same configuration works in both modes.

## Adding a new PHP version

- Copy the newest Dockerfile and rename `phpXX` throughout, including the `/usr/sbin/php-fpmXX` symlink.
- Add `files/phpXX/` with the s6 service in `etc/services.d/php-fpmXX/` and the FPM configuration in `etc/phpXX/`.
- Add the tag to the CI matrix, to `run-tests-local.sh` and to both tables in `README.md`.
- A version that is only in Alpine edge becomes an `-edge` tag: a stable Alpine base with only the PHP packages from edge. See `docs/adr/0001-edge-images-use-stable-base.md`.

## Removing a PHP version

A version is removed once no maintained stable Alpine release keeps it up to date, not only at its end of life. See `docs/adr/0002-drop-versions-alpine-stops-updating.md`.
