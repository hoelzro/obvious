local unicode = require 'obvious.lib.unicode'

local assert = assert
local error = error
local huge = math.huge
local max = math.max
local min = math.min
local setmetatable = setmetatable
local sfind = string.find
local sformat = string.format
local smatch = string.match
local ssub = string.sub
local tconcat = table.concat
local type = type
local ulength = unicode.length
local usub = unicode.sub

local rope_mt = {}
rope_mt.__index = rope_mt

local function rope_tostring(rope, pieces)
  if rope.start_tag then
    pieces[#pieces + 1] = rope.start_tag
  end

  for i = 1, #rope do
    if type(rope[i]) == 'string' then
      pieces[#pieces + 1] = rope[i]
    else
      rope_tostring(rope[i], pieces)
    end
  end

  if rope.end_tag then
    pieces[#pieces + 1] = rope.end_tag
  end
end

function rope_mt:__tostring()
  local pieces = {}
  rope_tostring(self, pieces)
  return tconcat(pieces)
end

function rope_mt:len()
  return self._len
end

-- I could use binary search to find the start of the chunk if I wanted (I
-- would need to store the offset into the rope at each node)
local function rope_substring(rope, start, finish, pieces)
  local chunk_start = 1
  local chunk_end

  if rope._entity then
    pieces[#pieces + 1] = rope[1]
    return
  end

  if rope.start_tag then
    pieces[#pieces + 1] = rope.start_tag
  end

  for i = 1, #rope do
    if finish < chunk_start then
      break
    end

    if type(rope[i]) == 'string' then
      chunk_end = chunk_start + ulength(rope[i])
    else
      chunk_end = chunk_start + rope[i]._len
    end
    chunk_end = chunk_end - 1

    if start <= chunk_end and finish >= chunk_start then
      local child_start = max(start - chunk_start, 0) + 1
      local child_end = finish - chunk_start + 1

      if type(rope[i]) == 'string' then
        pieces[#pieces + 1] = usub(rope[i], child_start, child_end)
      else
        rope_substring(rope[i], child_start, child_end, pieces)
      end
    end

    chunk_start = chunk_end + 1
  end

  if rope.end_tag then
    pieces[#pieces + 1] = rope.end_tag
  end
end

function rope_mt:sub(start, finish)
  finish = finish or self._len
  if finish < 1 or start < 1 then
    error('Negative indices are not yet supported', 2)
  end
  if finish < start then
    return ''
  end
  if start > self._len then
    return ''
  end
  local pieces = {}
  rope_substring(self, start, finish, pieces)
  return tconcat(pieces)
end

local function calculate_length(rope)
  if rope._len then
    return rope._len
  end

  local length = 0

  for i = 1, #rope do
    if type(rope[i]) == 'string' then
      length = length + ulength(rope[i])
    else
      rope[i]._len = calculate_length(rope[i])
      length = length + rope[i]._len
    end
  end

  return length
end

local function parse_markup(s)
  local current_node = { '' }
  local rope = setmetatable({ current_node }, rope_mt)
  local node_stack = { rope }

  local function finish_current_strand()
    if #current_node == 1 and current_node[1] == '' then
      return
    end

    current_node = { '' }
    local parent = node_stack[#node_stack]
    parent[#parent + 1] = current_node
  end

  local function down(tag)
    node_stack[#node_stack + 1] = current_node
    local child = { '', start_tag = tag }
    current_node[#current_node + 1] = child
    current_node = child
  end

  local function up(tag)
    if not current_node.start_tag then
      return nil, 'Imbalanced tags found'
    end
    local start_tag = assert(smatch(current_node.start_tag, '<(%w+)'), sformat("%q didn't match our start tag pattern", current_node.start_tag))
    local end_tag   = assert(smatch(tag, '</(%w+)'), sformat("%q didn't match our end tag pattern", tag))
    if start_tag ~= end_tag then
      return nil, sformat("end tag %q doesn't match start tag %q", tag, current_node.start_tag)
    end
    current_node.end_tag = tag
    current_node = node_stack[#node_stack]
    node_stack[#node_stack] = nil
    current_node[#current_node + 1] = ''

    return true
  end

  local end_of_previous_chunk = 1
  local entity_start, entity_end = sfind(s, '&%w+;')
  local open_tag_start, open_tag_end = sfind(s, '<%w+[^>]*>')
  local close_tag_start, close_tag_end = sfind(s, '</%w+%s*>')

  while end_of_previous_chunk < #s do
    local next_special_start = min(entity_start or huge, open_tag_start or huge, close_tag_start or huge, #s + 1)

    current_node[#current_node] = current_node[#current_node] .. ssub(s, end_of_previous_chunk, next_special_start - 1)
    end_of_previous_chunk = min(entity_end or huge, open_tag_end or huge, close_tag_end or huge, #s) + 1

    if next_special_start == entity_start then
      finish_current_strand()
      current_node[1] = ssub(s, entity_start, entity_end)
      current_node._len = 1 -- XXX are you sure about that (# chars or # glyphs)
      current_node._entity = true
      finish_current_strand()
      entity_start, entity_end = sfind(s, '&%w+;', end_of_previous_chunk)
    elseif next_special_start == open_tag_start then
      down(ssub(s, open_tag_start, open_tag_end))
      open_tag_start, open_tag_end = sfind(s, '<%w+[^>]*>', end_of_previous_chunk)
    elseif next_special_start == close_tag_start then
      local ok, err = up(ssub(s, close_tag_start, close_tag_end))
      if not ok then
        return ok, err
      end
      close_tag_start, close_tag_end = sfind(s, '</%w+%s*>', end_of_previous_chunk)
    end
  end

  if #node_stack > 1 then
    local pretty = require 'pretty'
    pretty.print(node_stack)
    return nil, 'Unclosed tags at end-of-string'
  end

  rope._len = calculate_length(rope)
  return rope
end

return parse_markup
