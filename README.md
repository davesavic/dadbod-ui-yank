# Dadbod-Ui Yank

A Neovim plugin to yank query results from `vim-dadbod-ui` into various formats (JSON, CSV, XML).

## Features
- Yank database query results in JSON, CSV, or XML format.
- Integrated with `vim-dadbod-ui`.

## Installation

### Using Lazy.nvim
```lua
{
  'davesavic/dadbod-ui-yank',
  dependencies = { 'kristijanhusak/vim-dadbod-ui' },
  config = function()
    require('dadbod-ui-yank').setup()
  end,
}
```

### Defaults
```lua
local default_opts = {
    with_headers = true,
}
```

## Usage
- `:DBUIYankAsCSV` - Yank query results in CSV format.
- `:DBUIYankAsJSON` - Yank query results in JSON format.
- `:DBUIYankAsXML` - Yank query results in XML format.

## License
MIT
