# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [12.7.0] - 2012-07-07

### Added

- Partitioning from a blank disk (drive is wiped).
- Specify partition sizes in MB, GB, % of remaining, or + (all remaining).
- Creation of md raid arrays.
- Creation of lvm2 volumes.
- Ability to format partitions as ext2, ext3, swap, reiserfs, xfs, or jfs.
- Specify local filesystems to be mounted during the install.
- Specify network shares to be mounted during the install.
- Choose your bootloader.
- Automatic bootloader configuration (currently grub, palo, and silo).
- Specify device for bootloader installation.
- Choose your logger (or none).
- Choose your cron daemon (or none).
- Choose your root password (plain-text or pre-encrypted).
- Specify URI for stage 3 tarball (file, http, https, ftp, or rsync).
- Specify method for getting a portage tree (sync, webrsync, or snapshot).
- Specify the directory that is used for the chroot.
- Specify extra packages to be emerged after the base system.
- Specify extra options passed to genkernel.
- Specify URI for pre-made kernel config.
- Choose which kernel sources package to use to build your kernel.
- Choose your timezone.
- Choose which services to add to which runlevels.
- Choose which services to remove from which runlevels.
- Specify basic networking configuration.
- Support for custom code using pre-/post-install step hooks in the config file.  

### Changed

- Config syntax modeled on the [Kickstart](https://en.wikipedia.org/wiki/Kickstart_(Linux)) config syntax.

[unreleased]: https://github.com/oxr463/quickstart/compare/v12.7.0...HEAD
[12.7.0]: https://github.com/oxr463/quickstart/releases/tag/v12.7.0
