# PR #12 acceptance evidence

This directory preserves the bounded R16/U6 evidence for the workflow
documentation change. It contains exactly six browser captures:

- `homepage-how-it-works-desktop-1440x900.png`
- `homepage-how-it-works-mobile-390x844.png`
- `concepts-full-desktop-1440x900.png`
- `concepts-full-mobile-390x844.png`
- `custom-workflows-full-desktop-1440x900.png`
- `custom-workflows-full-mobile-390x844.png`

`browser-acceptance.txt` is the output of `browser-acceptance.js` against the
production `_site` build. The pass covers navigation and heading order,
accessibility-tree names and roles, decorative connector exclusion, visible
keyboard focus, target sizes, 200% reflow, page overflow, long-code-block
containment, and hidden or overlapping workflow content.

`stable-0.6.5-help-transcript.txt` records the released binary's version and
relevant help. `stable-0.6.5-editorial-runtime-transcript.txt` preserves the
full editorial run through rejection, revision, approval, matching SHA-256,
and terminal `done`. `stable-0.6.5-scaffold-transcript.txt` preserves the
separate scaffold inspection. The latest non-draft release was rechecked as
`v0.6.5` on 2026-07-22 after the documentation corrections.
