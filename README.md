# Omarchy Headset

[![Omarchy](https://img.shields.io/badge/Omarchy-shell-1f2335?style=for-the-badge)](https://omarchy.org/)
[![Quickshell](https://img.shields.io/badge/Quickshell-plugin-54a3d8?style=for-the-badge)](https://quickshell.org/)
[![License](https://img.shields.io/badge/license-GPL--3.0-green?style=for-the-badge)](LICENSE)

Bar widget for the Omarchy shell for the Logitech G733: battery, sidetone, lights and microphone. It hides itself while the headset is off.

Needs [headsetcontrol](https://github.com/Sapd/HeadsetControl).

## Install

```bash
git clone https://github.com/gabrielsitta4/omarchy-headset ~/Documents/Projetos/omarchy-headset
ln -s ~/Documents/Projetos/omarchy-headset ~/.config/omarchy/plugins/local.headset
mkdir -p ~/.config/omarchy/bar/scripts
ln -s ~/Documents/Projetos/omarchy-headset/headset-battery ~/.config/omarchy/bar/scripts/headset-battery
ln -s ~/Documents/Projetos/omarchy-headset/headset-set ~/.config/omarchy/bar/scripts/headset-set
```

Add `{ "id": "local.headset" }` to a section of `bar.layout` in `~/.config/omarchy/shell.json`.
