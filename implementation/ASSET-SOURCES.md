# Reused design assets

The workflow machines, carrier bee, artifact forms, isometric grid treatment,
surface docks, and lift/carry/land motion grammar are adapted from the
Ivan-owned HiveDev site at commit `47e096da93e1c7aa0be8195401bc5f8f75d96c99`:

- `exporter/overlay/app/views/demo/_landing_factory.html.erb`
- `exporter/overlay/app/views/demo/_factory_intake.html.erb`
- `exporter/overlay/app/views/demo/_factory_bee.html.erb`
- `src/landing-line.mjs`
- `src/landing.css`

They are original native SVG/HTML/CSS/JS assets, not newly generated raster
art or a new diagram library. The shared renderer here removes the fixed
nine-station assumptions and the original coding-only panel bindings.

`assets/fonts/SpaceGrotesk.woff2` is copied from the same site's `src/fonts/`.
Its SIL Open Font License is retained beside it as `assets/fonts/OFL.txt`.

The compact agent-choice section follows the composition of the Tessl
screenshot supplied by Ivan during implementation: copy on the left, a small
agent grid on the right. Only Hive-supported agent names are used; no Tessl
assets, unsupported brand claims, or invented logos are included.

Framework capability and workflow data were checked against the public Hive
v0.8.0 release, not the dirty local framework checkout. See the implementation
report for exact verification and remaining limitations. The older overlapping
website PRs #11 and #12 were read as context; their code was not imported.

During implementation, Ivan's separate intake feedback narrowed one reuse:
`machine-idea` is now a shallow tray with a flat, supported request sheet rather
than the original stepped pedestal and upright sheet. The original isometric
vocabulary and continuous carrier handoff remain; the other machines are intact.
