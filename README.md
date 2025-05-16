# gdscript-extended-lsp.nim

## Features

- Documentation support for Godot using LSP (inside Neovim or Godot).
- Search documentation class (with auto completion)
- Jump to file on `res://resource/path` with `gf`
- Telescope integration (search for documentation class)

[gdscript-extended-lsp-demo.webm](https://github.com/Teatek/gdscript-extended-lsp.nvim/assets/38403802/0fb814b9-b28d-4399-bcff-81270aa6a36d)

## Installation

⚠️ This plugin does not set up the LSP client. It simply attaches and sets a keymap for "go to definition" (`gd` by default). This way you can customize your own keybindings in your LSP configuration.

If you use this plugin to view documentation inside Neovim (instead of within Godot), it is recommended to have Tree-sitter installed with the markdown and markdown_inline parsers.
While viewing documentation in Neovim, use `gf` to open the class under the cursor.

```lua

-- lazy.nvim
{
  "teatek/gdscript-extended-lsp.nvim", opts = {}
}
```

## Configuration

```lua
{
  doc_file_extension = ".txt", -- Documentation file extension (can allow a better search in buffers list with telescope)
  view_type = "vsplit", -- Options : "current", "split", "vsplit", "tab", "floating"
  split_side = false, -- (For split and vsplit only) Open on the right or top on false and on the left or bottom on true
  keymaps = {
    declaration = "gd", -- Keymap to go to definition
    close = { "q", "<Esc>" }, -- Keymap for closing the documentation
  },
  floating_win_size = 0.8, -- Floating window size
}
```

## Usage

`:Godot doc <symbol>` : Open class documentation

Exposed functions :

```lua
require('gdscript-extended-lsp').get_classes() -- get list of godot classes

require('gdscript-extended-lsp').request_doc_class(symbol) -- get documentation for a class
```

## Telescope

After the plugin setup, you can load the telescope extension.

```lua
require('telescope').load_extension('gdscript-extended-lsp')
```

`:Telescope gdscript-extended-lsp class` : Search class documentation with telescope


## License

[MIT](./LICENSE)
