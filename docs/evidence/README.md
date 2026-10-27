# P4 Visual Evidence

Add one of the following before submitting P4:

- `p4-contact-flow.png` — screenshot of the empty state, validation message,
  submit loading, and saved-contact state; or
- `p4-contact-flow.mp4` — a 10–20 second screen recording of the same flow.

The automated proof is available in `../p4-state-management.md` and
`test/contact_setup_screen_test.dart`.

## P5 Demo Evidence
Video CRUD dan persistence: <https://youtu.be/JmwPUNWhOu0>

## P8 Responsive UX Evidence

The P8 form screenshots cover the emergency-contact form at 360 × 800 and
800 × 1280. The open variants show the phone field focused in the desktop
browser capture; this browser does not render a mobile software keyboard. The
keyboard inset itself is simulated in the widget test to verify the save action
remains reachable:

- `p8-mobile-keyboard-closed.png`
- `p8-mobile-keyboard-open.png`
- `p8-wide-keyboard-closed.png`
- `p8-wide-keyboard-open.png`

Automated coverage for responsive layout, resize value retention, keyboard
insets, 200% text scaling, and save feedback is in
`../../test/contact_setup_screen_test.dart`.