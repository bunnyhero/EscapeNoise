# Escape Noise

## What it does

It plays a "click" sound when the ESC key is pressed.

## Why

Because I was perturbed by the lack of any kind of haptic or audio feedback on
the soft ESC key on the new MacBook Pro with Touch Bar. Also, I wanted to do a
small project with Swift, which turns out to be a hassle when using some of
the lower-level APIs such as `CGEvent.tapCreate()`.

## Project status

It works for me, but:

- it lacks any sort of UI (or even an app icon!) the sound file is hard-coded
- the keycode it responds to is hard-coded

## To Do

- Preferences:
  - Audio file
  - Audio volume
  - Start at login
- Menu bar status item rather than sitting in the Dock
- App icon
- A better name

