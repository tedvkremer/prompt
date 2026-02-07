# "TED'S PROMPT" - Simple, extensible & robust Bash-prompt

**High impact, low footprint.**

This project provides a sophisticated, asynchronous-ready status bar and prompt for Bash, written entirely in pure Bash. It aims to be the sweet spot between minimal prompts (too few features) and heavyweights like Powerlevel10k (too much code/complexity).

- **Fast:** No external binaries, no subshells where possible.
- **Flexible:** A simple DSL for defining segments.
- **Beautiful:** Full color support, glyphs, and layout control.

**Why another prompt library?**

This project favors:

1. Plain Bash over heavy frameworks.
2. A small, predictable DSL over long config files.
3. A layered architecture that keeps rendering fast and hackable.

## 1. USAGE:

### 1.1 Quick start

#### 1.1.1 Install

```bash
./install.sh
```

#### 1.1.2 Enable 

Add to `~/.bashrc` or `~/.bash_profile`:

```bash
[ -r "$HOME/.bash_prompt" ] && source "$HOME/.bash_prompt"
```

This installer script will:

1. Backup your existing `.bash_prompt` prompt and the prompt library.
2. Install the prompt and library to `.bash_prompt` and `~/.bash_prompt.d` respectively.
3. Does not modify your `.bashrc` file. You must source the prompt in your `.bashrc` file.

#### 1.1.3 Compatibility

1. Bash 4.3+ required (uses associative arrays and `local -n`).
2. Requires standard CLI tools: `tput`, `date`, `git`, `id`.
3. Icon widths are not universally knowable across fonts. Use `glyph:width` to tune for your setup.

#### 1.1.4 Troubleshooting

1. **Prompt not showing**: confirm your shell sources `~/.bash_prompt`.
2. **Status bar overlaps**: terminal must support `tput csr`; try a different terminal or disable the bar.
3. **Git segment missing**: ensure `git` is installed and you are inside a repo.
4. **Weird glyph spacing**: adjust icon width in `icon_spec` (e.g., `🖥️:2`).

### 1.2 Configuration

The prompt is configured via the `bash_prompt` file. You define **segments** and place them into **regions**.

```bash
#!/usr/bin/env bash

# 1. Load the prompt library
PROMPT_DIR="$HOME/.bash_prompt.d"
for f in "$PROMPT_DIR"/*.sh; do
  [ -r "$f" ] && source "$f"
done

# 2. Define segments, region assignments & prompt color
segments=(
  "path|📁|render_path_x|none:gray:olive:gray"
  "git|🌿|render_git_x|none:brown+bold:gray:lime?coral:gray"
  "user|👤|render_user|blue"
  "host|🖥️:2|render_host|purple"
  "time|🕐|render_time_x|turquoise:none:coral"
)
left="path|git"
center="time"
right="user|host"
prompt="orange"

# 3. Initialize the prompt
prompt_init segments "$left" "$center" "$right" "$prompt"
```

Segments are defined in the `segments` array using a pipe-delimited DSL:

```bash
"name|icon_spec|renderer_function|color_config"
```

- **name**: Unique identifier for the segment (e.g., `git`, `path`).
- **icon_spec**: The emoji/glyph to display, optionally with a width correction (e.g., `📁` or `🖥️:2`).
- **renderer_function**: The Bash function to call to get the content.
- **color_config**: How to color the output.

Segments are assigned regions via `left`, `center` and `right`. 

```bash
left="path|git"
center=""
right="time|user|host"
```

Prompt color is set with `prompt`.

### 1.3 Color

Following is a list of available colors. A color may have a bold assigned to it via `+bold`. The color `none` is used for segment parts that don't have color.

| Color |
| :---- |
| `orange` |
| `blue` |
| `yellow` |
| `green` |
| `bright_green` |
| `red` |
| `gray` |
| `white` |
| `purple` |
| `cyan` |
| `magenta` |
| `pink` |
| `teal` |
| `lime` |
| `brown` |
| `maroon` |
| `navy` |
| `olive` |
| `indigo` |
| `coral` |
| `turquoise` |

### 1.4 Renderers

| Renderer        | Type     | Description                                                           |
| :-------------- | :------- | :-------------------------------------------------------------------- |
| `render_user`   | Simple   | Prints the current username.                                          |
| `render_host`   | Simple   | Prints the short hostname.                                            |
| `render_time`   | Simple   | Prints the current time (e.g., `Fri Feb 6 08:00pm`).                  |
| `render_path`   | Simple   | Prints the current working directory (truncated if long).             |
| `render_time_x` | Extended | Prints date and time separated by the icon.                           |
| `render_path_x` | Extended | Prints path wrapped in brackets with icon on the left.                |
| `render_git_x`  | Extended | Prints git branch and status (clean/dirty) with conditional coloring. |

#### 1.4.1 Simple renderers

- **Function:** Returns a single string.
- **Color Config:** A single color (or modifiers like `blue+bold`).
- **Behavior:** The system automatically renders `[Icon] [Output]`.

```bash
# Definition
"user|👤|render_user|blue"

# Function
render_user() { echo "$USER"; }

# Output
👤 tedvkremer
```

#### 1.4.2 Extended renderers

- **Naming:** Denoted with a trailing `_x`
- **Function:** Returns a pipe-delimited string (`part1|part2|part3`).
- **Color Config:** A colon-delimited schema matching the output parts (`color1:color2:color3`).
- **Conditional Coloring:** Use `colorA?colorB` in config for conditional coloring.
- **Magic:**
  - Use `@` in the output to place the icon dynamically. This allows the color of the icon to be set.
  - Use `text,index` in output + `colorA?colorB` in config for conditional coloring.

```bash
# Definition
"git|🌿|render_git_x|none:gray:lime?coral:gray"

# Function
render_git_x() {
  # ... logic ...
  # Returns: "@| branch | [ | ✓,0 | ]"
  # Schema:  ^    ^      ^    ^     ^
  #          none gray  gray lime  gray
}
```

---

## 2. INTERNALS

### 2.1 Architecture

The system is decomposed into layers of modules, with sctrict areas of concern, driven by a declarative Domain Specific Language (DSL).

Prompt takes a declarative configuration and using status_bar, segments+renderers & terminal+font constructs a PROMPT_COMMAND and PS1.

**The lowest layer:**
terminal.sh and color.sh are stand-alone with no dependencies.

**The component layer:**
status_bar.sh, segments.sh, renderes.sh construct the prompt command from a configuration DSL.

**The controller layer:**
prompt.sh using the other 2 layers creates the status_bar fixed to the top and the simple prompt input line.

**Modules:**
1.  _Configuration_ the prompt configuration using the DSL.
2.  _Prompt_ the controller that orchestrates the layout and segments.
3.  _Status Bar_ builds left, center and right regions.
4.  _Segments_ renders segments and applies style from the DSL metadata.
5.  _Renderers_ segment renderers produce the content.
6.  _Terminal_ manages cursor and scroll region control.
7.  _Color_ provides the palette and escape sequences.

```text
          prompt + dsl
---------------------------------
status_bar + segments + renderers
----------------------------------
        terminal    color
```

### 2.2 Coding standard

The codebase employs a strict programming style to prevent namespace pollution and ensure predictability. Naming conventions communicate areas-of-responsibility, public API, and internal information hiding.

- **Module:**
  - `segments`, `color`, `terminal`
  - The modular unit packaged as `module.sh` and API namespace `module_`.
- **Public API:**
  - `segments_init`, `terminal_to_col`
  - Intended for use by consumers of the module.
- **Private API:** 
  - `__status_bar_draw`, `__color_map`
  - Internal implementation details; not to be called externally.
- **Module State:** 
  - `__module_var`
  - Internal module state hidden from consumers.

### 2.3 Module reference

| Module        | Role                | Public API                                | Private Implementation                     |
| :------------ | :------------------ | :---------------------------------------- | :----------------------------------------- |
| `bash_prompt` | **Configuration**   | N/A                                       | Sources modules, defines config variables. |
| `prompt`      | **Controller**      | `prompt_init`, `prompt_render`            | `__prompt_ps1`                             |
| `status_bar`  | **Layout Engine**   | `status_bar_init`, `status_bar_render`    | `__status_bar_build`, `__status_bar_draw`  |
| `segments`    | **Component Logic** | `segments_init`, `segments_render`        | `__segments` (registry map)                |
| `renderers`   | **Data Providers**  | `render_*`                                | N/A                                        |
| `terminal`    | **I/O & Cursor**    | `terminal_to_col`, `terminal_save_cursor` | N/A                                        |
| `color`       | **Styling**         | `color_init`                              | `__color_map`                              |
