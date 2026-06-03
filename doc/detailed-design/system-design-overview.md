# System Design Overview

## Design Philosophy

Based on user requirements, NAOS follows these core design principles:

### 1. Lightweight Design

NAOS achieves a lightweight system by minimizing both the root filesystem and applications:

- Use a lightweight base system: Alpine Linux
- Minimize and trim both rootfs and applications
- Optimize the kernel so it includes only required drivers and features
- Avoid loadable modules by statically compiling key components into the kernel

### 2. Security and Compliance

NAOS builds a complete protection model from hardware up to the application layer:

- **Secure boot**: protect firmware and boot-stage integrity by using the RK3588 FIT verification model
- **Full-disk encryption**: use Device-Mapper-Verity based protection to secure user data and system storage
- **Compliance**: restrict UART and SSH access and use certificate-based authentication

### 3. System Stability and Reliability

NAOS is designed for stable operation in long-running unattended scenarios:

- Support seamless A/B upgrades and automatic rollback
- Provide factory-test and automated test support
- Support unattended operation through watchdog and panic recovery
- Use a hardware abstraction design that can scale across boards

### 4. Modular and Process-Driven Build

NAOS structures its build flow for modularity and automation:

- **Separated build stages**: U-Boot, kernel, rootfs, and applications are built independently
- **Unified management**: APK is used for packaging and versioning applications, kernel modules, and system components
- **Automated pipeline**: CI/CD drives the full flow from source to image
- **Operational convenience**: support OTA, offline upgrade, and batch deployment

### 5. Ease of Management

NAOS provides practical tooling for deployment and maintenance:

- Use APK tooling to package and manage applications, U-Boot, kernel, and rootfs
- Provide an image generator for fast creation of deployable images
- Expose chip-independent GPIO interfaces to improve application portability

---
