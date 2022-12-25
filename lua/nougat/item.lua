local Object = require("nui.object")
local core = require("nui.bar.core")
local iu = require("nougat.item.util")
local u = require("nougat.util")

local next_id = u.create_id_generator()

---@alias nougat_item_content string|(fun(self: NougatItem, ctx: table):nil|string|string[])
---@alias nougat_item_hl integer|string|table|(fun(self: NougatItem, ctx: table): integer|string|table)
---@alias nougat_item_hidden boolean|(fun(self: NougatItem, ctx: table):boolean)

---@class NougatItem
---@field id integer
---@field hl? nougat_item_hl
---@field content nougat_item_content
---@field refresh? fun(self: NougatItem, ctx: table):nil
local Item = Object("NougatItem")

--luacheck: push no max line length

---@alias nougat_item { id: integer, content: nougat_item_content, hl?: nougat_item_hl, sep_left?: nougat_separator, prefix?: string, suffix?: string, sep_right?: nougat_separator, hidden?: nougat_item_hidden }

--luacheck: pop

local function content_function_processor(item, ctx)
  return core.clickable(item._content(item, ctx), {
    id = item._on_click_id,
    context = item._on_click_context or item,
    on_click = item._on_click,
  })
end

local function hl_item_processor(item, ctx)
  return type(item._hl_item.hl) == "function" and item._hl_item:hl(ctx) or item._hl_item.hl
end

function Item:init(config)
  self.id = next_id()

  self.hl = config.hl

  self.sep_left = iu.normalize_sep(-1, config.sep_left)
  self.prefix = type(config.prefix) == "string" and { config.prefix } or config.prefix
  self.suffix = type(config.suffix) == "string" and { config.suffix } or config.suffix
  self.sep_right = iu.normalize_sep(1, config.sep_right)

  self.hidden = config.hidden

  if config.type == "code" then
    self.content = core.code(config.content, {
      align = config.align,
      leading_zero = config.leading_zero,
      min_width = config.min_width,
      max_width = config.max_width,
    })
  elseif config.type == "vim_expr" then
    self.content = core.expression(config.content, {
      align = config.align,
      expand = config.expand,
      is_vimscript = true,
      leading_zero = config.leading_zero,
      min_width = config.min_width,
      max_width = config.max_width,
    })
  elseif config.type == "lua_expr" then
    self.content = core.expression(config.content, {
      id = self.id .. "_expression_fn",
      align = config.align,
      context = config.context or self,
      expand = config.expand,
      leading_zero = config.leading_zero,
      min_width = config.min_width,
      max_width = config.max_width,
    })
  elseif config.type == "literal" then
    local has_opts = config.align or config.leading_zero or config.min_width or config.max_width
    self.content = core.literal(config.content, has_opts and {
      align = config.align,
      leading_zero = config.leading_zero,
      min_width = config.min_width,
      max_width = config.max_width,
    } or nil)
  elseif config.type == "tab_label" then
    self.content = core.label(config.content, {
      close = config.close,
      tabnr = config.tabnr,
    })
  else
    self.content = config.content
  end

  if config.on_click then
    if type(self.content) == "function" then
      self._content = self.content
      self._on_click = config.on_click
      self._on_click_id = self.id .. "_click_handler"
      self._on_click_context = config.context
      self.content = content_function_processor
    else
      ---@diagnostic disable-next-line: param-type-mismatch
      self.content = core.clickable(self.content, {
        id = self.id .. "_click_handler",
        context = config.context or self,
        on_click = config.on_click,
      })
    end
  end

  if type(self.hl) == "table" and self.hl.id then
    self._hl_item = self.hl
    self.hl = hl_item_processor
  end

  self._config = config.config or {}

  self._on_init_breakpoints = config.on_init_breakpoints
end

---@param breakpoints integer[]
function Item:_init_breakpoints(breakpoints)
  iu.prepare_config_breakpoints(self, breakpoints)
  iu.prepare_property_breakpoints(self, "sep_left", breakpoints)
  iu.prepare_property_breakpoints(self, "prefix", breakpoints)
  iu.prepare_property_breakpoints(self, "suffix", breakpoints)
  iu.prepare_property_breakpoints(self, "sep_right", breakpoints)

  if self._on_init_breakpoints then
    self:_on_init_breakpoints(breakpoints)
  end
end

function Item:config(ctx)
  return self._config[ctx.ctx.breakpoint] or self._config
end

---@alias NougatItem.constructor fun(config: table): NougatItem
---@type NougatItem|NougatItem.constructor
local NougatItem = Item

return NougatItem
