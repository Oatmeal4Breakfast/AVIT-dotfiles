# Rex keybindings

Rex spells modifiers in the order `ctrl`, `alt`, `shift`, `cmd`.
`cmd` is Command and `alt` is Option.

This file documents the bindings in this Rex package plus Rex's built-in
defaults. Custom bindings live in `init.lua` and `keymaps.lua`.

## Custom bindings

### Pane focus (vim-style)

| Key | Action | What it does |
| --- | --- | --- |
| `ctrl+h` | `pane.focus` | Focus the split to the left |
| `ctrl+j` | `pane.focus` | Focus the split below |
| `ctrl+k` | `pane.focus` | Focus the split above |
| `ctrl+l` | `pane.focus` | Focus the split to the right |

These take precedence over the terminal, so Ctrl+H, Ctrl+J, Ctrl+K, and Ctrl+L
no longer reach programs running in the pane (they would normally be
backspace, newline, kill-line, and clear).

### Floating panes and commands

| Key | Action | What it does |
| --- | --- | --- |
| `cmd+s` | `scratch_float` | Open a floating shell in the focused pane's directory |
| `cmd+g` | `lazygit_float` | Open lazygit in a floating pane |
| `cmd+o` | `open_project` | Pick a project with fzf and open or switch to its session |
| `cmd+e` | `open_in_finder` | Open the focused pane's directory in Finder |

### Overridden Rex default

| Key | Now does | Replaces |
| --- | --- | --- |
| `cmd+g` | `lazygit_float` | Rex's Find Next (`client.find.next`) |

## Rex defaults

### Sessions

| Key | Action | What it does |
| --- | --- | --- |
| `shift+cmd+n` | `session.new` | Create a new session |
| `cmd+k` | `session.switch` | Open the session picker |
| `cmd+r` | `session.refresh` | Refresh the session list |

### Tabs and windows

| Key | Action | What it does |
| --- | --- | --- |
| `cmd+t` | `client.tab.new` | New tab |
| `cmd+w` | `client.close` / `pane.close` | Close the focused pane, else the selected tab, else the window |
| `alt+cmd+w` | `client.tab.close` | Close the selected tab |
| `shift+cmd+w` | `client.window.close` | Close the window |
| `cmd+n` | `client.window.new` | New window |
| `ctrl+tab` | `client.tab.next` | Next tab |
| `ctrl+shift+tab` | `client.tab.previous` | Previous tab |
| `shift+cmd+]` | `client.tab.next` | Next tab |
| `shift+cmd+[` | `client.tab.previous` | Previous tab |
| `cmd+1` … `cmd+9` | `client.tab.goto` | Go to tab 1–9 |
| `ctrl+shift+pageup` | `client.tab.move.backward` | Move tab backward |
| `ctrl+shift+pagedown` | `client.tab.move.forward` | Move tab forward |
| `shift+cmd+s` | `client.tab_style.toggle` | Toggle tab style |
| `ctrl+cmd+f` | `client.window.fullscreen.toggle` | Toggle full screen |
| `cmd+/` | `client.sidebar.toggle` | Toggle the sidebar |
| `cmd+.` | `client.sidebar.activity.toggle` | Toggle the activity view |

### Panes and splits

| Key | Action | What it does |
| --- | --- | --- |
| `cmd+d` | `pane.split.right` | Split right |
| `shift+cmd+d` | `pane.split.down` | Split down |
| `shift+cmd+left` | `pane.split.left` | Split left |
| `shift+cmd+right` | `pane.split.right` | Split right |
| `shift+cmd+up` | `pane.split.up` | Split up |
| `shift+cmd+down` | `pane.split.down` | Split down |
| `cmd+enter` | `pane.split.auto` | Split using the best fit |
| `alt+cmd+left` | `pane.focus.left` | Focus the pane to the left |
| `alt+cmd+right` | `pane.focus.right` | Focus the pane to the right |
| `alt+cmd+up` | `pane.focus.up` | Focus the pane above |
| `alt+cmd+down` | `pane.focus.down` | Focus the pane below |
| `cmd+[` | `pane.focus_previous` | Focus the previous pane |
| `cmd+]` | `pane.focus_next` | Focus the next pane |
| `alt+shift+cmd+left` | `pane.move.left` | Move the pane left |
| `alt+shift+cmd+right` | `pane.move.right` | Move the pane right |
| `alt+shift+cmd+up` | `pane.move.up` | Move the pane up |
| `alt+shift+cmd+down` | `pane.move.down` | Move the pane down |
| `alt+cmd+enter` | `pane.float` | Float the focused pane |
| `shift+cmd+enter` | `pane.zoom` | Zoom the pane or restore it |
| `alt+cmd+m` | `pane.minimize_floating` | Minimize the floating pane |
| `alt+shift+cmd+enter` | `pane.minimize_all_floating` | Minimize all floating panes |

### Navigation and search

| Key | Action | What it does |
| --- | --- | --- |
| `cmd+p` | `pane.go_to` | Go to anything: pane, block, tab, session, agent |
| `cmd+f` | `client.find.open` | Find in the focused pane |
| `cmd+g` | `client.find.next` | Find next — **overridden by `lazygit_float`** |
| `shift+cmd+g` | `pane.go_to_directory` | Go to a directory |
| `shift+cmd+g` | `client.find.previous` | Find previous — Rex documents both this and Go to Directory on the same key |
| `ctrl+cmd+i` | `pane.insert_path` | Insert a path at the cursor |
| `cmd+up` | `client.prompt.previous` | Jump to the previous prompt |
| `cmd+down` | `client.prompt.next` | Jump to the next prompt |
| `cmd+y` | `client.quick_look` | Quick Look the files or links on screen (Bleeding Edge) |

### Keys sent to the terminal

These are Rex defaults that pass the key through to the focused terminal
rather than acting on the Rex UI.

| Key | Action |
| --- | --- |
| `cmd+backspace` | `pane.send_key` |
| `cmd+left` | `pane.send_key` |
| `cmd+right` | `pane.send_key` |
| `alt+left` | `pane.send_key` — word left in most shells |
| `alt+right` | `pane.send_key` — word right in most shells |

### App, display, and fonts

| Key | Action | What it does |
| --- | --- | --- |
| `shift+cmd+p` | `client.palette.toggle` | Open the command palette |
| `cmd+,` | `client.settings` | Open Settings |
| `shift+cmd+,` | `client.diagnostics` | Open Rex Diagnostics |
| `cmd+=` / `shift+cmd+=` | `client.font.increase` | Increase font size |
| `cmd+-` | `client.font.decrease` | Decrease font size |
| `cmd+0` | `client.font.reset` | Reset font size |
| `shift+cmd+u` | `client.update.accept` | Install an available update |
| `alt+shift+cmd+u` | `client.update.accept_when_idle` | Relaunch into the update when idle |
| `shift+cmd+.` | `client.notice.dismiss` | Dismiss a notice |

## Actions without a default shortcut

Some actions are available in the command palette but have no default key.
Notable ones:

- **Reload Config** (`client.config.reload`) — use the command palette.
- **Resize Pane** (`pane.resize`) — use the command palette, or add a binding.
- **Next Session** (`session.next`) and **Previous Session** (`session.previous`).
- **Rename Session** (`session.rename`) and **Close Session** (`session.close`).
- **Rename Pane** (`pane.rename`) and **Rename Tab** (`client.tab.rename`).
- **New Floating Pane** (`pane.new_floating`).
- **Change Shortcut…** (`client.shortcuts.edit`) — edit shortcuts from the app.

To see the live keymap after changing the config, run:

```sh
rex keymap
```

To reload after editing `init.lua`, use **Reload Config** in the command palette.
