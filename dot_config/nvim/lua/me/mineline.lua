local feline = require('feline')
local vi_mode_utils = require('feline.providers.vi_mode')

-- left and right constants (first and second items of the components array)
local LEFT = 1
local RIGHT = 2

-- vi mode color configuration
local MODE_COLORS = {
  ['NORMAL'] = 'green',
  ['COMMAND'] = 'skyblue',
  ['INSERT'] = 'orange',
  ['REPLACE'] = 'red',
  ['LINES'] = 'violet',
  ['VISUAL'] = 'violet',
  ['OP'] = 'yellow',
  ['BLOCK'] = 'yellow',
  ['V-REPLACE'] = 'yellow',
  ['ENTER'] = 'yellow',
  ['MORE'] = 'yellow',
  ['SELECT'] = 'yellow',
  ['SHELL'] = 'yellow',
  ['TERM'] = 'yellow',
  ['NONE'] = 'yellow',
}

-- default theme
local DEFAULT = {
  bg = '#1F1F23',
  black = '#1B1B1B',
  skyblue = '#50B0F0',
  cyan = '#009090',
  fg = '#D0D0D0',
  green = '#60A040',
  oceanblue = '#0066cc',
  magenta = '#C26BDB',
  orange = '#FF9000',
  red = '#D10000',
  violet = '#9E93E8',
  white = '#FFFFFF',
  yellow = '#E1E120',
}

local seperators = {
  vertical_bar = '┃',
  vertical_bar_thin = '│',
  left = '',
  right = '',
  block = '█',
  left_filled = '',
  right_filled = '',
  slant_left = '',
  slant_left_thin = '',
  slant_right = '',
  slant_right_thin = '',
  slant_left_2 = '',
  slant_left_2_thin = '',
  slant_right_2 = '',
  slant_right_2_thin = '',
  left_rounded = '',
  left_rounded_thin = '',
  right_rounded = '',
  right_rounded_thin = '',
  circle = '●',
}

-- build the components
local components = {
  -- components when buffer is active
  active = {
    {}, -- left section
    {}, -- right section
  },
  -- components when buffer is inactive
  inactive = {
    {}, -- left section
    {}, -- right section
  },
}

table.insert(components.active[LEFT], {
  provider = '▊ ',
  hl = {
    fg = 'skyblue',
  }
})

-- icon version of VIM mode
--table.insert(components.active[LEFT], {
--  provider = 'vi_mode',
--  hl = function()
--    return {
--      name = vi_mode_utils.get_mode_highlight_name(),
--      fg = vi_mode_utils.get_mode_color(),
--      style = 'bold',
--    }
--  end,
--})

-- name version of VIM mode
table.insert(components.active[LEFT], {
  provider = 'vi_mode',
  hl = function()
    return {
      name = vi_mode_utils.get_mode_highlight_name(),
      fg = 'black',
      bg = vi_mode_utils.get_mode_color(),
      style = 'bold',
    }
  end,
  left_sep = {
    { str = '  ', hl = function() return { bg = vi_mode_utils.get_mode_color() } end },
  },
  right_sep = {
    { str = ' ', hl = function() return { bg = vi_mode_utils.get_mode_color() } end },
    'slant_right',
  },
  icon = '',
})

table.insert(components.active[LEFT], {
  provider = 'git_branch',
  hl = {
    fg = 'white',
    bg = 'oceanblue',
    style = 'bold',
  },
  left_sep = 'slant_left_2',
  right_sep = {
    str = 'slant_right',
  },
})

table.insert(components.active[LEFT], {
  provider = 'file_info',
  hl = {
      fg = 'white',
      bg = 'oceanblue',
      style = 'bold',
  },
  left_sep = {
      'slant_left_2',
      { str = ' ', hl = { bg = 'oceanblue', fg = 'NONE' } },
  },
  right_sep = {
      { str = ' ', hl = { bg = 'oceanblue', fg = 'NONE' } },
      'slant_right',
      ' ',
  },
})

--table.insert(components.active[LEFT], {
--  provider = 'file_size',
--  right_sep = {
--      ' ',
--      {
--          str = 'slant_left_2_thin',
--          hl = {
--              fg = 'fg',
--              bg = 'bg',
--          },
--      },
--  },
--})

table.insert(components.active[LEFT], {
  provider = 'position',
  left_sep = ' ',
  right_sep = {
      ' ',
      {
          str = 'slant_right_2_thin',
          hl = {
              fg = 'fg',
              bg = 'bg',
          },
      },
  },
})

table.insert(components.active[LEFT], {
  provider = 'diagnostic_errors',
  hl = { fg = 'red' }
})

table.insert(components.active[LEFT], {
  provider = 'diagnostic_warnings',
  hl = { fg = 'yellow' }
})

table.insert(components.active[LEFT], {
  provider = 'diagnostic_hints',
  hl = { fg = 'cyan' }
})

table.insert(components.active[LEFT], {
  provider = 'diagnostic_info',
  hl = { fg = 'skyblue' }
})

table.insert(components.active[RIGHT], {
  provider = 'git_diff_added',
  hl = {
    fg = 'green',
    bg = 'black',
  },
})

table.insert(components.active[RIGHT], {
  provider = 'git_diff_changed',
  hl = {
    fg = 'orange',
    bg = 'black',
  },
})

table.insert(components.active[RIGHT], {
  provider = 'git_diff_removed',
  hl = {
    fg = 'red',
    bg = 'black',
  },
  right_sep = {
    str = ' ',
    hl = {
        fg = 'NONE',
        bg = 'black',
    },
  },
})

table.insert(components.active[RIGHT], {
  provider = 'line_percentage',
  hl = {
    style = 'bold',
  },
  left_sep = ' ',
  right_sep = ' ',
})

table.insert(components.active[RIGHT], {
  provider = 'scroll_bar',
  hl = {
    fg = 'skyblue',
    style = 'bold',
  },
})

table.insert(components.inactive[LEFT], {
  provider = 'file_info',
  hl = {
      fg = 'white',
      bg = 'oceanblue',
      style = 'bold',
  },
  right_sep = {
      { str = ' ', hl = { bg = 'oceanblue', fg = 'NONE' } },
      'slant_right_2',
      ' ',
  },
})

feline.setup({
  components = components,
  vi_mode_colors = MODE_COLORS,
})
