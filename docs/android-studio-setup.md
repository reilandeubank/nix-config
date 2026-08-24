# Recreating the Android Studio / SDK setup

This system previously had Android Studio, the Android SDK, and related
tooling installed via NixOS. That configuration was removed on 2026-08-23
to slim down the system closure. This document describes how to bring it
back if it's needed again.

## What was removed

From `configuration.nix`:

- The `androidPackages` / `androidSdkRoot` let-bindings that composed a
  custom Android SDK.
- `android-studio`, `android-tools`, and `androidPackages.androidsdk` from
  `environment.systemPackages`.
- `geekbench` from `environment.systemPackages` (unrelated to Android, also
  removed per request).
- `environment.sessionVariables.ANDROID_HOME`.
- `nixpkgs.config.android_sdk.accept_license`.
- The `adbusers` group from the `reilandeubank` user's `extraGroups`.

## How to recreate it

Add the following back to `configuration.nix`.

### 1. Compose the Android SDK (in the `let` block)

```nix
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  androidPackages = pkgs.androidenv.composeAndroidPackages {
    platformVersions = ["34" "35" "36"];
    buildToolsVersions = ["34.0.0" "35.0.0" "36.0.0"];
    includeCmake = true;
    cmakeVersions = ["3.22.1"];
    includeNDK = true;
    ndkVersions = ["27.1.12297006"];
    includeEmulator = true;
  };
  androidSdkRoot = "${androidPackages.androidsdk}/libexec/android-sdk";
in {
  ...
}
```

Adjust `platformVersions`, `buildToolsVersions`, and `ndkVersions` to
whatever's current/needed at the time.

### 2. Add packages to `environment.systemPackages`

```nix
  environment.systemPackages = with pkgs; [
    # ...existing packages...
    android-tools
    android-studio
    androidPackages.androidsdk
  ];
```

### 3. Set `ANDROID_HOME` and accept the SDK license

```nix
  environment.sessionVariables.ANDROID_HOME = androidSdkRoot;

  nixpkgs.config.android_sdk.accept_license = true;
```

### 4. Grant the user adb access

Enable the `adb` program module (this is what actually creates the
`adbusers` group) and add the user to it:

```nix
  programs.adb.enable = true;

  users.users.reilandeubank = {
    # ...
    extraGroups = ["networkmanager" "wheel" "docker" "adbusers"];
  };
```

### 5. Rebuild

```sh
sudo nixos-rebuild switch
```

The first build will take a while since it needs to download/build the SDK
components, platform tools, build tools, NDK, and emulator images.

## Notes

- `androidenv.composeAndroidPackages` pulls a lot of binary blobs from
  Google; expect a large closure size increase (several GB).
- If Android Studio's built-in SDK manager is preferred over the Nix-managed
  SDK, `android-studio` alone (without `androidPackages.androidsdk` /
  `ANDROID_HOME`) can be installed instead, and the SDK managed from within
  the IDE at `~/Android/Sdk`.
