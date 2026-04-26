# Ted's Prompt — Simple, extensible & robust shell prompt

**Prompt Concept, Design & Code**
- by Ted V. Kremer 
- w/ AI guidance for bash-script language and best-practice authority

**Whole Product**
- Guidance by Gemini CLI, Codex CLI & Claude Code
- Installer bash-script by Gemini CLI
- Validation bash-script by Codex CLI
- README.md documentation by Claude Code

[Screenshot of prompt & installer](screenshot.png)

**High impact, low footprint.**

This project provides a sophisticated, asynchronous-ready status bar and prompt for your shell. It aims to be the sweet spot between minimal prompts (too few features) and heavyweights like Powerlevel10k (too much code/complexity).

- **Fast:** No external binaries, no subshells where possible.
- **Flexible:** A simple DSL for defining segments.
- **Beautiful:** Full color support, glyphs, and layout control.

**Why another prompt library?**

This project favors:

1. Plain shell scripts over heavy frameworks.
2. A small, predictable DSL over long config files.
3. A layered architecture that keeps rendering fast and hackable.

---

## 1. USAGE:

### 1.1 Quick start

#### 1.1.1 Install

```bash
./install.sh
```

#### 1.1.2 Enable

Add to your shell startup file:

- Bash: `~/.bashrc` or `~/.bash_profile`
- Zsh: `~/.zshrc`

```bash
[ -r "$HOME/.teds_prompt" ] && source "$HOME/.teds_prompt"
```

This installer script will:

1. Backup your existing `.teds_prompt` prompt and the prompt library.
2. Install the prompt and library to `~/.teds_prompt` and `~/.teds_prompt.d` respectively.
3. Does not modify your shell startup file. You must source the prompt yourself.

#### 1.1.3 Compatibility

1. Bash 4.3+ supported.
2. Zsh 5.1+ supported.
3. Requires standard CLI tools: `tput`, `date`, `git`, `id`.
4. Icon widths are not universally knowable across fonts. Use `glyph:width` to tune for your setup.

#### 1.1.4 Troubleshooting

1. **Prompt not showing**: confirm your shell sources `~/.teds_prompt`.
2. **Status bar overlaps**: terminal must support `tput csr`; try a different terminal or disable the bar.
3. **Git segment missing**: ensure `git` is installed and you are inside a repo.
4. **Weird glyph spacing**: adjust icon width in `icon_spec` (e.g., `🖥️:2`).

### 1.2 Configuration

The prompt is configured via the `teds_prompt` file. You define **segments** and place them into **regions**.

```bash
# 1. Load the prompt library
PROMPT_DIR="$HOME/.teds_prompt.d"
prompt_modules=(
  "$PROMPT_DIR/terminal.sh"
  "$PROMPT_DIR/color.sh"
  "$PROMPT_DIR/renderers.sh"
  "$PROMPT_DIR/segments.sh"
  "$PROMPT_DIR/status_bar.sh"
  "$PROMPT_DIR/prompt.sh"
)

if [ -n "${BASH_VERSION:-}" ]; then
  prompt_modules+=("$PROMPT_DIR/prompt_bash.sh")
elif [ -n "${ZSH_VERSION:-}" ]; then
  prompt_modules+=("$PROMPT_DIR/prompt_zsh.sh")
else
  printf 'Error: unsupported shell\n' >&2
  return 1 2>/dev/null || exit 1
fi

for f in "${prompt_modules[@]}"; do
  [ -r "$f" ] || {
    printf 'Error: required prompt module not readable: %s\n' "$f" >&2
    return 1 2>/dev/null || exit 1
  }
  source "$f"
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
"name|icon_spec|renderer_function|color_metadata"
```

- **name**: Unique identifier for the segment (e.g., `git`, `path`).
- **icon_spec**: The emoji/glyph to display, optionally with a width correction (e.g., `📁` or `🖥️:2`).
- **renderer_function**: The function to call to get the content.
- **color_metadata**: How to color the output.

Segments are assigned regions via `left`, `center` and `right`.

```bash
left="path|git"
center=""
right="time|user|host"
```

Prompt color is set with `prompt`.

### 1.3 Color

Following is a list of available colors. A color may have a bold assigned to it via `+bold`. The color `none` is used for segment parts that don't have color.

**Colors:** `orange`, `blue`, `yellow`, `green`, `bright_green`, `red`, `gray`, `white`, `purple`, `cyan`, `magenta`, `pink`, `teal`, `lime`, `brown`, `maroon`, `navy`, `olive`, `indigo`, `coral`, `turquoise`

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
"user|👤|render_user|green"

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
"git|🌿|render_git_x|none:purple|gray:lime?coral:gray"

# Function
render_git_x() {
  # ... logic ...
  # Returns:" @  | branch | [ | ✓,0 | ]"
  # Schema:   ^      ^      ^    ^    ^
  # Colors: none   purple gray  lime gray
}
```

## 2. INTERNALS

### 2.1 Architecture

The system is decomposed into layers of modules, with strict areas of concern and dependencies, driven by a declarative Domain Specific Language (DSL).

```text
                  ┌───────────────────────────────────┐
    controller    │               prompt              │
                  ├───────────────────────────────────┤
    provider      │      prompt_bash │ prompt_zsh     │
                  ├───────────────────────────────────┤
                  │             status_bar            │
    components    │        + segments + renderers     │
                  │      + domain specific language   │
                  ├───────────────────────────────────┤
    foundation    │        terminal  +  color         │
                  └───────────────────────────────────┘
```

_Dependencies are a DAG, top to bottom only_

**The foundation layer:**
`terminal` and `color` are stand-alone with no dependencies.

**The component layer:**
`status_bar`, `segments`, `renderers` construct & render the prompt command from a configuration DSL.

**The provider layer:**
The shell provider implements the shell-specific hook registration and prompt formatting API consumed by `prompt`. `prompt_bash` serves bash; `prompt_zsh` serves zsh. The correct provider is selected automatically at source time.

**The controller layer:**
`prompt` uses the other layers and the DSL definition to create the `status_bar` fixed to the top of the terminal and a simple prompt input line.

**Modules:**

1.  **prompt:** the controller that orchestrates the layout and segments.
2.  **prompt_bash / prompt_zsh:** shell providers (hook registration, prompt formatting).
3.  **status_bar:** builds left, center and right regions.
4.  **segments:** renders segments and applies style from the DSL metadata.
5.  **renderers:** segment renderers produce the content.
6.  **terminal:** manages cursor and scroll region control.
7.  **color:** provides the palette and escape sequences.

### 2.2 Coding standard

The codebase employs a strict programming style to prevent namespace pollution and ensure predictability. Naming conventions communicate areas-of-responsibility, public API, and internal information hiding.

- **Module:**
  - `segments`, `color`, `terminal`
  - The modular unit packaged as `module.sh` and API namespace `module_`.
- **Public API:**
  - `segments_init`, `terminal_to_col`
  - Intended for use by consumers of the module.
- **Private API:**
  - `__status_bar_draw`
  - Internal implementation details; not to be called externally.
- **Module State:**
  - `__module_var`
  - Internal module state hidden from consumers.

### 2.3 Module reference

| Module        | Description                                               | Public API                                                                                                                                                                     |
| :------------ | :-------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `prompt`      | the controller that orchestrates the layout and segments. | `prompt_init`                                                                                                                                                                  |
| `prompt_bash` | the bash shell provider.                                  | `__prompt_register_hooks`, `__prompt_format_ps1`                                                                                                                               |
| `prompt_zsh`  | the zsh shell provider.                                   | `__prompt_register_hooks`, `__prompt_format_ps1`                                                                                                                               |
| `status_bar`  | builds left, center and right regions.                    | `status_bar_init`, `status_bar_render`                                                                                                                                         |
| `segments`    | renders segments and applies style from the DSL metadata. | `segments_init`, `segments_render`                                                                                                                                             |
| `renderers`   | segment renderers produce the content.                    | `render_time`, `render_user`, `render_host`, `render_path`, `render_path_x`, `render_time_x`, `render_git_x`                                                                   |
| `terminal`    | manages cursor and scroll region control.                 | `terminal_init`, `terminal_abort`, `terminal_clear`, `terminal_num_cols`, `terminal_to_col`, `terminal_to_start`, `terminal_top_init`, `terminal_top_exit`, `terminal_reserve` |
| `color`       | provides the palette and escape sequences.                | `color_init`, `color_print`                                                                                                                                                    |
