# camascii

Your camera, typeset live in ASCII. Runs entirely in the browser; frames never leave the device.

Live: https://camascii.avadlabs.workers.dev

- Four character ramps, three inks (paper, safelight, colour), contrast, exposure, invert, mirror
- Expose frames onto a contact sheet, save as PNG or .txt, or copy the text
- Keyboard: space expose, `[` `]` grain, R ramp, I ink, V invert, M mirror, F hold. Wheel or pinch on the finder changes grain.

## Deploy

```sh
npm install
npx wrangler deploy   # runs build.mjs, which inlines public/ into dist/worker.js
```
