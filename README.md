# gdscript-extended-lsp.nvim

Add viewing documentation support for Godot using LSP.
Allows to search class on cursor position and in cmd.

Note: This plugin is still a wip. There is a lot to do but it can already be useful for online documentation or in godot app replacement.

User commands :
* `:GodotDocSymbol <class_name>` Get documentation for a class.
* `:GodotDocCursor` Get documentation for class on cursor position.
* `:GodotDocTelescope` Get documentation for a class using Telescope.

## Installation

```lua
-- lazy.nvim
{
    "Teatek/gdscript-extended-lsp.nvim"
}
```
Suggested setup (replace already LSP setup for godot):

```lua
local on_attach = function()
    vim.keymap.set("n", "K", vim.lsp.buf.hover, {buffer=0})
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, {buffer=0})
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, {buffer=0})
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, {buffer=0})
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {buffer=0})
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {buffer=0})
    vim.keymap.set({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, {buffer=0})
end
require("gdscript_extended").setup({
    on_attach = on_attach
})
```

## Configuration

```lua
{
    doc_style = 0, -- Open in a floating window (0), current window (1) or in a new tab (2)
    on_attach = nil, -- on attach function for gdscript LSP setup
    border = 0, -- Border style for floating windows
    doc_extension = ".doc", -- Documentation file extension (can allow a better search in buffers list)
}
```

## License

[MIT](./LICENSE)
