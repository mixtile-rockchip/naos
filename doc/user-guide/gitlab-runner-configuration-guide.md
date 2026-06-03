# GitLab Runner Configuration Guide

This document describes the example GitLab Runner setup used by this repository and explains how each runner maps to the CI pipeline.

## 1. Related Files

- `misc-tools/gitlab-runner/config.example.toml`: GitLab Runner configuration template

## 2. Runner Mapping

The CI configuration under `.gitlab-ci/` uses three runner tags:

- `my-server-builder`: used for the `build` stage
- `apk-builder-runner`: used for the `apkbuild` stage
- `aws-upload`: used for the `upload` stage

The example `config.example.toml` provides one runner definition for each of these tags.

### 2.1 Build Runner

- image: `ghcr.io/mixtile-rockchip/ubuntu-build-env:latest`
- purpose: build full firmware and image artifacts
- notes: requires `privileged = true`, `/dev`, and Docker socket mounting

### 2.2 APK Build Runner

- image: `ghcr.io/mixtile-rockchip/alpine-build:latest`
- purpose: build Alpine APK packages
- notes: keeps Docker socket access and the shared cache directory mount

### 2.3 Upload Runner

- image: `ghcr.io/mixtile-rockchip/awscli:alpine-3.16`
- purpose: upload APK artifacts to S3 and trigger repository index refresh
- notes: this image already includes both `aws-cli` and `curl`

## 3. Usage

### 3.1 Copy the Template

Copy the template to the actual GitLab Runner configuration path:

```bash
cp misc-tools/gitlab-runner/config.example.toml /etc/gitlab-runner/config.toml
```

### 3.2 Replace the Placeholders

Update the following values in `/etc/gitlab-runner/config.toml`:

- `https://gitlab.example.com/`
- `REPLACE_WITH_BUILD_RUNNER_TOKEN`
- `REPLACE_WITH_APKBUILD_RUNNER_TOKEN`
- `REPLACE_WITH_UPLOAD_RUNNER_TOKEN`

### 3.3 Confirm Runner Tags

When registering or configuring runners in GitLab, make sure the tags match the CI configuration:

- `my-server-builder`
- `apk-builder-runner`
- `aws-upload`

## 4. Notes

- Do not commit real runner tokens, hostnames, or generated runner IDs into the repository.
- The example template keeps only the fields actually needed by this project. GitLab Runner will generate additional runtime fields automatically.
