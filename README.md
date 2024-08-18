# Multi-architecture Ubuntu Cloud Image Builder for Proxmox

This repository contains a Packer template for building lightweight, flexible Ubuntu cloud images for multiple architectures (AMD64, ARM64, and s390x) that can be easily imported into Proxmox. The images are built automatically via GitHub Actions, tested with Open Policy Agent (OPA) for security compliance, and pushed to both GitHub Packages and the Packer registry.

## Key Features

- Minimal Ubuntu Server cloud images for AMD64, ARM64, and s390x architectures
- Automatically built and tested for security compliance using OPA
- Pushed to GitHub Packages and Packer registry after passing security tests
- No secrets or specific configurations baked into the images
- Designed to be easily imported into Proxmox

## How it Works

1. The Packer template defines minimal Ubuntu cloud image configurations for multiple architectures.
2. GitHub Actions builds the images using QEMU.
3. OPA tests are run to ensure the images meet predefined security policies.
4. If tests pass, the resulting images are pushed to GitHub Packages and the Packer registry.
5. Compressed QCOW2 images are attached to the GitHub release.

## Security Checks

Before pushing, each image is tested against the following security criteria:

- Absence of prohibited packages (e.g., telnet, netcat)
- Absence of known vulnerable packages
- Proper permissions on sensitive files (e.g., /etc/shadow, /etc/passwd)
- Absence of sensitive data (e.g., private keys, API keys, passwords)

If an image fails these checks, it will not be pushed to the registries.

## Using the Images

### From GitHub Packages

1. Pull the image for your desired architecture from GitHub packages:
   ```
   docker pull ghcr.io/<your-github-username>/ubuntu-cloud-base-<arch>:latest
   ```
   Replace `<arch>` with `amd64`, `arm64`, or `s390x`.

2. Save the image as a raw disk:
   ```
   docker save ghcr.io/<your-github-username>/ubuntu-cloud-base-<arch>:latest | docker run --rm -i -v $PWD:/workdir ubuntu tar xv -C /workdir --strip-components 3 --wildcards '*/layer.tar' > ubuntu-cloud-base-<arch>.raw
   ```

3. Transfer the raw disk to your Proxmox host.

4. Import the disk into Proxmox:
   ```
   qm importdisk <vm-id> ubuntu-cloud-base-<arch>.raw <storage-pool>
   ```

### From Packer Registry

Use the image in your Packer builds:

```hcl
source "proxmox" "vm" {
  ...
  clone_from = "<your-github-username>/ubuntu-cloud-base-<arch>"
  ...
}
```

### From GitHub Releases

1. Download the desired QCOW2 image from the latest release.
2. Transfer the image to your Proxmox host.
3. Import the image into Proxmox:
   ```
   qm importdisk <vm-id> ubuntu-cloud-base-focal-<arch>.qcow2 <storage-pool>
   ```


## Customization

To customize the base images or security policies:

1. Fork this repository.
2. Modify the `ubuntu-cloud.pkr.hcl` file to change VM specifications or add provisioning steps.
3. Update the `policies/image_security.rego` file to modify security policies.
4. Update the GitHub Actions workflow in `.github/workflows/build-and-push.yml` if necessary.
5. Push your changes. GitHub Actions will build, test, and (if tests pass) push the new images for all architectures.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.