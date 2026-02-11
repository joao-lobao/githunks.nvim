A simple lightweight git gutter for Neovim able to navigate between hunks in buffers.

## Installation

Install with [lazy.nvim](https://github.com/folke/lazy.nvim):

Add this in your `init.lua` or `plugins.lua`:

```lua
{
  "joao-lobao/githunks.nvim",
  config = function()
    require("githunks").setup()
  end
}
```

## Usage

Gutter signaling git changes will show up on the sign column.
To navigate between hunks use the provided commands `GitHunkNext` and `GitHunkPrev`.
You can set your own custom keymaps or set the keymaps inside the setup function.
Below is the default configuration:

```lua
{
  "joao-lobao/githunks.nvim",
  config = function()
    require("githunks").setup({
        -- default configuration
        keymaps = {
            goto_hunk_next = "", -- suggestion "gn"
            goto_hunk_prev = "", -- suggestion "gp"
        },
    })
  end
}
```
