-- ==========================================================================
-- Options
-- ==========================================================================
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Disable netrw (yazi replaces it)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrwSettings = 1
vim.g.loaded_netrwFileHandlers = 1

vim.opt.number = true
vim.opt.relativenumber = true
-- signcolumn managed by snacks.statuscolumn
vim.opt.cursorline = true
vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 8

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.termguicolors = true
vim.opt.undofile = true
vim.opt.updatetime = 250
vim.schedule(function() vim.opt.clipboard = 'unnamedplus' end)
vim.opt.mouse = 'a'
vim.opt.autoread = true
vim.opt.wrap = false
vim.opt.breakindent = true
vim.opt.showmode = false
vim.opt.inccommand = 'split'
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.pumheight = 10
vim.opt.confirm = true
vim.opt.fillchars = { eob = ' ' }
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.swapfile = false
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

vim.opt.smoothscroll = true
vim.opt.splitkeep = 'screen'
vim.opt.jumpoptions:append('stack')
vim.opt.timeoutlen = 300
vim.opt.shortmess:append('I')

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local bigfile_size = 1024 * 1024
local ts_parsers = {
  'lua', 'vim', 'vimdoc', 'query',
  'markdown', 'markdown_inline',
  'bash', 'json', 'yaml', 'toml',
  'python', 'javascript', 'typescript', 'tsx',
  'html', 'css', 'go', 'rust',
}

local function buf_path(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then return nil end
  return vim.fs.normalize(path)
end

local function path_is_big(path)
  local stat = path and vim.uv.fs_stat(path)
  return stat and stat.size > bigfile_size or false
end

local function is_bigfile(bufnr)
  return vim.b[bufnr].bigfile or vim.bo[bufnr].filetype == 'bigfile' or path_is_big(buf_path(bufnr))
end

local function sync_treesitter_parsers(update)
  local ts = require('nvim-treesitter')
  if update then
    ts.update(ts_parsers):wait(300000)
    return
  end

  local installed = ts.get_installed and ts.get_installed() or {}
  local missing = vim.tbl_filter(function(parser)
    return not vim.tbl_contains(installed, parser)
  end, ts_parsers)
  if #missing > 0 then
    ts.install(missing)
  end
end

local function defer_plugin_load(_) end

-- Auto-reload files changed outside nvim. CursorHold intentionally omitted:
-- with updatetime=250 it stats every file four times per second while idle,
-- which thrashes NFS/sshfs. FocusGained + BufEnter covers the common case.
autocmd({ 'FocusGained', 'BufEnter' }, {
  group = augroup('AutoReload', { clear = true }),
  command = 'silent! checktime',
})

-- Highlight on yank
autocmd('TextYankPost', {
  group = augroup('YankHighlight', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- Mark big files early so expensive plugins can opt out reliably even if
-- their own detection only runs later.
autocmd('BufReadPre', {
  group = augroup('BigFileMark', { clear = true }),
  callback = function(args)
    if path_is_big(buf_path(args.buf)) then
      vim.b[args.buf].bigfile = true
    end
  end,
})

-- Return to last edit position when opening files
autocmd('BufReadPost', {
  group = augroup('LastPosition', { clear = true }),
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

-- Terminal buffers: no numbers, no signcolumn
autocmd('TermOpen', {
  group = augroup('TermUI', { clear = true }),
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = 'no'
  end,
})

-- Prose filetypes: spell check + soft wrap
vim.opt.spelllang = { 'en_us' }
autocmd('FileType', {
  group = augroup('Prose', { clear = true }),
  pattern = { 'markdown', 'text', 'gitcommit' },
  callback = function(args)
    if is_bigfile(args.buf) then return end
    vim.opt_local.spell = true
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
  end,
})

-- Use manual folds for buffers we already know are too large for TS folds.
autocmd('FileType', {
  group = augroup('BigFileUI', { clear = true }),
  callback = function(args)
    if not is_bigfile(args.buf) then return end
    vim.b[args.buf].bigfile = true
    pcall(vim.treesitter.stop, args.buf)
    vim.wo.foldmethod = 'manual'
    vim.wo.foldexpr = '0'
  end,
})

-- Per-filetype indent. Global default is 2-space; these override where the
-- language or community convention disagrees. Formatters (gofmt, ruff) will
-- fix files on save, but this keeps editing before-save feeling correct.
autocmd('FileType', {
  group = augroup('Indent', { clear = true }),
  callback = function(args)
    local ft = args.match
    local indent = ({
      go = { sw = 4, ts = 4, et = false },
      make = { sw = 4, ts = 4, et = false },
      python = { sw = 4, ts = 4, et = true },
      rust = { sw = 4, ts = 4, et = true },
    })[ft]
    if not indent then return end
    vim.bo[args.buf].shiftwidth = indent.sw
    vim.bo[args.buf].tabstop = indent.ts
    vim.bo[args.buf].expandtab = indent.et
  end,
})

-- Diagnostics (no LSP, but treesitter/plugins may emit; set sane defaults
-- so anything that does show up looks right without further config).
vim.diagnostic.config({
  virtual_text = { prefix = '●', spacing = 2 },
  severity_sort = true,
  underline = true,
  update_in_insert = false,
  float = { border = 'rounded', source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN]  = '',
      [vim.diagnostic.severity.INFO]  = '',
      [vim.diagnostic.severity.HINT]  = '',
    },
  },
})

-- ==========================================================================
-- Plugins
-- ==========================================================================
-- Pack hooks must be registered before the first vim.pack.add() so clean
-- bootstraps/install-from-lockfile runs plugin setup steps reliably.
autocmd('PackChanged', {
  group = augroup('PackHooks', { clear = true }),
  callback = function(args)
    local data = args.data or {}
    local spec = data.spec
    if not spec or (data.kind ~= 'install' and data.kind ~= 'update') then return end

    if spec.name == 'nvim-treesitter' then
      if not data.active then
        vim.cmd.packadd('nvim-treesitter')
      end
      sync_treesitter_parsers(true)
    end
  end,
})

vim.pack.add({
  -- ui
  'https://github.com/catppuccin/nvim',
  'https://github.com/echasnovski/mini.icons',
  'https://github.com/folke/snacks.nvim',
  'https://github.com/echasnovski/mini.statusline',
  'https://github.com/echasnovski/mini.tabline',

  -- navigation
  'https://github.com/folke/flash.nvim',
  'https://github.com/ibhagwan/fzf-lua',
  'https://github.com/mikavilpas/yazi.nvim',
  'https://github.com/nvim-lua/plenary.nvim',
  { src = 'https://github.com/ThePrimeagen/harpoon', version = 'harpoon2' },

  -- editing
  'https://github.com/echasnovski/mini.surround',
  'https://github.com/echasnovski/mini.ai',
  'https://github.com/echasnovski/mini.bufremove',
  'https://github.com/echasnovski/mini.pairs',
  'https://github.com/echasnovski/mini.splitjoin',
  'https://github.com/echasnovski/mini.comment',
  'https://github.com/gbprod/yanky.nvim',

  -- git
  'https://github.com/lewis6991/gitsigns.nvim',

  -- markdown
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/MeanderingProgrammer/render-markdown.nvim',
  'https://github.com/3rd/image.nvim',
  'https://github.com/3rd/diagram.nvim',

  -- code navigation
  'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
  'https://github.com/folke/todo-comments.nvim',
  'https://github.com/NvChad/nvim-colorizer.lua',

  -- session
  'https://github.com/folke/persistence.nvim',

  -- formatter
  'https://github.com/stevearc/conform.nvim',

  -- keymap hints
  'https://github.com/folke/which-key.nvim',

  -- tmux integration (seamless C-hjkl between nvim splits and tmux panes)
  'https://github.com/christoomey/vim-tmux-navigator',
})

-- Keep heavy plugins installed but off runtimepath until they are used.
vim.pack.add({
  'https://github.com/MagicDuck/grug-far.nvim',
  'https://github.com/sindrets/diffview.nvim',
  'https://github.com/delphinus/md-render.nvim',
}, { load = defer_plugin_load })

-- ==========================================================================
-- Treesitter (main branch: install + enable explicitly)
-- ==========================================================================
vim.schedule(function() sync_treesitter_parsers(false) end)

autocmd('FileType', {
  group = augroup('TSHighlight', { clear = true }),
  callback = function(args)
    if is_bigfile(args.buf) then return end
    if pcall(vim.treesitter.start, args.buf) then
      vim.wo.foldmethod = 'expr'
      vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    end
  end,
})

-- ==========================================================================
-- Theme
-- ==========================================================================
require('catppuccin').setup({
  integrations = {
    gitsigns = true,
    flash = true,
    fzf = true,
    grug_far = true,
    diffview = true,
    harpoon = true,
    markdown = true,
    render_markdown = true,
    snacks = { enabled = true },
    mini = { enabled = true },
    treesitter = true,
    which_key = true,
    yazi = true,
  },
})
vim.cmd.colorscheme('catppuccin-latte')

-- ==========================================================================
-- Plugin config
-- ==========================================================================

-- icons first: mini.icons replaces nvim-web-devicons. Mock before any other
-- plugin setup so downstream plugins (oil, fzf-lua, etc.) see the shim.
require('mini.icons').setup()
MiniIcons.mock_nvim_web_devicons()

-- flash (sneak)
require('flash').setup({
  modes = {
    char = { enabled = true },
    search = { enabled = true },
  },
  label = { after = true, before = false },
})

-- fzf-lua
require('fzf-lua').setup({
  'default',
  winopts = {
    preview = { layout = 'vertical', vertical = 'up:60%' },
  },
})

-- editing
require('mini.ai').setup()
require('mini.bufremove').setup()
require('mini.comment').setup()
require('mini.pairs').setup()
require('mini.splitjoin').setup({
  mappings = { toggle = 'gS', split = '', join = '' },
})
require('mini.surround').setup()

-- yanky (yank ring; cycle with ]y/[y after paste)
require('yanky').setup()

local function source_after_plugins(path)
  local after_paths = vim.fn.glob(path .. '/after/plugin/**/*.{vim,lua}', false, true)
  vim.tbl_map(function(after_path)
    vim.cmd.source({ after_path, magic = { file = false } })
  end, after_paths)
end

local lazy_plugins = {}

local function packadd_once(name)
  if lazy_plugins[name] then return end
  local plug = vim.pack.get({ name }, { info = false })[1]
  vim.cmd.packadd({ vim.fn.escape(name, ' '), bang = false, magic = { file = false } })
  if vim.v.vim_did_enter == 1 and plug then
    source_after_plugins(plug.path)
  end
  lazy_plugins[name] = true
end

local function ensure_grug_far()
  if lazy_plugins['grug-far.nvim:setup'] then return end
  packadd_once('grug-far.nvim')
  require('grug-far').setup()
  lazy_plugins['grug-far.nvim:setup'] = true
end

local function ensure_diffview()
  if lazy_plugins['diffview.nvim:setup'] then return end
  packadd_once('diffview.nvim')
  require('diffview').setup()
  lazy_plugins['diffview.nvim:setup'] = true
end

local function ensure_md_render()
  if lazy_plugins['md-render.nvim'] then return end
  packadd_once('md-render.nvim')
end

local function lazy_plug(plug_name)
  return function()
    ensure_md_render()
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes(plug_name, true, false, true), 'x', false
    )
  end
end

autocmd('CmdUndefined', {
  group = augroup('LazyCommands', { clear = true }),
  pattern = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory' },
  callback = function() ensure_diffview() end,
})
autocmd('CmdUndefined', {
  group = augroup('LazyCommands', { clear = false }),
  pattern = { 'GrugFar', 'GrugFarWithin' },
  callback = function() ensure_grug_far() end,
})

-- yazi (file manager integration)
require('yazi').setup({
  open_for_directories = true,
  keymaps = {
    show_help = '<f1>',
    open_file_in_vertical_split = '<c-v>',
    open_file_in_horizontal_split = '<c-x>',
    open_file_in_tab = '<c-t>',
    grep_in_directory = '<c-sg>',
    replace_in_directory = '<c-sr>',
    cycle_open_buffers = '<tab>',
    copy_relative_path_to_selected_files = '<c-y>',
    send_to_quickfix_list = '<c-q>',
    change_working_directory = '<c-\\>',
  },
})

-- git
require('gitsigns').setup({
  word_diff = true,
  current_line_blame = true,
  current_line_blame_opts = { delay = 300 },
  current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
  on_attach = function(bufnr)
    if is_bigfile(bufnr) then return false end
  end,
})

-- markdown
require('render-markdown').setup({ file_types = { 'markdown' } })

-- image.nvim: kitty graphics protocol (Ghostty supports it). Render only at
-- cursor to play nicely with render-markdown.nvim's virtual text.
require('image').setup({
  backend = 'kitty',
  processor = 'magick_cli',
  integrations = {
    markdown = {
      enabled = true,
      only_render_image_at_cursor = false,
      filetypes = { 'markdown' },
    },
  },
  max_width = 100,
  max_height = 12,
  max_height_window_percentage = 40,
})

-- diagram.nvim: renders mermaid (and plantuml/d2/gnuplot) code blocks via mmdc.
-- mmdc shells out to puppeteer; bun-installed mmdc skips puppeteer's chromium
-- download, so point it at the system Chrome via -p <config>.
local mermaid_opts = {
  background = 'transparent',
  scale = 2,
  cli_args = {
    '-p', vim.fn.stdpath('config') .. '/puppeteer-config.json',
    '-c', vim.fn.stdpath('config') .. '/mermaid-config.json',
  },
}
require('diagram').setup({
  integrations = { require('diagram.integrations.markdown') },
  renderer_options = { mermaid = mermaid_opts },
})

-- diagram.nvim's show_diagram_hover renders the image at line 6 of a 5-line
-- scratch buffer, which trips screenpos() with E966. Bypass it: drive the
-- markdown integration's renderer ourselves and open the PNG in the system
-- viewer, which gives real zoom/pan anyway.
function _G.zoom_diagram_at_cursor()
  local integration = require('diagram.integrations.markdown')
  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.tbl_contains(integration.filetypes, vim.bo[bufnr].filetype) then
    vim.notify('Not a markdown buffer', vim.log.levels.INFO)
    return
  end
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local diagram
  for _, d in ipairs(integration.query_buffer_diagrams(bufnr)) do
    if row >= d.range.start_row and row <= d.range.end_row then
      diagram = d
      break
    end
  end
  if not diagram then
    vim.notify('No diagram at cursor', vim.log.levels.INFO)
    return
  end
  local renderer
  for _, r in ipairs(integration.renderers) do
    if r.id == diagram.renderer_id then renderer = r; break end
  end
  if not renderer then
    vim.notify('No renderer for ' .. diagram.renderer_id, vim.log.levels.ERROR)
    return
  end
  local opts = ({ mermaid = mermaid_opts })[renderer.id] or {}
  local result = renderer.render(diagram.source, opts)
  local function open()
    if vim.fn.filereadable(result.file_path) == 1 then
      vim.ui.open(result.file_path)
    else
      vim.notify('Diagram render failed: ' .. result.file_path, vim.log.levels.ERROR)
    end
  end
  if result.job_id then
    vim.fn.jobwait({ result.job_id })
    vim.schedule(open)
  else
    open()
  end
end

-- Hide ```mermaid ... ``` source when cursor isn't inside the block, since
-- image.nvim already renders the diagram inline. Cursor entering the block
-- reveals the source for editing. Requires conceallevel>=1 — render-markdown
-- already sets it to 3 in rendered modes (n/c/t).
local mermaid_ns = vim.api.nvim_create_namespace('mermaid_conceal')

local function refresh_mermaid_conceal(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype ~= 'markdown' then return end
  vim.api.nvim_buf_clear_namespace(bufnr, mermaid_ns, 0, -1)
  if vim.b[bufnr].mermaid_conceal_disabled then return end

  local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local in_block, start_row = false, nil
  for i, line in ipairs(lines) do
    local row = i - 1
    if not in_block and line:match('^%s*```mermaid') then
      in_block = true
      start_row = row
    elseif in_block and line:match('^%s*```%s*$') then
      local end_row = row
      if cursor_row < start_row or cursor_row > end_row then
        -- keep start_row visible: image.nvim anchors to it. Concealing it
        -- collapses every block's anchor to the same screen row → overlap.
        for r = start_row + 1, end_row do
          vim.api.nvim_buf_set_extmark(bufnr, mermaid_ns, r, 0, {
            end_row = r + 1,
            conceal_lines = '',
          })
        end
      end
      in_block, start_row = false, nil
    end
  end
end

autocmd({ 'BufEnter', 'CursorMoved', 'CursorMovedI', 'TextChanged', 'InsertLeave' }, {
  group = augroup('MermaidConceal', { clear = true }),
  pattern = { '*.md', '*.markdown' },
  callback = function(args) refresh_mermaid_conceal(args.buf) end,
})

-- treesitter-textobjects (jump between functions/classes)
require('nvim-treesitter-textobjects').setup({
  select = { lookahead = true },
  move = { set_jumps = true },
})

local ts_move = require('nvim-treesitter-textobjects.move')
local ts_select = require('nvim-treesitter-textobjects.select')

for _, spec in ipairs({
  { key = 'm', query = '@function.outer',  label = 'function'  },
  { key = 'c', query = '@class.outer',     label = 'class'     },
  { key = 'a', query = '@parameter.inner', label = 'parameter' },
}) do
  vim.keymap.set({ 'n', 'x', 'o' }, ']' .. spec.key,
    function() ts_move.goto_next_start(spec.query) end,
    { desc = 'Next ' .. spec.label })
  vim.keymap.set({ 'n', 'x', 'o' }, '[' .. spec.key,
    function() ts_move.goto_previous_start(spec.query) end,
    { desc = 'Prev ' .. spec.label })
end

for _, spec in ipairs({
  { key = 'f', query = 'function',  label = 'function'  },
  { key = 'c', query = 'class',     label = 'class'     },
  { key = 'a', query = 'parameter', label = 'parameter' },
}) do
  vim.keymap.set({ 'x', 'o' }, 'a' .. spec.key,
    function() ts_select.select_textobject('@' .. spec.query .. '.outer') end,
    { desc = 'Around ' .. spec.label })
  vim.keymap.set({ 'x', 'o' }, 'i' .. spec.key,
    function() ts_select.select_textobject('@' .. spec.query .. '.inner') end,
    { desc = 'Inner ' .. spec.label })
end

-- todo comments
require('todo-comments').setup()

-- colorizer (inline preview of #hex / rgb())
require('colorizer').setup({
  filetypes = { 'css', 'scss', 'html', 'lua', 'javascript', 'typescript', 'yaml', 'toml' },
  user_default_options = { names = false },
})

-- persistence (per-cwd session save/restore)
require('persistence').setup({ options = { autoload = true } })
vim.uv.new_timer():start(60000, 60000, function()
  vim.schedule(function() require('persistence').save() end)
end)

-- statusline
require('mini.statusline').setup()
require('mini.tabline').setup()

-- snacks
local function setup_snacks_bigfile(ctx)
  vim.b[ctx.buf].bigfile = true
  if vim.fn.exists(':NoMatchParen') ~= 0 then
    vim.cmd([[NoMatchParen]])
  end
  Snacks.util.wo(0, { foldmethod = 'manual', statuscolumn = '', conceallevel = 0 })
  vim.b[ctx.buf].completion = false
  vim.b[ctx.buf].minianimate_disable = true
  vim.b[ctx.buf].minihipatterns_disable = true
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(ctx.buf) then
      vim.bo[ctx.buf].syntax = ctx.ft
    end
  end)
end

require('snacks').setup({
  bigfile = { enabled = true, size = bigfile_size, setup = setup_snacks_bigfile },
  zen = { enabled = true },
  scroll = { enabled = true },
  indent = { enabled = true },
  statuscolumn = { enabled = true },
  input = { enabled = true },
  notifier = { enabled = true },
  terminal = { enabled = true },
  gitbrowse = { enabled = true },
  words = { enabled = true },
})

-- harpoon (pin 4 files for instant switching)
local harpoon = require('harpoon')
harpoon:setup()

-- conform (formatter; format-on-save)
local prettier = { 'prettierd', 'prettier', stop_after_first = true }
require('conform').setup({
  formatters_by_ft = {
    lua = { 'stylua' },
    python = { 'ruff_format' },
    javascript = prettier,
    typescript = prettier,
    javascriptreact = prettier,
    typescriptreact = prettier,
    json = prettier,
    yaml = prettier,
    markdown = prettier,
    html = prettier,
    css = prettier,
    go = { 'goimports', 'gofmt' },
    rust = { 'rustfmt' },
    sh = { 'shfmt' },
  },
  format_on_save = function(bufnr)
    if is_bigfile(bufnr) or vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
    return { timeout_ms = 1000, lsp_format = 'never' }
  end,
})

vim.api.nvim_create_user_command('FormatDisable', function(args)
  if args.bang then
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
end, { desc = 'Disable autoformat-on-save', bang = true })

vim.api.nvim_create_user_command('FormatEnable', function(args)
  if args.bang then
    vim.b.disable_autoformat = false
  else
    vim.g.disable_autoformat = false
  end
end, { desc = 'Re-enable autoformat-on-save', bang = true })

-- which-key
require('which-key').setup({ preset = 'modern' })
require('which-key').add({
  { '<leader>f', group = 'Find' },
  { '<leader>g', group = 'Git' },
  { '<leader>m', group = 'Markdown' },
  { '<leader>s', group = 'Search/Replace' },
  { '<leader>t', group = 'Toggle' },
  { '<leader>h', group = 'Harpoon' },
  { '<leader>c', group = 'Code' },
  { '<leader>q', group = 'Session/Quit' },
  { '<leader>b', group = 'Buffer' },
  { '<leader>w', group = 'Window' },
  { '<leader>x', group = 'Problems' },
})

-- ==========================================================================
-- Keymaps
-- ==========================================================================

-- general
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<cr>', { desc = 'Clear search' })
vim.keymap.set('v', 'J', ":m '>+1<cr>gv=gv", { desc = 'Move down', silent = true })
vim.keymap.set('v', 'K', ":m '<-2<cr>gv=gv", { desc = 'Move up', silent = true })
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')
vim.keymap.set({ 'n', 'x', 'o' }, 's', function() require('flash').jump() end, { desc = 'Flash' })
vim.keymap.set({ 'n', 'x', 'o' }, 'S', function() require('flash').treesitter() end, { desc = 'Flash treesitter' })
vim.keymap.set('n', '-', '<cmd>Yazi<cr>', { desc = 'Open yazi' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', '<C-Up>', '<cmd>resize +2<cr>', { desc = 'Increase height' })
vim.keymap.set('n', '<C-Down>', '<cmd>resize -2<cr>', { desc = 'Decrease height' })
vim.keymap.set('n', '<C-Left>', '<cmd>vertical resize -2<cr>', { desc = 'Decrease width' })
vim.keymap.set('n', '<C-Right>', '<cmd>vertical resize +2<cr>', { desc = 'Increase width' })
vim.keymap.set('n', '<C-a>', 'ggVG', { desc = 'Select all' })

-- paste (yanky ring; cycle with ]y/[y)
vim.keymap.set('n', 'p', '<Plug>(YankyPutAfter)')
vim.keymap.set('n', 'P', '<Plug>(YankyPutBefore)')
vim.keymap.set({ 'n', 'x' }, 'gp', '<Plug>(YankyGPutAfter)')
vim.keymap.set({ 'n', 'x' }, 'gP', '<Plug>(YankyGPutBefore)')
vim.keymap.set('x', 'p', '"_dP')
vim.keymap.set('n', ']y', '<Plug>(YankyNextEntry)')
vim.keymap.set('n', '[y', '<Plug>(YankyPreviousEntry)')

-- find
vim.keymap.set('n', '<leader><leader>', '<cmd>FzfLua files<cr>', { desc = 'Find files' })
vim.keymap.set('n', '<leader>/', '<cmd>FzfLua live_grep<cr>', { desc = 'Live grep' })
vim.keymap.set('x', '<leader>/', function() require('fzf-lua').grep_visual() end, { desc = 'Grep selection' })
vim.keymap.set('n', '<leader>f/', '<cmd>FzfLua lgrep_curbuf<cr>', { desc = 'Grep current buffer' })
vim.keymap.set('n', '<leader>fh', '<cmd>FzfLua help_tags<cr>', { desc = 'Help tags' })
vim.keymap.set('n', '<leader>fk', '<cmd>FzfLua keymaps<cr>', { desc = 'Keymaps' })
vim.keymap.set('n', '<leader>fo', '<cmd>FzfLua oldfiles<cr>', { desc = 'Recent files' })
vim.keymap.set('n', '<leader>ft', '<cmd>TodoFzfLua<cr>', { desc = 'Todo comments' })
vim.keymap.set('n', '<leader>fw', '<cmd>FzfLua grep_cword<cr>', { desc = 'Grep word' })

-- buffer
vim.keymap.set('n', '<leader>bb', '<cmd>FzfLua buffers<cr>', { desc = 'Switch buffer' })
vim.keymap.set('n', '<leader>bd', function() require('mini.bufremove').delete(0) end, { desc = 'Delete buffer' })

-- code
vim.keymap.set({ 'n', 'v' }, '<leader>cf', function()
  require('conform').format({ async = true, lsp_format = 'never' })
end, { desc = 'Format' })

-- explorer
vim.keymap.set('n', '<leader>e', '<cmd>Yazi<cr>', { desc = 'Explorer' })

-- git
vim.keymap.set('n', '<leader>gb', '<cmd>Gitsigns blame_line full=true<cr>', { desc = 'Blame line' })
vim.keymap.set('n', '<leader>gB', '<cmd>FzfLua git_branches<cr>', { desc = 'Branches' })
vim.keymap.set('n', '<leader>gc', '<cmd>FzfLua git_commits<cr>', { desc = 'Commits' })
vim.keymap.set('n', '<leader>gC', '<cmd>FzfLua git_bcommits<cr>', { desc = 'Buffer commits' })
vim.keymap.set('n', '<leader>gd', '<cmd>Gitsigns diffthis<cr>', { desc = 'Diff this file' })
vim.keymap.set('n', '<leader>gD', function() require('gitsigns').diffthis('~') end, { desc = 'Diff last commit' })
vim.keymap.set('n', '<leader>gg', function() Snacks.lazygit() end, { desc = 'Lazygit' })
vim.keymap.set('n', '<leader>gH', function()
  ensure_diffview()
  vim.cmd('DiffviewFileHistory %')
end, { desc = 'File history' })
vim.keymap.set('n', '<leader>go', function() Snacks.gitbrowse() end, { desc = 'Open on GitHub' })
vim.keymap.set('n', '<leader>gp', '<cmd>Gitsigns preview_hunk<cr>', { desc = 'Preview hunk' })
vim.keymap.set({ 'n', 'v' }, '<leader>gr', '<cmd>Gitsigns reset_hunk<cr>', { desc = 'Reset hunk' })
vim.keymap.set({ 'n', 'v' }, '<leader>gs', '<cmd>Gitsigns stage_hunk<cr>', { desc = 'Stage hunk' })
vim.keymap.set('n', '<leader>gS', '<cmd>FzfLua git_status<cr>', { desc = 'Git status' })
vim.keymap.set('n', '<leader>gt', '<cmd>Gitsigns toggle_deleted<cr>', { desc = 'Toggle deleted' })
vim.keymap.set('n', '<leader>gu', '<cmd>Gitsigns undo_stage_hunk<cr>', { desc = 'Undo stage hunk' })
vim.keymap.set('n', '<leader>gv', function()
  ensure_diffview()
  vim.cmd('DiffviewOpen')
end, { desc = 'Diffview open' })
vim.keymap.set('n', '<leader>gV', function()
  pcall(vim.cmd, 'DiffviewClose')
end, { desc = 'Diffview close' })

-- harpoon
vim.keymap.set('n', '<leader>ha', function() harpoon:list():add() end, { desc = 'Add file' })
vim.keymap.set('n', '<leader>hh', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Menu' })
vim.keymap.set('n', '<leader>1', function() harpoon:list():select(1) end, { desc = 'Harpoon 1' })
vim.keymap.set('n', '<leader>2', function() harpoon:list():select(2) end, { desc = 'Harpoon 2' })
vim.keymap.set('n', '<leader>3', function() harpoon:list():select(3) end, { desc = 'Harpoon 3' })
vim.keymap.set('n', '<leader>4', function() harpoon:list():select(4) end, { desc = 'Harpoon 4' })

-- markdown
vim.keymap.set('n', '<leader>mp', lazy_plug('<Plug>(md-render-preview)'),     { desc = 'Preview (float)' })
vim.keymap.set('n', '<leader>mt', lazy_plug('<Plug>(md-render-preview-tab)'), { desc = 'Preview (tab)' })
vim.keymap.set('n', '<leader>md', lazy_plug('<Plug>(md-render-demo)'),        { desc = 'Render demo' })
vim.keymap.set('n', '<leader>mz', function() _G.zoom_diagram_at_cursor() end, { desc = 'Zoom diagram (Preview)' })
vim.keymap.set('n', '<leader>mH', function()
  local b = vim.api.nvim_get_current_buf()
  vim.b[b].mermaid_conceal_disabled = not vim.b[b].mermaid_conceal_disabled
  refresh_mermaid_conceal(b)
end, { desc = 'Toggle mermaid source hide' })

-- session/quit
vim.keymap.set('n', '<leader>qa', '<cmd>qa<cr>', { desc = 'Quit all' })
vim.keymap.set('n', '<leader>qd', function() require('persistence').stop() end, { desc = "Don't save session" })
vim.keymap.set('n', '<leader>ql', function() require('persistence').load({ last = true }) end, { desc = 'Restore last session' })
vim.keymap.set('n', '<leader>qq', '<cmd>q<cr>', { desc = 'Quit window' })
vim.keymap.set('n', '<leader>qs', function() require('persistence').load() end, { desc = 'Restore session' })

-- search/replace
vim.keymap.set('n', '<leader>sr', function()
  ensure_grug_far()
  vim.cmd('GrugFar')
end, { desc = 'Find and replace' })
vim.keymap.set('n', '<leader>sw', function()
  ensure_grug_far()
  require('grug-far').open({ prefills = { search = vim.fn.expand('<cword>') } })
end, { desc = 'Replace current word' })
vim.keymap.set('x', '<leader>sw', function()
  ensure_grug_far()
  vim.cmd('noautocmd normal! "zy')
  require('grug-far').open({ prefills = { search = vim.fn.getreg('z') } })
end, { desc = 'Replace selection' })

-- toggle
vim.keymap.set('n', '<leader>tn', function()
  local off = not vim.opt.number:get()
  vim.opt.number = off
  vim.opt.relativenumber = off
end, { desc = 'Line numbers' })
vim.keymap.set('n', '<leader>ts', '<cmd>set spell!<cr>', { desc = 'Spell check' })
vim.keymap.set('n', '<leader>tt', function() Snacks.terminal() end, { desc = 'Terminal' })
vim.keymap.set('n', '<leader>tw', '<cmd>set wrap!<cr>', { desc = 'Wrap' })

-- window
vim.keymap.set('n', '<leader>wd', '<C-W>c', { desc = 'Delete window' })
vim.keymap.set('n', '<leader>w=', '<C-W>=', { desc = 'Equal sizes' })
vim.keymap.set('n', '<leader>w-', '<C-W>s', { desc = 'Split below' })
vim.keymap.set('n', '<leader>w|', '<C-W>v', { desc = 'Split right' })

-- problems
vim.keymap.set('n', '<leader>xd', vim.diagnostic.open_float, { desc = 'Line diagnostics' })
vim.keymap.set('n', '<leader>xl', '<cmd>lopen<cr>', { desc = 'Location list' })
vim.keymap.set('n', '<leader>xq', '<cmd>copen<cr>', { desc = 'Quickfix list' })

-- zen
vim.keymap.set('n', '<leader>z', function() Snacks.zen() end, { desc = 'Zen mode' })
vim.keymap.set('n', '<leader>Z', function() Snacks.zen.zoom() end, { desc = 'Zen zoom' })

-- navigation
vim.keymap.set('n', '[b', '<cmd>bprevious<cr>', { desc = 'Prev buffer' })
vim.keymap.set('n', ']b', '<cmd>bnext<cr>', { desc = 'Next buffer' })
vim.keymap.set('n', '[h', '<cmd>Gitsigns prev_hunk<cr>', { desc = 'Prev hunk' })
vim.keymap.set('n', ']h', '<cmd>Gitsigns next_hunk<cr>', { desc = 'Next hunk' })
vim.keymap.set('n', '[q', '<cmd>cprev<cr>', { desc = 'Prev quickfix' })
vim.keymap.set('n', ']q', '<cmd>cnext<cr>', { desc = 'Next quickfix' })
vim.keymap.set('n', '[t', function() require('todo-comments').jump_prev() end, { desc = 'Prev todo' })
vim.keymap.set('n', ']t', function() require('todo-comments').jump_next() end, { desc = 'Next todo' })
