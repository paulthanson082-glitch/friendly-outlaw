# Binary Assets

All files go in `app/src/main/assets/bin/`. Replace the stub placeholders with real ARM64 static binaries before release.

---

## frida-server-arm64

**Source:** https://github.com/frida/frida/releases

1. Find the latest stable release.
2. Download `frida-server-{version}-android-arm64.xz`.
3. Decompress: `xz -d frida-server-{version}-android-arm64.xz`
4. Rename the output to `frida-server-arm64`.
5. Verify: `file frida-server-arm64` should report `ELF 64-bit LSB executable, ARM aarch64`.

---

## nmap-arm64

**Source:** Kali NetHunter packages or a trusted static ARM64 build.

1. Obtain a statically linked ARM64 nmap binary for Android (e.g., from the Kali NetHunter project at https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-project).
2. Save the binary as `nmap-arm64`.
3. Verify: `file nmap-arm64` should report `ELF 64-bit LSB executable, ARM aarch64`.

---

## busybox-arm64

**Source:** https://busybox.net/downloads/binaries/

1. Navigate to the latest directory listing (e.g., `https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/` — pick the ARM64 variant).
2. Download the ARM64 static binary: `busybox-armv8l` or equivalent.
3. Rename to `busybox-arm64`.
4. Verify: `file busybox-arm64` should report `ELF 64-bit LSB executable, ARM aarch64`.

---

## Placement

All three files must reside at:

```
app/src/main/assets/bin/frida-server-arm64
app/src/main/assets/bin/nmap-arm64
app/src/main/assets/bin/busybox-arm64
```

`BinaryManager.ensureBinaries()` copies them to `context.filesDir/bin/` on first launch (or when the app version changes) and marks them executable via `chmod +x`.
