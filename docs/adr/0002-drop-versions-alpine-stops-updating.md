---
status: accepted
date: 2026-11-20
---

# Drop PHP versions that are no longer first class

## Context and Problem Statement

These images are meant as a base layer a developer can lean on without auditing it themselves. That promise includes not knowingly keeping unpatched images online. Until now that meant removing an image once its PHP version reached end of life.

The world around that promise has changed. PHP announced both its October 2026 security release (PHP2Shell, CVE-2026-109618/109619) and its November 2026 release in advance, and other projects such as TYPO3 and Next.js announce theirs too. At the same time, AI tooling finds vulnerabilities faster and in larger numbers, and they are patched and exploited faster too. The window between a fix being published and a flaw being exploited is small, so what counts is being able to run a patched version right away.

Alpine updates the PHP packages of a release only while that release is the newest one carrying that PHP version. Once a newer Alpine release drops an old PHP version, that version is no longer a first class citizen: it stays behind on an older Alpine branch, and its security fixes arrive there late or not at all. PHP itself keeps fixing the version until its end of life; the gap is in the Alpine route, not at the source.

PHP 8.2 hit this in November 2026. Alpine 3.22 is the last release that packages it, and on 20 November 2026 it still shipped 8.2.35, without the critical fixes of the 19 November security release, six weeks before 8.2 reaches end of life.

Such a version also fails silently. Scanners that rely on the Alpine secdb, such as Trivy, do not flag it, because the branch never records the fixes it is missing.

What should happen to an image whose PHP version Alpine no longer treats as first class?

## Considered Options

- Stop building the image and remove its tag from Docker Hub.
- Keep building the image, with a warning at the top of the README, until the fixes reach the old Alpine branch or the version reaches end of life.
- Keep building the image with a temporary mitigation and a warning. For 8.2 that meant locking `session.upload_progress.enabled` off in the FPM pool, which blocks CVE-2026-115560.
- Keep the version alive by pulling it from `edge/testing`, where 8.2.36 was built within hours of the release, on top of the stable base from ADR 0001.

## Decision Outcome

Chosen option: stop building the image and remove its tag, because every other option keeps a vulnerable image online.

- A warning in the README reaches almost nobody: users have a `FROM` line they rarely look at, and the scanner they do look at stays silent. The image would scan clean while it is vulnerable.
- A mitigation covers one flaw at a time. For 8.2 it blocked one of several critical CVEs, and the rest had no configuration workaround.
- Pulling from `edge/testing` means the image has to add `edge/testing` to `/etc/apk/repositories`, or every `apk add php82-*` in a user's Dockerfile fails, because the stable base has no PHP 8.2 packages. A version would come from edge early in its life, from stable in the middle and from edge again at the end, which nobody can keep track of.

A PHP version is built as long as Alpine treats it as first class: a maintained stable Alpine release carries it and keeps its packages up to date. Once that stops, the image stops building and its tag is removed, even before the version's end of life. This extends the existing rule of removing images at end of life. The README announces the removal at the top for a while.

### Consequences

- Good, because users on a removed tag get a failing build instead of a silently vulnerable image. Running containers and locally cached images keep working.
- Bad, because a version can disappear weeks or months before its end of life, depending on Alpine's release cycle rather than PHP's.
- Bad, because removing a tag from Docker Hub is a manual step for the maintainer; CI does not do it.
