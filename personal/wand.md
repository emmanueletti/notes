# Wand

Wand is both a setup of my computer to my perfect working environment as well as my agent harness.

## Design
1. Wand setsup and lints the machine as a workbench not storage
- no credentials or sensitive data on disk
  - e.g ssh secrets, application credentials, documents, etc.
  - nothing for prompt injection attacks to exfiltrate

2. Agent harness is minimal

## Arch linux setup decisions

- change tty font to the largest option
- wire up btrfs snapshotting on every package manager interaction
- remote backups - figure out how to implement 1,2,3
- install both linux and linux-lts for backup
