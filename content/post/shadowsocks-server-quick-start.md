---
title: Shadowsocks Quick Setup
date: 2022-03-13 00:03:36
updated: 2022-03-13 00:03:36
categories: Tech
tags: 
    - Setup
    - Quick Notes
---

This note is written for my personal convenience.

# Server Setup

## Installation

```
$ sudo pacman -S shadowsocks-libev
```

## Shadowsocks Server Configuration

Config file is located at `/etc/shadowsocks/myserver.json`.

On FreeBSD it is `/usr/local/etc/shadowsocks/myserver.json`

The file name can vary.

```json
{
    "server": "0.0.0.0",
    "server_port": 8388,
    "password": "mypassword",
    "timeout": 300,
    "method": "chacha20-ietf-poly1305",
    "fast_open": false,
    "workers": 1,
    "nameserver": "8.8.8.8"
}
```

**Note**: For server, `"local_address": "127.0.0.1"` and `"local_port": 1080` would cause problems so don't them.

## Start Server (Not Persistent after Restart)

```bash
$ ss-server -c /etc/shadowsocks/myserver.json &
```

## Start Server (As A System Service)

**Note**: The config file name has to be placed after `@`.

```bash
$ sudo systemctl enable shadowsocks-libev-server@myserver
$ sudo systemctl start shadowsocks-libev-server@myserver
```

# Client Helper

## SS Access Key Generation Script (Bash Script)

This script will prompt you to input parameters that are in the config file to generate a base64 encoded link.

```bash
#!/usr/bin/bash
# Usage: this_script.sh
read -p 'Method: ' -r ss_method
read -p 'Password: ' -r ss_password
read -p 'Server IP: ' -r ss_server_ip
read -p 'Server Port: ' -r ss_server_port
echo "ss://" $(printf "${ss_method}:${ss_password}@${ss_server_ip}:${ss_server_port}" | base64)
```

## SS Access Key Generation Script (JavaScript)

This approch requires Node.js but it can parse config file automatically.

```javascript
// Usage: node this_script.js <config_file>
let argv = process.argv.slice(2);
if (argv.length < 1) {
    console.log("nothing");
    return;
}

const fs = require('fs');

let config_file = argv[0];
let config_json = JSON.parse(fs.readFileSync(config_file));
let ss_url = "ss://" + btoa(`${config_json['method']}:${config_json['password']}@${config_json['server'][0]}:${config_json['server_port']}`);
console.log(ss_url);
```
