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

-- pastel theme
local PASTEL = {
  bg = '#1e1e1e',
  offbg = '#343434',
  midbg = '#3c3c3c',
  bribg = '#47474f',
  black = '#1B1B1B',
  skyblue = '#7fc9fa',
  cyan = '#58fcfc',
  fg = '#D0D0D0',
  green = '#78fa7e',
  oceanblue = '#6eaff0',
  magenta = '#de8cf5',
  orange = '#fab457',
  red = '#ff5252',
  offred = '#e23737',
  violet = '#a699f7',
  briwhite = '#ffffff',
  white = '#e3e3e3',
  offwhite = '#cdcdcd',
  yellow = '#ffff6e',
  offyellow = '#f7df7e',
}
-- not used, just here for visual reference
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
    'left_rounded',
    { str = ' ', hl = function() return { bg = vi_mode_utils.get_mode_color() } end },
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
    bg = 'offbg',
    style = 'bold',
  },
  left_sep = {
      'slant_left_2',
      { str = ' ', hl = { bg = 'offbg', fg = 'NONE' } },
  },
  right_sep = {
      { str = ' ', hl = { bg = 'offbg', fg = 'NONE' } },
      'slant_right',
  },
  icon = ' ',
})

table.insert(components.active[LEFT], {
  provider = 'file_info',
  hl = {
      fg = 'white',
      bg = 'midbg',
  },
  left_sep = {
      'slant_left_2',
      { str = ' ', hl = { bg = 'midbg', fg = 'NONE' } },
  },
  right_sep = {
      { str = ' ', hl = { bg = 'midbg', fg = 'NONE' } },
      'slant_right',
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

-- table.insert(components.active[LEFT], {
--   provider = 'position',
--   left_sep = ' ',
--   right_sep = {
--       ' ',
--       {
--           str = 'slant_right_2_thin',
--           hl = {
--               fg = 'fg',
--               bg = 'bg',
--           },
--       },
--   },
-- })

table.insert(components.active[LEFT], {
  provider = 'diagnostic_errors',
  hl = {
    fg = 'red',
    bg = 'offbg'
  },
  left_sep = {
      'slant_left_2',
      { str = ' ', hl = { bg = 'offbg', fg = 'NONE' } },
  },
  right_sep = {
      { str = ' ', hl = { bg = 'offbg', fg = 'NONE' } },
      'slant_right',
  },
  icon = '󰅚 ',
})

table.insert(components.active[LEFT], {
  provider = 'diagnostic_warnings',
  hl = {
    fg = 'yellow',
    bg = 'offbg'
  },
  left_sep = {
      'slant_left_2',
      { str = ' ', hl = { bg = 'offbg', fg = 'NONE' } },
  },
  right_sep = {
      { str = ' ', hl = { bg = 'offbg', fg = 'NONE' } },
      'slant_right',
  },
  icon = ' ',
})

table.insert(components.active[LEFT], {
  provider = 'diagnostic_hints',
  hl = {
    fg = 'cyan',
    bg = 'offbg'
  },
  left_sep = {
      'slant_left_2',
      { str = ' ', hl = { bg = 'offbg', fg = 'NONE' } },
  },
  right_sep = {
      { str = ' ', hl = { bg = 'offbg', fg = 'NONE' } },
      'slant_right',
  },
})

table.insert(components.active[LEFT], {
  provider = 'diagnostic_info',
  hl = {
    fg = 'skyblue',
    bg = 'offbg'
  },
  left_sep = {
      'slant_left_2',
      { str = ' ', hl = { bg = 'offbg', fg = 'NONE' } },
  },
  right_sep = {
      { str = ' ', hl = { bg = 'offbg', fg = 'NONE' } },
      'slant_right',
  },
})

table.insert(components.active[LEFT], {
  provider = 'git_diff_added',
  hl = {
    fg = 'green',
    -- bg = 'black',
  },
})

table.insert(components.active[LEFT], {
  provider = 'git_diff_changed',
  hl = {
    fg = 'orange',
    -- bg = 'black',
  },
})

table.insert(components.active[LEFT], {
  provider = 'git_diff_removed',
  hl = {
    fg = 'red',
    -- bg = 'black',
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
  provider = 'position',
  hl = {
      fg = 'briwhite',
      bg = 'offred',
      style = 'bold',
  },
  left_sep = {
      'slant_left',
      { str = ' ', hl = { bg = 'offred', fg = 'NONE' } },
  },
  right_sep = {
      { str = ' ', hl = { bg = 'offred', fg = 'NONE' } },
      'slant_right_2',
      ' ',
  },
})

table.insert(components.active[RIGHT], {
  provider = 'line_percentage',
  hl = {
    style = 'bold',
  },
  left_sep = ' ',
  right_sep = '  ',
})

table.insert(components.active[RIGHT], {
  provider = 'scroll_bar',
  hl = {
    fg = 'skyblue',
    style = 'bold',
  },
})

table.insert(components.inactive[LEFT], {
  provider = 'file_type',
  hl = {
      fg = 'briwhite',
      bg = 'midbg',
      style = 'bold',
  },
  left_sep = {
    'left_rounded',
    { str = ' ', hl = { bg = 'midbg', fg = 'NONE' } },
  },
  right_sep = {
    { str = ' ', hl = { bg = 'midbg', fg = 'NONE' } },
    'right_rounded',
  },
})

feline.setup({
  theme = PASTEL,
  components = components,
  vi_mode_colors = MODE_COLORS,
})
