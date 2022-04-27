# Welcome to Oreka, an open media capture and retrieval platform

> - Copyright (C) 2005, Orecx LLC: http://www.orecx.com
> - Modified and Distributed by: InterActiveTel LLC: http://interactivetel.com
> - Forked from: https://github.com/OrecX/Oreka
> - Another Interesting Fork: https://github.com/voiceip/oreka


## Directory Structure

This directory contains the scripts to build ***OrkAudio*** from source and create a release package. Here is a brief description of each of them:

- `conf/`: Our configuration files for `OrkAudio`
- `dist/`: Pre/Post installation scripts for `rpm` and `deb` packages
- `docs/`: User, Administrator and Developer documentation
- `pcaps/`: Packet captures used for testing
- `devel.sh`: script to build `OrkAudio` in development mode
- `gdb-root.sh`: wrapper script to run `gdb` debugger as root
- `install.sh`: Build `OrkAudio` from source and install it at the specified location
- `lib.sh`: Utility library
- `make-pkg.sh`: Creates a release package (`rpm` or `deb`)
- `sync.sh`: Download upstream changes
- `uninstall.sh`: Uninstall `OrkAudio` from the system

## How to build/install `OrkAudio` from source
`install.sh`: Without parameters it will install `OrkAudio` and all its depencencies to `/usr` by default
`install.sh /path/to/dir`: Will install `OrkAudio` at the specified location, usefull for staged installs

## How to uninstall `OrkAudio`
`uninstall.sh`: Without parameters it will install `OrkAudio` and all its depencencies to `/usr` by default
`install.sh /path/to/dir`: Will install `OrkAudio` at the specified location, usefull for staged installs

## How to make a release package (`rpm` or `deb`)
`make-pkg.sh`: Run this script in the desired linux distribution, it will automatically create a `deb` or `rpm` package

## How to download upstream changes
`sync.sh`: Just run the script and it will download any changes from upstream repository

## Dependencies
**Dependencies**: `apr`, `pcap`, `boost`, `xerces-c`, `libsndfile`, `speex`, `log4cxx`, `openssl`, `opus`, `silk`, `bcg729`

### Where to get the original libraries

- **Boost**: <https://www.boost.org/users/download/>
- **Opus**: <https://github.com/xiph/opus.git>
- **SILK**: <https://github.com/gaozehua/SILKCodec>
- **G729**: <https://github.com/BelledonneCommunications/bcg729>

Also, a copy of the working version of these libraries are at [**_Interactivetel Repository_**](https://packages.interactivetel.com). The installer will pull them from here.

## Additional Documentation

### OrecX
https://files.orecx.com/docs/

### Packet Encapsulation:
- <https://github.com/fmadio/pcap_decap>
- <https://github.com/thefloweringash/tzsp2pcap>
- <https://github.com/rs/tzsp>
- <https://web.archive.org/web/20050404125022/http://www.networkchemistry.com/support/appnotes/an001_tzsp.html>
- <https://ccie-or-null.net/tag/vntag/>
- <https://learnduty.com/articles/vn-tag-explained-configuration/>
