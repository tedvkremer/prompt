# Ted's bash-prompt

**High impact, low footprint.**

This project provides a sophisticated, asynchronous-ready status bar and prompt for Bash, written entirely in pure Bash. It aims to be the sweet spot between minimal prompts (too few features) and heavyweights like Powerlevel10k (too much code/complexity).

* **Fast:** No external binaries, no subshells where possible.
* **Flexible:** A simple DSL for defining segments.
* **Beautiful:** Full color support, glyphs, and layout control.

## USAGE:

### Installation

An automated installer is provided to simplify setup.

```bash
./install.sh
```

This script will:
1. Backup your existing `.bash_prompt` prompt and the prompt library.
2. Install the prompt and library to `.bash_prompt` and `~/.bash_prompt.d` respectively.
3. Does not modify your `.bashrc` file. You must source the prompt in your `.bashrc` file.

### Configuration

The prompt is configured via the `bash_prompt` file. You define **segments** and place them into **regions**.

#### 1. Define Segments

Segments are defined in the `segments` array using a pipe-delimited DSL:

```bash
"name|icon_spec|renderer_function|color_config"
```

* **name**: Unique identifier for the segment (e.g., `git`, `path`).
* **icon_spec**: The emoji/glyph to display, optionally with a width correction (e.g., `📁` or `🖥️:2`).
* **renderer_function**: The Bash function to call to get the content.
* **color_config**: How to color the output.

### Available Renderers

| Renderer | Type | Description |
| :--- | :--- | :--- |
| `render_user` | Simple | Prints the current username. |
| `render_host` | Simple | Prints the short hostname. |
| `render_time` | Simple | Prints the current time (e.g., `Fri Feb 6 08:00pm`). |
| `render_path` | Simple | Prints the current working directory (truncated if long). |
| `render_time_x` | Extended | Prints date and time separated by the icon. |
| `render_path_x` | Extended | Prints path wrapped in brackets with icon on the left. |
| `render_git_x` | Extended | Prints git branch and status (clean/dirty) with conditional coloring. |

#### 2. Choose Your Renderer Style

There are two types of renderers you can write or use:

**A. Simple Renderers**

* **Function:** Returns a single string.
* **Color Config:** A single color (or modifiers like `blue+bold`).
* **Behavior:** The system automatically renders `[Icon] [Output]`.

```bash
# Definition
"user|👤|render_user|blue"

# Function
render_user() { echo "$USER"; }

# Output
👤 user
```

**B. Extended Renderers**

* **Function:** Returns a pipe-delimited string (`part1|part2|part3`).
* **Color Config:** A colon-delimited schema matching the output parts (`color1:color2:color3`).
* **Magic:**
  * Use `@` in the output to place the icon dynamically.
  * Use `text,index` in output + `colorA?colorB` in config for conditional coloring.

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

#### 3. Assign to Regions

Place your segment names into the layout variables:

```bash
left="path|git"
center=""
right="time|user|host"
```

---

## INTERNALS

The architecture adheres to a strict layered design and naming convention to maintain modularity and performance in pure Bash.

### Architecture

The system flows from high-level orchestration down to atomic rendering units.

```text
prompt ---> status_bar --->* regions (left/center/right) --->* segments
```

1.  **Prompt:** The entry point (`prompt_render`) that handles the `PS1` signal.
2.  **Status Bar:** The layout engine (`status_bar_render`) that orchestrates the three horizontal regions.
3.  **Regions:** Logical containers that hold ordered lists of segments.
4.  **Segments:** The atomic units that combine data (renderers) with style (DSL config).

### Coding Standards

The codebase enforces a strict programming style to prevent namespace pollution and ensure predictability.

#### Naming Conventions

*   **Public API:** `module_method` (e.g., `segments_init`, `terminal_to_col`)
    *   Intended for use by other modules or the configuration file.
*   **Private API:** `__module_method` (e.g., `__status_bar_draw`, `__color_map`)
    *   Internal implementation details; not to be called externally.
*   **Variables:** `MODULE_VAR_NAME` (Global config) or `__module_var` (Internal state).

#### Module Lifecycle

Every module follows a standard lifecycle pattern:

1.  **Source:** The module declares its functions and constants.
2.  **Init:** A public `module_init` function sets up internal state (e.g., parsing the segment DSL).
3.  **Runtime:** Public `module_render` or utility functions perform the work.

### Module Reference

| Module | Role | Public API | Private Implementation |
| :--- | :--- | :--- | :--- |
| `bash_prompt` | **Configuration** | N/A | Sources modules, defines config variables. |
| `prompt` | **Controller** | `prompt_init`, `prompt_render` | `__prompt_ps1` |
| `status_bar` | **Layout Engine** | `status_bar_init`, `status_bar_render` | `__status_bar_build`, `__status_bar_draw` |
| `segments` | **Component Logic** | `segments_init`, `segments_render` | `__segments` (registry map) |
| `renderers` | **Data Providers** | `render_*` | N/A |
| `terminal` | **I/O & Cursor** | `terminal_to_col`, `terminal_save_cursor` | N/A |
| `color` | **Styling** | `color_init` | `__color_map` |
