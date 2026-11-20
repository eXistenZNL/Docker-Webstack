# 2. Drop a PHP version once Alpine no longer treats it as first class

## Status

Accepted

## Context

These images are meant as a base layer a developer can lean on without auditing it themselves. That promise includes not knowingly keeping unpatched images online. Until now that meant removing an image once its PHP version reached end of life.

The world around that promise has changed. PHP announced both its October 2026 security release (PHP2Shell, CVE-2026-109618/109619) and its November 2026 release in advance, and other projects such as TYPO3 and Next.js announce theirs too. At the same time, AI tooling finds vulnerabilities faster and in larger numbers, and they are patched and exploited faster too. The window between a fix being published and a flaw being exploited is small, so what counts is being able to run a patched version right away.

Alpine updates the PHP packages of a release only while that release is the newest one carrying that PHP version. Once a newer Alpine release drops an old PHP version, that version is no longer a first class citizen: it stays behind on an older Alpine branch, and its security fixes arrive there late or not at all. PHP itself keeps fixing the version until its end of life; the gap is in the Alpine route, not at the source.

PHP 8.2 hit this in November 2026. Alpine 3.22 is the last release that packages it, and on 20 November 2026 it still shipped 8.2.35, without the critical fixes of the 19 November security release, six weeks before 8.2 reaches end of life.

The alternative was to keep the version alive by pulling it from `edge/testing`, where 8.2.36 was built within hours of the release, on top of the stable base from ADR 0001. That was rejected: the image then has to add `edge/testing` to `/etc/apk/repositories`, or every `apk add php82-*` in a user's Dockerfile fails, because the stable base has no PHP 8.2 packages. A version would come from edge early in its life, from stable in the middle and from edge again at the end, which nobody can keep track of.

## Decision

A PHP version is built as long as Alpine treats it as first class: a maintained stable Alpine release carries it and keeps its packages up to date. Once that stops, the image stops building and its tag is removed from Docker Hub, even before the version's end of life. This extends the existing rule of removing images at end of life.

The README announces the removal at the top for a while.

## Consequences

- Users on a removed tag get a failing build instead of a silently vulnerable image. Running containers and locally cached images keep working.
- A version can disappear weeks or months before its end of life, depending on Alpine's release cycle rather than PHP's.
- Removing a tag from Docker Hub is a manual step for the maintainer; CI does not do it.
