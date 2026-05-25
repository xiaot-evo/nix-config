# Cursor & Icon Theme Modules Design

## Summary

Create two feature modules under `modules/features/preference/` providing cursor theme and icon theme configuration as Den aspects. These are templates — the user includes them in their host/user definition to activate theming.

## Cursor Theme (`preference.cursor-theme`)

- **File**: `modules/features/preference/cursor-theme.nix`
- **Aspect**: `den.aspects.preference.cursor-theme`
- **Class**: `homeManager` only (cursor is a user-level preference)
- **Home Manager config**: `home.pointerCursor`
- **Theme**: Bibata-Modern-Classic (from `pkgs.bibata-cursors`)
- **Size**: 24
- **X11 config**: enabled, with `defaultCursor` matching the theme name

The `home.pointerCursor` module auto-generates config for GTK, X11, Sway, and HyprCursor where applicable.

## Icon Theme (`preference.icon-theme`)

- **File**: `modules/features/preference/icon-theme.nix`
- **Aspect**: `den.aspects.preference.icon-theme`
- **Class**: `homeManager` only (icon theme is a user-level preference)
- **Home Manager config**: `gtk.iconTheme`
- **Theme**: Tela (from `pkgs.tela-icon-theme`)

## Usage

Add to the user's `includes` in `modules/hosts/<hostname>/<username>.nix`:

```nix
includes = (with den.aspects; [
  preference.cursor-theme
  preference.icon-theme
  # ... other aspects
]);
```

## Dependencies

- `pkgs.bibata-cursors` — cursor theme package
- `pkgs.tela-icon-theme` — icon theme package

Both are available in nixpkgs-unstable. No new flake inputs required.

## Future Extensibility

These are template modules. Users can:
- Change cursor variant (e.g. `Bibata-Original-Ice`, `Bibata-Modern-Amber`)
- Adjust cursor size
- Swap icon theme (e.g. `papirus-icon-theme`, `adwaita-icon-theme`)
- Add Qt icon theme config via `qt.style` if needed
