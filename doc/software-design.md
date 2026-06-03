# Software Design Specification

## Part I: Core System and Architecture

### Chapter 1: Design Goals

#### 1.1 Project Background

NAOS is a lightweight embedded operating system based on Alpine Linux. It is designed for edge devices and aims to provide a secure, reliable, and maintainable embedded platform.

#### 1.2 Design Principles

The system design follows these core principles:

- **Lightweight**: Minimize image size and resource usage to improve runtime efficiency.
- **Modular**: Use a modular architecture for easier customization and maintenance.
- **Secure**: Build end-to-end protection from hardware up to the application layer.
- **Reliable**: Ensure long-term stable operation for unattended deployments.

---

### Chapter 2: System Architecture Overview

#### 2.1 Hardware Abstraction for Image Building

NAOS uses Shell scripts to implement a hardware abstraction layer for image building. Borrowing the layered idea from Yocto, the build scripts select the correct hardware configuration based on parameters and automatically build images for the target platform. This design decouples hardware configuration from build flow and makes it easier to support multiple boards.

**Detailed design**: See [Modular Build, Unified Management, and Operations](./detailed-design/modular-build-and-operations.md).

#### 2.2 Logical Pin Abstraction

By adding the `gpio-name` property to GPIO nodes in the device tree (DTS), NAOS provides chip-independent logical pin abstraction. Applications can access GPIOs by logical names instead of relying on hardware-specific details.

**Detailed design**: See [Modular Build, Unified Management, and Operations](./detailed-design/modular-build-and-operations.md).

---

### Chapter 3: Lightweight Operating System Design

#### 3.1 Alpine RootFS Selection and Customization

NAOS uses Alpine Linux as the base root filesystem. Alpine is built on musl libc and BusyBox, which keeps the system small and efficient. For applications that require glibc, container-based compatibility can be used.

**Detailed design**: See [Lightweight Design](./detailed-design/lightweight-design.md).

#### 3.2 Package Management Design

NAOS adopts Alpine APK package management to unify software packaging and distribution. This separates compilation from deployment and significantly improves image build efficiency.

**Detailed design**: See [Modular Build, Unified Management, and Operations](./detailed-design/modular-build-and-operations.md).

---

## Part II: Security and Compliance

### Chapter 4: Hardware and Boot Security

#### 4.1 Secure Boot

On RK3588, secure boot is implemented with FIT image verification and OTP-stored key hashes to establish a chain of trust and ensure firmware integrity and authenticity.

**Detailed design**: See [Security and Compliance Design](./detailed-design/security-and-compliance-design.md).

#### 4.2 Full-Disk Encryption

NAOS uses a Device-Mapper-Verity based protection scheme and stores keys in the eMMC RPMB partition to protect data at rest.

**Detailed design**: See [Security and Compliance Design](./detailed-design/security-and-compliance-design.md).

---

### Chapter 5: Access Control

#### 5.1 UART Access Control

NAOS improves security by disabling standard getty services and mounting the root filesystem read-only where appropriate, limiting UART access in production scenarios.

**Detailed design**: See [Security and Compliance Design](./detailed-design/security-and-compliance-design.md).

#### 5.2 SSH Remote Debugging Hardening

NAOS uses OpenSSH with CA-signed certificates, allowing only clients with valid certificates to connect.

**Detailed design**: See [Security and Compliance Design](./detailed-design/security-and-compliance-design.md).

---

## Part III: Maintenance and Operations

### Chapter 6: Upgrade and Recovery

#### 6.1 A/B Partitioning and Seamless Rollback

NAOS uses the SDK's A/B partition mechanism to support seamless upgrades and automatic rollback on boot failure.

**Detailed design**: See [System Stability and Reliability Design](./detailed-design/system-stability-and-reliability-design.md).

#### 6.2 Upgrade Interface

NAOS provides a unified `upgrade-system` command to simplify software upgrades.

**Detailed design**: See [System Stability and Reliability Design](./detailed-design/system-stability-and-reliability-design.md).

#### 6.3 Offline Upgrade Support

NAOS supports both USB-based offline upgrades and application-assisted local upgrades.

**Detailed design**: See [System Stability and Reliability Design](./detailed-design/system-stability-and-reliability-design.md).

#### 6.4 Batch OTA Upgrades

NAOS uses HawkBit to manage OTA rollouts for multiple devices, including automatic update checks and upgrade execution.

**Detailed design**: See [System Stability and Reliability Design](./detailed-design/system-stability-and-reliability-design.md).

#### 6.5 Factory Reset

NAOS uses an overlay-based design to restore factory defaults by clearing user data while returning the system to a clean baseline.

**Detailed design**: See [System Stability and Reliability Design](./detailed-design/system-stability-and-reliability-design.md).

---

### Chapter 7: System Reliability

#### 7.1 Unattended Operation and Watchdog

Hardware watchdog and kernel panic auto-reboot mechanisms are used to keep the system running reliably in unattended environments.

**Detailed design**: See [System Stability and Reliability Design](./detailed-design/system-stability-and-reliability-design.md).

#### 7.2 Factory Test Interface

NAOS provides a dedicated factory-test mode that boots a test partition from USB and verifies hardware functionality.

**Detailed design**: See [System Stability and Reliability Design](./detailed-design/system-stability-and-reliability-design.md).

---

## Part IV: Development and Quality

### Chapter 8: Tooling and Infrastructure

#### 8.1 Containerization Support

NAOS supports containerized application delivery. Users can package applications and their runtime dependencies, with Docker as the default example, as APK packages so that applications remain decoupled from the system image.

**Detailed design**: See [Modular Build, Unified Management, and Operations](./detailed-design/modular-build-and-operations.md).

#### 8.2 Image Generator

NAOS provides an automated image generation tool that pulls prebuilt components from the APK repository, supports application customization and filesystem encryption, and produces deployable images quickly.

**Detailed design**: See [Image Generator Guide](./user-guide/image-generator-guide.md).

#### 8.3 Automated Build System (CI/CD)

NAOS supports a complete CI/CD flow from source code to final image artifacts.

**Detailed design**: See [Modular Build, Unified Management, and Operations](./detailed-design/modular-build-and-operations.md).

---

## Detailed Document Index

This document is the high-level design specification for NAOS. For implementation details and operational guidance, refer to the documents below.

### Core Design Documents

- [System Design Overview](./detailed-design/system-design-overview.md): overall design concepts and architecture
- [Lightweight Design](./detailed-design/lightweight-design.md): Alpine rootfs selection, system minimization, and kernel optimization
- [Security and Compliance Design](./detailed-design/security-and-compliance-design.md): secure boot, encryption, and access control
- [System Stability and Reliability Design](./detailed-design/system-stability-and-reliability-design.md): A/B upgrades, watchdog, factory test, and recovery
- [Modular Build, Unified Management, and Operations](./detailed-design/modular-build-and-operations.md): build flow, APK management, CI/CD, and GPIO abstraction

### User Guides

- [Build Guide](./user-guide/build-guide.md): build and packaging workflow
- [Cloud Environment Setup](./user-guide/cloud-environment-setup.md): AWS Lightsail, APK repository, and HawkBit deployment
- [APK Package Build Example](./user-guide/apk-package-build-example.md): example application package build flow
- [Image Generator Guide](./user-guide/image-generator-guide.md): image generation workflow
- [GitLab Runner Configuration Guide](./user-guide/gitlab-runner-configuration-guide.md): example runner setup for the GitLab CI pipeline
