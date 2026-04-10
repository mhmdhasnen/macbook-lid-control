# MacBook Lid Control

Control what happens when your MacBook lid is closed.

`MacBook Lid Control` is a lightweight macOS utility project that monitors lid state and helps support clamshell-style workflows with external displays.

## Features

- Detect lid open/close events
- Lightweight native macOS app
- Simple build and install scripts
- DMG packaging support for distribution
- App icon assets included

## Project Structure

- `Sources/` - Swift source files
- `Sources/LidControllerApp.swift` - App entry point
- `Sources/LidMonitor.swift` - Lid state monitoring logic
- `Sources/Info.plist` - App metadata
- `Assets.xcassets/` - Icon and asset catalog files
- `LidController.app/` - Built app bundle output
- `build.sh` - Build script
- `install.sh` - Local install script
- `package_dmg.sh` - DMG packaging script
- `make_icon.sh` - Icon generation helper

## Requirements

- macOS
- Xcode or Xcode Command Line Tools
- Swift toolchain compatible with your macOS version

## Build

```bash
./build.sh
```

## Install

```bash
./install.sh
```

## Package DMG

```bash
./package_dmg.sh
```

## Usage Notes

- Some lid/sleep behavior is ultimately managed by macOS power policies and hardware rules.
- External display, power adapter, and system settings can affect observed behavior.
- Validate behavior on your specific Mac model before relying on it daily.

## Troubleshooting

- Ensure scripts are executable:
  ```bash
  chmod +x build.sh install.sh package_dmg.sh make_icon.sh
  ```
- If build tools are missing, install Xcode Command Line Tools:
  ```bash
  xcode-select --install
  ```

## Disclaimer

Use at your own risk. Modifying sleep or clamshell-related behavior may impact battery life, thermals, and system stability.

## License

MIT
