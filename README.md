# SyncthingBar

A macOS menu bar status item for [syncthing](https://syncthing.net/).

Requires macOS 10.12 or later.

![syncthingbar](https://cloud.githubusercontent.com/assets/312540/20534205/30e9a3e4-b0d8-11e6-8453-ca749b9fbff2.jpg)

## Syncthing

The syncthing and syncthing-inotify binaries are included in the app. They are copied to ~/Library/Application Support/SyncthingBar when SyncthingBar is first run. If you want to upgrade syncthing at any time, place the updated binaries in this folder.

By default SyncthingBar will run syncthing and syncthing-inotify when it launches. You can turn this off in Preferences.

## Setup

When you first run SyncthingBar you need to set the API key for your installation of syncthing. To obtain your API key open the syncthing UI via the "Open Syncthing" menu, then click "Actions" -> "Settings".

You can also set the URL for connecting to syncthing, though in most cases the default value should work.

## Download

Precompiled binaries are available in the [Releases](https://github.com/nhojb/SyncthingBar/releases) section.
