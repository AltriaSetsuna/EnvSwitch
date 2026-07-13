# Node.js Module

The Node.js module lives at:

```text
modules/node/
```

The default is Node.js 24.18.0, the current LTS release when this definition
was added:

```text
modules/node/default -> versions/node-24.18.0
```

EnvSwitch downloads the official Linux x64 binary archive from nodejs.org and
verifies its SHA256 checksum before extraction. The archive includes `node`,
`npm`, `npx`, and Corepack.

## Platform Requirements

The bundled definition targets Linux x86_64. Node.js 24 officially supports
this platform with Linux kernel 4.18 or newer and glibc 2.28 or newer. Its
official binary also requires `GLIBCXX_3.4.25`, available with GCC 8.1 or
newer. Ubuntu 20.04 and newer meet these requirements; Ubuntu 18.04 does not
because it provides glibc 2.27.

`envswitch fetch node` checks the architecture, kernel, and glibc before
downloading, then runs the extracted binary to verify the installation.

## Environment

When enabled, the Node.js module sets `ENVS_NODE_HOME` and prepends
`$ENVS_NODE_HOME/bin` to `PATH`. It does not set a global npm prefix, so npm's
normal per-project and user configuration continues to apply.

## Commands

```bash
envswitch fetch node
envswitch fetch node 24.18.0
envswitch use node
envswitch use node 24.18.0
envswitch on node
envswitch off node
envswitch default node 24.18.0
envswitch link node 24.18.0 /path/to/node-prefix
```

Omitting the version from `fetch node` or `use node` selects the configured
default. A linked prefix must contain an executable `bin/node`.
