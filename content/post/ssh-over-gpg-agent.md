---
title: SSH Over GPG Agent
date: 2022-03-13 00:02:12
updated: 2022-03-13 00:02:12
categories: QuickNotes
tags: 
    - setup
---

This is a quick note of `gpg-agent` setup for SSH.

# Quick Setup
1. Import your GPG authentication key.
2. Enable SSH support for `gpg-agent`.
```bash
$ echo enable-ssh-support >> $HOME/.gnupg/gpg-agent.conf
```
3. Get the authentication keygrip.
```bash
$ gpg -k --with-keygrip
```
4. Add the authentication key to the keychain (replace `KEYGRIP` with the value obtained from the previous step)
```bash
$ echo KEYGRIP >> $HOME/.gnupg/sshcontrol
```
5. Add the following init code to `.bashrc`
```bash
unset SSH_AGENT_PID
export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
export GPG_TTY="$(tty)"
gpg-connect-agent updatestartuptty /bye > /dev/null
```
6. Kill any running `ssh-agent` and `gpg-agent`, and then open a new Bash session.

# Misc
## Export SSH Public Keys
```bash
$ gpg --export-ssh-key <uid/fingerprint>
```
