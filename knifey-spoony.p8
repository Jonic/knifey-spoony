pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- knifey spoony
-- by jonic + ribbon black
-- v1.0.0b

--[[
  "i see you've played knifey
  spoony before"

  jonic: this is my first real
  attempt to make a game with
  pico-8. it's a bit messy,
  because i've spent a long time
  trying to figure out systems
  for things such as displaying
  groups of sprites, animating
  elements, and dispalying text.

  i haven't made any attempt to
  optimise this code, so it
  should be easy for a beginner
  to get to grips with it. if
  you're struggling to read it
  in pico-8, the full code is
  on github here:

  https://github.com/jonic/knifey-spoony
]]

-->8
-- game object
local game_init = function()
  local g = {}

  -- g.default_state     = 'object_debug'
  g.default_state     = 'title_transition_in'
  g.frame_multiplier  = 1
  g.high_score        = 0
  g.high_score_beaten = false
  g.objects           = {}
  g.objects_order     = {}
  g.score             = 0
  g.state             = nil
  g.states            = {}

  g.object_add = function(name, o)
    add(g.objects_order, name)
    g.objects[name] = o
    -- g.object_debug()
  end

  g.object_debug = function()
    local debug = ''
    foreach (g.objects_order, function(name)
      debug = debug .. name .. ', '
    end)
    printh(debug)
  end

  g.object_destroy = function(name)
    local index = g.object_get_order_index(name)
    local o     = g.objects[name]

    if (index ~= nil) then
      -- printh('remove object: `' .. name .. '`')
      g.objects_order[index] = nil
      del(g.objects, o)
    end
    -- g.object_debug()
  end

  g.object_get_order_index = function(name)
    for i, v in pairs(g.objects_order) do
      if (v == name) return i
    end
  end

  g.object_restack = function(name)
    local index = g.object_get_order_index(name)
    g.objects_order[index] = nil
    add(g.objects_order, name)
  end

  g.objects_destroy = function(objects_list)
    foreach (objects_list, g.object_destroy)
  end

  g.objects_destroy_all = function()
    g.objects_order = copy({})
    g.objects       = copy({})
  end

  g.objects_exec = function(fn)
    local obj
    for _, name in pairs(g.objects_order) do
      obj = g.objects[name]
      if (obj ~= nil) obj[fn]()
    end
  end

  g.objects_restack = function(objects_list)
    foreach (objects_list, g.object_restack)
  end

  g.draw = function()
    cls()
    g.objects_exec('draw')
    g.state.draw()
  end

  g.go_to = function(name)
    printh('state: `' .. name .. '`')

    if g.state then
      g.skip_animations()
      g.state_unload()
    end

    g.state = g.states[name]
    g.state.init()
  end

  g.init = function()
    cartdata('jonic_knifeyspoony')
    g.go_to(g.default_state)
  end

  g.reset = function()
    g.objects_destroy_all()
    g.reset_vars()
    g.state            = g.states[g.default_state]
    g.frame_multiplier = 2
  end

  g.reset_vars = function()
    g.high_score        = dget(0)
    g.high_score_beaten = false
    g.score             = 0
  end

  g.skip_animations = function()
    g.objects_exec('skip')
  end

  g.state_unload = function()
    g.state.unload()
  end

  g.update = function()
    g.objects_exec('update')
    g.state.update()
  end

  g.update_high_score = function()
    g.high_score        = g.score
    g.high_score_beaten = true
    dset(0, g.high_score)
  end

  g.update_score = function()
    g.score += 1
    if (g.score > g.high_score) g.update_high_score()
  end

  return g
end

local game = game_init()

--> 8
-- helpers functions
-- clone and copy from https://gist.github.com/MihailJP/3931841
function clone(t) -- deep-copy a table
  if type(t) ~= "table" then return t end
  local meta = getmetatable(t)
  local target = {}
  for k, v in pairs(t) do
    if type(v) == "table" then
      target[k] = clone(v)
    else
      target[k] = v
    end
  end
  setmetatable(target, meta)
  return target
end

function copy(t) -- shallow-copy a table
  if type(t) ~= "table" then return t end
  local meta = getmetatable(t)
  local target = {}
  for k, v in pairs(t) do target[k] = v end
  setmetatable(target, meta)
  return target
end

function draw_sprite(s, x, y)
  local i  = s.i
  local x  = s.x + (x or 0)
  local y  = s.y + (y or 0)
  local w  = s.w or 1
  local h  = s.h or 1
  local fx = s.fx or false
  local fy = s.fy or false

  spr(i, x, y, w, h, fx, fy)
end

function draw_sprites(sprites, x, y)
  foreach(sprites, draw_sprite, x, y)
end

function f(n)
  return n * game.frame_multiplier
end

function o(name)
  return game.objects[name]
end

function rndint(min, max)
  return flr(rnd(max)) + min
end

-- easing equations
-- https://github.com/EmmanuelOga/easing/blob/master/lib/easing.lua
local function linear(t, b, c, d)
  return c * t / d + b
end

local function outBack(t, b, c, d, s)
  if not s then s = 1.70158 end
  t = t / d - 1
  return c * (t * t * ((s + 1) * t + s) + 1) + b
end

local function inBack(t, b, c, d, s)
  if not s then s = 1.70158 end
  t = t / d
  return c * t * t * ((s + 1) * t - s) + b
end

local function outBounce(t, b, c, d)
  t = t / d
  if t < 1 / 2.75 then
    return c * (7.5625 * t * t) + b
  elseif t < 2 / 2.75 then
    t = t - (1.5 / 2.75)
    return c * (7.5625 * t * t + 0.75) + b
  elseif t < 2.5 / 2.75 then
    t = t - (2.25 / 2.75)
    return c * (7.5625 * t * t + 0.9375) + b
  else
    t = t - (2.625 / 2.75)
    return c * (7.5625 * t * t + 0.984375) + b
  end
end

local function inBounce(t, b, c, d)
  return c - outBounce(d - t, 0, c, d) + b
end

-->8
-- init objects and states
function object_init(name, props)
  game.object_destroy(name)
  -- printh('object: created `' .. name .. '`')

  local o = {}

  o.color       = props.color   or 7
  o.frame_count = 0
  o.name        = name
  o.outline     = props.outline or nil
  o.rects       = props.rects   or nil
  o.text        = props.text    or nil
  o.tiles       = props.tiles   or nil
  o.updated     = false
  o.x           = props.x       or 0
  o.y           = props.y       or 0

  o.center_x = function()
    local text = o.text .. ''
    return 64 - #text * 2
  end

  o.draw_rect = function(r)
    local x1    = (r.x or 0) + o.x
    local y1    = (r.y or 0) + o.y
    local x2    = x1 + r.w
    local y2    = y1 + r.h
    local color = r.color

    rectfill(x1, y1, x2, y2, color)
  end

  o.draw_rects = function(rects)
    foreach(rects, function(r)
      if (r.w == nil) return o.draw_rects(r)
      o.draw_rect(r)
    end)
  end

  o.draw_text = function()
    local color   = o.color
    local outline = o.outline
    local text    = o.text
    local x       = o.x
    local y       = o.y

    if outline ~= nil then
      print(text, x - 1, y, outline)
      print(text, x + 1, y, outline)
      print(text, x, y - 1, outline)
      print(text, x, y + 1, outline)
    end

    print(text, x, y, color)
  end

  o.draw_tile = function(t)
    local x  = (t.x or 0) + o.x
    local y  = (t.y or 0) + o.y
    local w  = t.w or 1
    local h  = t.h or 1
    local fx = t.fx or false
    local fy = t.fy or false

    spr(t.i, x, y, w, h, fx, fy)
  end

  o.draw_tiles = function(tiles)
    foreach(tiles, function(t)
      if (t.i == nil) return o.draw_tiles(t)
      o.draw_tile(t)
    end)
  end

  o.is_animating = function() return type(o.duration) == 'number' and o.frame_count < o.duration end
  o.is_text      = function() return o.type() == 'text'  end
  o.is_tiles     = function() return o.type() == 'tiles' end
  o.is_rects     = function() return o.type() == 'rects' end

  o.move  = function(props)
    o.delay    = f(props.delay    or 0)
    o.duration = f(props.duration or 0)
    o.easing   = props.easing   or nil
    o.new_x    = props.x        or o.x
    o.new_y    = props.y        or o.y
    o.old_x    = o.x
    o.old_y    = o.y

    o.complete    = false
    o.frame_count = 0
    o.updated     = false

    return o
  end

  o.pos = function(coords)
    o.x = coords.x or o.x
    o.y = coords.y or o.y
    return o
  end

  o.skip = function()
    if (not o.is_animating()) return
    o.duration = nil
    o.x        = o.new_x
    o.y        = o.new_y
  end

  o.tick = function()
    if o.delay > 0 then
      o.delay -= 1
      return
    end

    o.frame_count += 1
  end

  o.type = function()
    if (o.text  ~= nil) return 'text'
    if (o.tiles ~= nil) return 'tiles'
    if (o.rects ~= nil) return 'rects'
  end

  o.update_pos = function(pos_key)
    local pos1 = o['old_' .. pos_key]
    local pos2 = o['new_' .. pos_key]

    local t = o.frame_count -- elapsed time
    local b = pos1          -- begin
    local c = pos2 - pos1   -- change == ending - beginning
    local d = o.duration    -- duration (total time)
    local e = o.easing or linear

    if (type(e) == 'string') then
      if     e == 'inBack'    then e = inBack
      elseif e == 'outBack'   then e = outBack
      elseif e == 'inBounce'  then e = inBounce
      elseif e == 'outBounce' then e = outBounce
      else                         e = linear
      end
    end

    return flr(e(t, b, c, d))
  end

  o.update = function()
    o.updated = true
    if (not o.is_animating()) return

    o.tick()
    o.x = o.update_pos('x')
    o.y = o.update_pos('y')
  end

  o.draw = function()
    if (not o.updated) return
    if (o.is_text())   return o.draw_text()
    if (o.is_tiles())  return o.draw_tiles(o.tiles)
    if (o.is_rects())  return o.draw_rects(o.rects)
  end

  game.object_add(name, o)
  return o
end

function state_init(name, props)
  local s = {}

  s.frame_count = 0
  s.name        = name
  s.props       = props()

  s.draw = function()
    if (s.should_flash()) return s.draw_flash()
    if (s.props.draw) s.props.draw()
  end

  s.draw_flash = function()
    rectfill(0, 0, 127, 127, s.props.flash.color)
  end

  s.init = function()
    s.frame_count = 0
    if (s.props.init) s.props.init()
  end

  s.should_flash = function()
    return (s.props.flash ~= nil) and (s.props.flash.on == s.frame_count)
  end

  s.unload = function()
    if (s.props.unload) s.props.unload()
  end

  s.update = function()
    s.frame_count += 1

    if (s.props.transition ~= nil) then
      if (s.frame_count == f(s.props.transition.timeout)) then
        game.go_to(s.props.transition.destination)
      end
    end

    if (s.props.update) s.props.update()
  end

  game.states[name] = s

  return s
end

-->8
-- objects definitions
local rects = {
  floor = {
    {        w = 119, h = 1, color = 15 },
    { y = 2, w = 119, h = 7, color = 4  },
    { y = 9, w = 119, h = 3, color = 2  },
  },
}

local text = {
  about             = '2018 jonic + ribbon black',
  game_over         = 'game over!',
  high_score        = 'high score: ',
  high_score_beaten = '** new high score **',
  knifey            = 'knifey',
  play_again        = 'press x to play again',
  score             = 'score',
  spoony            = 'spoony',
  start_game        = 'press x to start',
}

local tiles = {
  playing = {
    high_score_icon = {
      { i = 111 },
    },
    buttons = {
      knifey = {
        {{ i = 4,  w = 4, h = 2 }},
        {{ i = 8,  w = 4, h = 2 }},
        {{ i = 12, w = 4, h = 2 }},
        {{ i = 8,  w = 4, h = 2 }},
      },
      spoony = {
        {{ i = 36, w = 4, h = 2 }},
        {{ i = 40, w = 4, h = 2 }},
        {{ i = 44, w = 4, h = 2 }},
        {{ i = 40, w = 4, h = 2 }},
      },
    },
    score = {
      { i = 134, w = 4, h = 3 },
      { i = 50,  x = 14, y = 21},
    },
    utensils = {
      knifey = {
        {
          -- red knife
          { i = 75,  x = 8,  y = 0, w = 2, h = 4 },
          { i = 77,  x = 8,  y = 32, w = 2 },
          { i = 93,  y = 40 },
          { i = 94,  x = 8,  y = 40 },
          { i = 79,  x = 16, y = 40 },
          { i = 95,  x = 24, y = 40 },
          { i = 105, x = 8,  y = 48, w = 2, h = 2 },
        },
        {
          -- thin knife
          { i = 64, x = 8,         w = 2, h = 4 },
          { i = 66, x = 8, y = 32, w = 2, h = 4 },
        },
        {
          -- metal knife
          { i = 64,  x = 8,  y = 0,  w = 2, h = 2 },
          { i = 68,  x = 8,  y = 16 },
          { i = 113, x = 16, y = 16 },
          { i = 112, x = 8,  y = 24, w = 2 },
          { i = 84,  x = 8,  y = 32, w = 2, h = 3 },
          { i = 69,  x = 8,  y = 56, w = 2 },
        },
        {
          -- master sword
          { i = 71, x = 8, y = 0,  w = 2, h = 4 },
          { i = 73, x = 8, y = 32, w = 2, h = 4 },
        },
      },
      spoony = {
        {
          -- white spoon
          { i = 130, x = 8,         w = 2, h = 4 },
          { i = 132, x = 8, y = 32, w = 1, h = 2 },
          { i = 164, x = 8, y = 48, w = 2, h = 2 },
        },
        {
          -- metal spoon
          { i = 109, x = 8,         w = 2, h = 2 },
          { i = 128, x = 8, y = 16, w = 2, h = 4 },
          { i = 116, x = 8, y = 48, w = 2 },
          { i = 69,  x = 8, y = 56, w = 2 },
        },
        {
          -- wood handle spoon
          { i = 109, x = 8,         w = 2, h = 2 },
          { i = 128, x = 8, y = 16, w = 2, h = 4 },
          { i = 105, x = 8, y = 48, w = 2, h = 2 },
        },
      },
    },
  },
  playing_transition_in = {
    knifey = {
      { i = 4,  w = 4, h = 2 },
    },
    spoony = {
      { i = 36, w = 4, h = 2 },
    },
  },
  title = {
    bottom_line = {
      { i = 19 },
      { i = 32, x = 8 },
      { i = 33, x = 16 },
      { i = 33, x = 24 },
      { i = 33, x = 32 },
      { i = 33, x = 40 },
      { i = 33, x = 48 },
      { i = 33, x = 56 },
      { i = 33, x = 64 },
      { i = 33, x = 72 },
    },
    knife = {
      { i = 138, w = 2, h = 3 },
    },
    spoon = {
      { i = 140, w = 2, h = 3 },
    },
    text = {
      -- k
      k1 = {
        { i = 192, w = 2, h = 2 },
      },
      -- n
      n1 = {
        { i = 192, h = 2 },
        { i = 194, x = 8, h = 2 },
      },
      -- i
      i1 = {
        { i = 195 },
        { i = 208, y = 8 },
      },
      -- f
      f1 = {
        { i = 192, h = 2 },
        { i = 196, x = 8, h = 2 },
      },
      -- e
      e1 = {
        { i = 192, h = 2 },
        { i = 197, x = 8, h = 2 },
      },
      -- y
      y1 = {
        { i = 198, w = 2, h = 2 },
      },
      -- s
      s1 = {
        { i = 224, w = 2, h = 2 },
      },
      -- p
      p1 = {
        { i = 192, h = 2 },
        { i = 227, x = 8, h = 2 },
      },
      -- o
      o1 = {
        { i = 228, h = 2 },
        { i = 194, x = 8 },
        { i = 245, x = 8, y = 8 },
      },
      -- o
      o2 = {
        { i = 228, h = 2 },
        { i = 194, x = 8 },
        { i = 245, x = 8, y = 8 },
      },
      -- n
      n2 = {
        { i = 192, h = 2 },
        { i = 194, x = 8, h = 2 },
      },
      -- y
      y2 = {
        { i = 198, w = 2, h = 2 },
      },
    },
    top_line = {
      { i = 1 },
      { i = 1, x = 8 },
      { i = 1, x = 16 },
      { i = 1, x = 24 },
      { i = 1, x = 32 },
      { i = 1, x = 40 },
      { i = 1, x = 48 },
      { i = 1, x = 56 },
      { i = 1, x = 64 },
      { i = 1, x = 72 },
    },
  },
}

-->8
-- state definitions
state_init('object_debug', function()
  local s = {}
  s.color = 1

  s.add_color = function()
    local i     = s.color
    local step  = 8 * i
    local width = 127 - step
    local rects = {{ color = i, h = 128, w = width }}

    object_init('color_' .. i, { rects = rects })
      .pos({ x = -(width + 8), y = 127 })
      .move({ x = 0, y = 0, delay = 8 * i, duration = f(30), easing = 'outBack' })
  end

  s.update = function()
    if (s.color > 15) return
    s.add_color()
    s.color += 1
  end

  return s
end)

state_init('title_transition_in', function()
  local s = {}

  s.transition = { destination = 'title', timeout = 85 }

  s.draw = function()
    map(0, 0)
  end

  s.init = function()
    game.reset()

    local knife = tiles.title.knife
    local spoon = tiles.title.spoon
    local tline = tiles.title.top_line
    local bline = tiles.title.bottom_line

    object_init('title_knife', { tiles = knife, x = 16,   y = -100 }).move({ y = 24, delay = 40, duration = 30, easing = outBounce })
    object_init('title_spoon', { tiles = spoon, x = 96,   y = 227  }).move({ y = 80, delay = 40, duration = 30, easing = outBounce })
    object_init('title_tline', { tiles = tline, x = 200,  y = 40   }).move({ x = 32, delay = 10, duration = 10, easing = outBack   })
    object_init('title_bline', { tiles = bline, x = -328, y = 80   }).move({ x = 16, delay = 10, duration = 10, easing = outBack   })

    s.init_title_text()
  end

  s.init_title_text = function()
    local d  = 20
    local e  = outBack
    local kx = 200
    local ky = 48
    local sx = -200
    local sy = 64
    local t  = tiles.title.text

    object_init('title_k1', { tiles = t.k1, x = kx, y = ky }).move({ x = 16, delay = 20, duration = d, easing = e })
    object_init('title_n1', { tiles = t.n1, x = kx, y = ky }).move({ x = 32, delay = 23, duration = d, easing = e })
    object_init('title_i1', { tiles = t.i1, x = kx, y = ky }).move({ x = 48, delay = 26, duration = d, easing = e })
    object_init('title_f1', { tiles = t.f1, x = kx, y = ky }).move({ x = 56, delay = 29, duration = d, easing = e })
    object_init('title_e1', { tiles = t.e1, x = kx, y = ky }).move({ x = 72, delay = 32, duration = d, easing = e })
    object_init('title_y1', { tiles = t.y1, x = kx, y = ky }).move({ x = 88, delay = 35, duration = d, easing = e })
    object_init('title_s1', { tiles = t.s1, x = sx, y = sy }).move({ x = 16, delay = 35, duration = d, easing = e })
    object_init('title_p1', { tiles = t.p1, x = sx, y = sy }).move({ x = 32, delay = 32, duration = d, easing = e })
    object_init('title_o1', { tiles = t.o1, x = sx, y = sy }).move({ x = 48, delay = 29, duration = d, easing = e })
    object_init('title_o2', { tiles = t.o2, x = sx, y = sy }).move({ x = 64, delay = 26, duration = d, easing = e })
    object_init('title_n2', { tiles = t.n2, x = sx, y = sy }).move({ x = 80, delay = 23, duration = d, easing = e })
    object_init('title_y2', { tiles = t.y2, x = sx, y = sy }).move({ x = 96, delay = 20, duration = d, easing = e })
  end

  s.update = function()
    if (btnp(5)) game.go_to('title')
  end

  return s
end)

state_init('title',  function ()
  local s = {}

  s.flash = { color = 7, on = 0 }

  local start = {
    counter = 0,
    max     = f(24),
    off     = -10,
    on      = 100,
    pos     = 0,
  }

  s.draw = function()
    map(0, 0)
  end

  s.init = function()
    start.pos = start.on

    object_init('title_about', { text = text.about,      x = 14, y = 147 }).move({ y = 117, duration = 20, easing = 'outBack' })
    object_init('title_start', { text = text.start_game, x = 32, y = start.pos })
  end

  s.unload = function()
    game.objects_destroy({ 'title_about', 'title_start' })
  end

  s.update = function()
    s.update_start_text()
    if (btnp(5)) game.go_to('title_transition_out')
  end

  s.update_start_text = function()
    start.counter += 1

    if (start.counter >= start.max) then
      start.counter = 0

      if (start.pos == start.on) then
        start.pos = start.off
      else
        start.pos = start.on
      end
    end

    o('title_start').pos({ y = start.pos })
  end

  return s
end)

state_init('title_transition_out', function()
  local s = {}

  s.flash      = { color = 7, on = 0 }
  s.transition = { destination = 'playing_transition_in', timeout = 35 }

  s.draw = function()
    map(0, 0)
  end

  s.init = function()
    o('title_knife').move({ y = -100, delay = 5,  duration = 30, easing = 'inBack' })
    o('title_tline').move({ x = 200,  delay = 15, duration = 10, easing = 'inBack' })
    o('title_bline').move({ x = -328, delay = 15, duration = 10, easing = 'inBack' })
    o('title_spoon').move({ y = 227,  delay = 5,  duration = 30, easing = 'inBack' })

    s.transition_out_text_animation()
  end

  s.transition_out_text_animation = function()
    local d  = 20
    local e  = 'inBack'
    local kx = 200
    local sx = -200

    o('title_k1').move({ x = kx, delay = 15, duration = d, easing = e })
    o('title_n1').move({ x = kx, delay = 12, duration = d, easing = e })
    o('title_i1').move({ x = kx, delay = 9,  duration = d, easing = e })
    o('title_f1').move({ x = kx, delay = 6,  duration = d, easing = e })
    o('title_e1').move({ x = kx, delay = 3,  duration = d, easing = e })
    o('title_y1').move({ x = kx, delay = 0,  duration = d, easing = e })
    o('title_s1').move({ x = sx, delay = 0,  duration = d, easing = e })
    o('title_p1').move({ x = sx, delay = 3,  duration = d, easing = e })
    o('title_o1').move({ x = sx, delay = 6,  duration = d, easing = e })
    o('title_o2').move({ x = sx, delay = 9,  duration = d, easing = e })
    o('title_n2').move({ x = sx, delay = 12, duration = d, easing = e })
    o('title_y2').move({ x = sx, delay = 15, duration = d, easing = e })
  end

  return s
end)

state_init('playing_transition_in', function()
  local s = {}

  s.transition = { destination = 'playing', timeout = 130 }

  s.draw = function()
    map(0, 0)
  end

  s.init = function()
    game.objects_destroy_all()

    local k = tiles.playing_transition_in.knifey
    local s = tiles.playing_transition_in.spoony

    object_init('button_knifey', { tiles = k,                   x = 10, y = 127 }).move({ y = 95,  duration = 20, delay = 5, easing = 'outBounce' })
    object_init('button_spoony', { tiles = s,                   x = 86, y = 127 }).move({ y = 95,  duration = 20, delay = 5, easing = 'outBounce' })
    object_init('score_board',   { tiles = tiles.playing.score, x = 48, y = -24 }).move({ y = 87,  duration = 20, delay = 5, easing = 'outBounce' })
    object_init('score_text',    { text  = text.score,          x = 54, y = -19 }).move({ y = 92,  duration = 20, delay = 5, easing = 'outBounce' })
    object_init('score',         { text  = game.score,          x = 62, y = -12 }).move({ y = 99,  duration = 20, delay = 5, easing = 'outBounce' })
    object_init('floor',         { rects = rects.floor,         x = 4,  y = 143 }).move({ y = 111, duration = 20, easing = 'outBounce' })
    object_init('countin_3',     { text  = '3',                 x = 55, y = -12 }).move({ y = 44,  duration = 20, delay = 40,  easing = 'outBounce' })
    object_init('countin_2',     { text  = '2',                 x = 62, y = -12 }).move({ y = 44,  duration = 20, delay = 70,  easing = 'outBounce' })
    object_init('countin_1',     { text  = '1',                 x = 69, y = -12 }).move({ y = 44,  duration = 20, delay = 100, easing = 'outBounce' })
  end

  s.unload = function()
    game.objects_destroy({
      'countin_1',
      'countin_2',
      'countin_3',
    })
  end

  return s
end)

state_init('playing', function()
  local s = {}

  s.flash = { color = 7, on = 0 }

  s.defaults = {
    button_animations = {
      knifey = {
        active = false,
        frame  = 1,
      },
      spoony = {
        active = false,
        frame  = 1,
      },
    },
    fail_anim = {
      active      = false,
      dissolve_y1 = 7,
      dissolve_y2 = 80,
      flash       = false,
      timeout     = f(50),
    },
    timeout = {
      max        = f(150),
      min        = f(20),
      multiplier = 0.95,
      remaining  = 0,
      start      = f(120),
    },
  }

  s.button_animations = {}
  s.fail_anim         = {}
  s.timeout           = {}
  s.timer = {
    color     = 8,
    height    = 2,
    max_width = 120,
    start_x   = 4,
    start_y   = 4,
  }
  s.utensil = {
    index    = 0,
    sprites  = {},
    previous = {
      index = nil,
      type  = nil,
    },
    type     = nil,
  }

  s.animate_button = function(button)
    s.button_animations[button].active = true
  end

  s.choose_utensil = function()
    s.utensil.previous.type  = s.utensil.type
    s.utensil.previous.index = s.utensil.index

    local utensil_type  = rnd(1) > 0.5 and text.knifey or text.spoony
    local utensil_array = tiles.playing.utensils[utensil_type]
    local utensil_index = rndint(1, #utensil_array)

    if (utensil_index == s.utensil.previous.index) and
       (utensil_type  == s.utensil.previous.type) then
      return s.choose_utensil()
    end

    game.object_destroy('utensil')

    s.utensil.type  = utensil_type
    s.utensil.index = utensil_index
    object_init('utensil', { tiles = utensil_array[utensil_index], x = 48, y = 10 }).move({ y = 16, duration = 3 })
  end

  s.decrease_timeout_remaining = function()
    s.timeout.remaining -= 1
    if (s.timeout.remaining <= 0) s.round_failed()
  end

  s.decrease_timeout_start = function()
    local new_timeout = s.timeout.start * s.timeout.multiplier
    s.timeout.start = mid(s.timeout.min, new_timeout, s.timeout.start)
  end

  s.dissolve_utensil = function()
    local rects = {{ w = 48, h = 0, color = 0 }}
    local y1 = s.fail_anim.dissolve_y1
    local y2 = s.fail_anim.dissolve_y2
    object_init('fail_wipe_top_' .. y1,    { rects = rects, x = 39, y = y1 })
    object_init('fail_wipe_bottom_' .. y2, { rects = rects, x = 39, y = y2 })
  end

  s.draw = function()
    s.draw_timer()
    s.draw_buttons()
    if (s.fail_anim.active) s.draw_fail_anim()
    map(0, 0)
  end

  s.draw_button = function(button)
    local button_animation = s.button_animations[button]
    local frame            = button_animation.frame
    local button_tiles     = tiles.playing.buttons[button]
    local x_values         = { knifey = 10, spoony = 86 }

    object_init('button_' .. button, { tiles = button_tiles[frame] })
      .pos({
        x = x_values[button],
        y = 95,
      })

    if (button_animation.active) button_animation.frame += 1

    if (button_animation.frame == #button_tiles) then
      button_animation.active = false
      button_animation.frame  = 1
    end
  end

  s.draw_buttons = function()
    s.draw_button(text.knifey)
    s.draw_button(text.spoony)
  end

  s.draw_fail_anim = function()
    if (s.fail_anim.flash) then
      rectfill(0, 0, 127, 127, 8)
      s.fail_anim.flash = false
      return
    end

    s.dissolve_utensil()
    o('floor').move({ y = 127, duration = 20 })
  end

  s.draw_timer = function()
    if (s.timeout.remaining <= 0) return

    x = s.timer.start_x + s.timer_width()
    y = s.timer.start_y + s.timer.height - 1

    rectfill(s.timer.start_x, s.timer.start_y, x, y, s.timer.color)
  end

  s.evaluate_input = function(choice)
    if (choice == s.utensil.type) return s.round_passed()
    s.round_failed()
  end

  s.get_input = function()
    if (s.fail_anim.active) return

    if (btnp(0)) then
      s.animate_button(text.knifey)
      s.evaluate_input(text.knifey)
    end

    if (btnp(1)) then
      s.animate_button(text.spoony)
      s.evaluate_input(text.spoony)
    end
  end

  s.init = function()
    s.reset()
    s.new_round()

    object_init('high_score_icon', { tiles = tiles.playing.high_score_icon, x = 106, y = -10 })
    object_init('high_score_text', { text = game.high_score, x = 113, y = 8 }).move({ y = 8, duration = 30, easing = 'outBack' })
  end

  s.new_round = function()
    s.timeout.remaining = s.timeout.start
    s.update_score_display()
    s.choose_utensil()
  end

  s.reset = function()
    game.reset_vars()
    s.button_animations = clone(s.defaults.button_animations)
    s.fail_anim         = copy(s.defaults.fail_anim)
    s.timeout           = copy(s.defaults.timeout)
  end

  s.round_failed = function()
    s.fail_anim.active = true
    s.fail_anim.flash  = true
  end

  s.round_passed = function()
    game.update_score()
    s.update_score_display()
    s.update_high_score_display()
    s.decrease_timeout_start()
    s.new_round()
  end

  s.score_x = function()
    local score_text = game.score .. ''
    return 64 - #score_text * 2
  end

  s.timer_width = function()
    local elapsed_percentage = s.timeout.remaining / s.timeout.start
    return flr(elapsed_percentage * s.timer.max_width)
  end

  s.unload = function()
    game.object_destroy('utensil')
    for i = 0, 127 do
      game.object_destroy('fail_wipe_top_' .. i)
      game.object_destroy('fail_wipe_bottom_' .. i)
    end
  end

  s.update = function()
    if (s.fail_anim.active) return s.update_fail_anim()
    s.decrease_timeout_remaining()
    s.get_input()
  end

  s.update_fail_anim = function()
    s.fail_anim.dissolve_y1 += 2
    s.fail_anim.dissolve_y2 -= 2
    s.fail_anim.timeout     -= 1

    if (s.fail_anim.dissolve_y1 > s.defaults.fail_anim.dissolve_y2) then
      s.fail_anim.dissolve_y1 = s.defaults.fail_anim.dissolve_y2
    end

    if (s.fail_anim.dissolve_y2 < s.defaults.fail_anim.dissolve_y1) then
      s.fail_anim.dissolve_y2 = s.defaults.fail_anim.dissolve_y1
    end

    if (s.fail_anim.timeout == 0) game.go_to('game_over')
  end

  s.update_high_score_display = function()
    if (game.high_score_beaten) then
      game.object_destroy('high_score_text')
      o('high_score_icon').pos({ y = 6 }).move({ y = 8, duration = 3 })
      object_init('high_score_text', { text = game.high_score, x = 113, y = 6 }).move({ y = 8, duration = 3 })
    end
  end

  s.update_score_display = function()
    o('score_board').pos({ y = 86 }).move({ y = 87, delay = 3, duration = 2 })
    object_init('score', { text = game.score, x = s.score_x(), y = 99 })
  end

  return s
end)

state_init('game_over', function()
  local s = {}

  s.draw = function()
    map(0, 0)
  end

  s.init = function()
    game.objects_destroy({
      'button_knifey',
      'button_spoony',
      'score',
      'utensil',
    })

    local high_score_text = text['high_score'] .. game.high_score
    local score_text      = text['score'] .. ': ' .. game.score

    object_init('game_over_bg',    { rects = {{w = 111, h = 111, color = 8}}, x = 8, y = 8 })
    object_init('game_over_text',  { text = text.game_over,  x = 44, y = 16, outline = 0 })
    object_init('score_text',      { text = score_text,      x = 46, y = 32, outline = 0 })
    object_init('high_score_text', { text = high_score_text, x = 36, y = 40, outline = 0 })
    object_init('play_again', { text = text.play_again, x = 22, y = 112, outline = 0 })

    if (game.high_score_beaten) then
      object_init('high_score_beaten_text', { text = text.high_score_beaten, x = 24, y = 56, outline = 0 })
    end
  end

  s.unload = function()
    o('game_over_bg').pos({ x = 200, y = 200 })
    o('game_over_text').pos({ x = 200, y = 200 })
    o('play_again').pos({ x = 200, y = 200 })

    if (game.high_score_beaten) then
      o('high_score_beaten_text').pos({ x = 200, y = 200 })
    end
  end

  s.update = function()
    if (btnp(4)) game.go_to('title_transition_in')
    if (btnp(5)) game.go_to('playing')
  end

  return s
end)

-->8
-- game loop
function _init()
  game.init()
end

function _update60()
  game.update()
end

function _draw()
  game.draw()
end
__gfx__
aaaaaaaaaaaaaaaaaaaaaaa4a9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a99999999999999999999994a9000000007077077770777707777077770707700000000000000000000000000000000000000000000000000000000000000000
a90000000000000000000094a9000000007077070770077007707077000707700000000000000000000000000000000000000000000000000000000000000000
a90000000000000000000094a9000000007077070770077007700077700777700070770777707777077770777707077000000000000000000000000000000000
a90000000000000000000094a9000000007770070770077007770077000077000070770707700770077070770007077000707707777077770777707777070770
a90000000000000000000094a9000000007077070770777707700077770077000070770707700770077000777007777000707707777077770777707777070770
a90000000000000000000094a9000000000000000000000000000000000000000077700707700770077700770000770000707707777077770777707777070770
a90000000000000000000094a9000000000000000000000000000000000000000070770707707777077000777700770000707707077007700770707700070770
a9000000990000009900000000000000000000000000000000000000000000000000000000000000000000000000000000707707077007700770007770077770
a9000000990000009900000000000000000888888888888888888888888880000000000000000000000000000000000000777007077007700777007700007700
a9000000990000009900000000000000008888888888888888888888888888000088888888888888888888888888880000707707077077770770007777007700
99000000990000009900000000000000008888888888888888888888888888000888888888888888888888888888888088888888888888888888888888888888
99000000990000009900000000000000002222222222222222222222222222000888888888888888888888888888888088888888888888888888888888888888
a9000000990000009900000000000000002222222222222222222222222222000222222222222222222222222222222088888888888888888888888888888888
990000009900000099aaaaaaaaaaaaaa002222222222222222222222222222000222222222222222222222222222222022222222222222222222222222222222
99000000990000004999999999999999001111111111111111111111111111000111111111111111111111111111111011111111111111111111111111111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000007777077770777707777077770707700000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000007000070770707707077070770707700000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000007777077770707707077070770777700077770777707777077770777707077000000000000000000000000000000000
00000000000000000000000000000000000077070000707707077070770077000070000707707077070770707707077000777707777077770777707777070770
00000000000000000000000000000000007777070000777707777070770077000077770777707077070770707707777000777707777077770777707777070770
aa9999a9999999999999999999999999000000000000000000000000000000000000770700007077070770707700770000777707777077770777707777070770
99999999999999994999944444444444000000000000000000000000000000000077770700007777077770707700770000700007077070770707707077070770
000000940000009499940000aaaaaaaa000000000000000000000000000000000000000000000000000000000000000000777707777070770707707077077770
000000940000009499940000a9999999000bbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000007707000070770707707077007700
000000940000009499940000a900000000bbbbbbbbbbbbbbbbbbbbbbbbbbbb00000bbbbbbbbbbbbbbbbbbbbbbbbbb00000777707000077770777707077007700
000000940000009400000000a900000000bbbbbbbbbbbbbbbbbbbbbbbbbbbb000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000940000009400000000a9000000003333333333333333333333333333000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000940000009400000000a90000000033333333333333333333333333330003333333333333333333333333333330bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
999999940000009400000000a9000000003333333333333333333333333333000333333333333333333333333333333033333333333333333333333333333333
444444440000009400000000a9000000001111111111111111111111111111000111111111111111111111111111111011111111111111111111111111111111
0000000007600000000555555555000000665555000056555505000076600000000000007666666655555555000000077000000088888888f000000800000000
000000076655000000055555555500000056555500005655550500007666600000000000766666665555555500000077f800000088888888f0000000dddddddd
000000766555000000055555555500000005555500005555500500007666660000000000766666665555555500000778f880000088888888f000000866666665
000000766555000000055555555500000000555500000555505000007666666000000000766666655555555500007788f888000088888888f00000087dddddd5
000007665555000000005555555500000007555500000555005000007666666600000000766666655555555500077888f088800088888888f0000000dddd5ddd
000007665555000000005555555500000076555500000050050000007666666650000000766666655555555500778888f000880088888888f00000005555ddd5
000076655555000000005555555500000065555500000055550000007666666655000000666666655555555507788888f000088088888888f0000000dddddddd
000076655555000000000000000000000065555500000005500000007666666655500000555555555555555507888888f0000080888888888000000855555550
00007665555500000000ffffff4200000005555555550000000000007666666655550000111111111110000078888888f0000008000000000000000000000000
000766655555000000004444444200000005555555550000000000007666666655555000ffff4ff44f4442228888888ff00000080000766ddddddddddd550000
0007665555550000000044422442000000055555555500000000000076666666555550004444444444442242888888fff000000800076ddd666666660dd55000
000766555555000000004426524200000005555555550000000000007666666655555500444444444444224288888ffff0000008000dddd66ddd777750dd5000
00076555555500000000442552420000000055555555000000000000766666665555550044444444444442228888fffff0000008000dddd6ddd6dddd50d55000
0076655555550000000044422442000000005555555500000000000076666666555555504444444444442242888ffffff00000080000dddd5dddd55505550000
007665555555000000004444444200000000555555550000000000007666666655555550444444444444422288fffffff00000080000000ddddddddd50000000
00766555555500000000444ff4420000000005555550000000000000766666665555555022222222222222428ffffffff0000008000000000555555500000000
0066555555550000000044ffff42000000000055550000000000000076666666555555550000111111110000fffffff8f00000080000006655000000a0a0a000
006655555555000000004ff44ff2000000000055550000000000000076666666555555550000222222220000ffffff88f00000080000065555500000a9a9a000
006655555555000000004f4444f2000000000055550000000000000076666666555555550000444444220000fffff888f00000080000655555550000aaaaa000
006655555555000000004f4444f2000000000055550000000000000076666666555555550000444444420000ffff8888f00000080006555005555000aaaaa000
006655555555000000004f444442000000000055550000000000000076666666555555550000222222220000fff88888f0000008006555000055550099999000
0066555555550000000044444442000000000055550000000000000076666666555555550000444444420000ff888888f0000008006550000555550000000000
006555555555000000004f444422000000000055550000000000000076666666555555550000444444420000f8888888f0000008065500005555555000000000
006555555555000000004442222200000000005555000000000000007666666655555555000044444442000088888888f0000008065000055555555000000000
006555555555000000000000000000000000065555500000000000007666666655555555000044444442000088888888f0000008065000555555655000000000
006555555555000000006666666500000000065555500000000000007666666655555555000022222222000088888888f0000008655000555555665500000000
006555555555000000006655555500000000065555500000000000007666666655555555000044444442000088888888f0000008650005555555665500000000
006555555555000000006555555500000000055555500000000000007666666655555555000044444442000088888888f0000008650055555555665500000000
006555555555000000005555555500000000055665500000000000007666666655555555000044444422000088888888f0000008650055555556665500000000
006555555555000000005555555500000000656555550000000000007666666655555555000022222221000088888888f0000008650555555566665500000000
006555555555000000000555555000000000656555550000000000007666666655555555000666666655500088888888f0000008550555555566655500000000
005555555555000000000055550000000000556555550000000000007666666655555555000655555551100088888888f0000008555555555666655500000000
0555555566666550007776660000000007766600ffffffff0aaaaaaa9aaa99999999999999999990000000000000000000000000000000000000000000000000
0555556666665550077777666600000077766600444444449999999999999999999999999999999900000000000000000000000bbb0000000000000000000000
0055666666655500777777766660000077766600444444449000000000000000000000000000000900000000000000000000000bbb0000000000000000000000
0005556666555000771777776666000077776600444444449000000000000000000000000000000900800000000000000000000bbb0000000000000000000000
0000555555550000711177777666600077776600444444449011111111111111111111111111110900880000000000000000000bbb0000000000000000000000
000005555550000071d117777666660077777600444444449011111111111111111111111111110900888000000000000000000bbb0000000000000000000000
00000055550000007ddd11777766660077777600444444449011111111111111111111111111110900888800000000000000000bbb0000000000000000000000
00000005500000007ddd11177766660077777600444444449011111111111111111111111111110900888880000000000000000bbb0000000000000000000000
00000005500000007dddd1177766666077777660444444449011111111111111111111111111110900888888000000000000000bbb0000000000000000000000
00000005500000007dddd1117766666077777760222222229011111111111111111111111111110900888888800000000000000bbb0000000000000000000000
00000005500000007dddd111776666600777776022222222901111111111111111111111111111090088888888000000000000bbbbb000000000000000000000
00000005500000007ddddd1177766666077777602222222290111111111111111111111111111109008888888800000000000bbbbbbb00000000000000000000
00000005500000007ddddd117776666607777766222222229011111111111111111111111111110900888888880000000000bbbbbbbbb0000000000000000000
00000005500000007ddddd111776666607777776000000009011111111111111111111111111110900888888880000000000bbbbbbbbb0000000000000000000
00000005500000007ddddd111776666600777776000000009011111111111111111111111111110900888888880000000000bbbbbbbbb0000000000000000000
00000005500000007ddddd111776666600777776000000009011111111111111111111111111110900888888880000000000bbbbbbbbb0000000000000000000
000000655500000077dddd111776666600777777600000009011111111111111111111111111110900888888880000000000bbbbbbbbb0000000000000000000
000000655500000007dddd1117766666007777776000000090011111111111111111111111111009008888888800000000000bbbbbbb00000000000000000000
000000655500000007ddd11117766666007777777600000090000000000000000000000000000009008888888800000000000bbbbbbb00000000000000000000
000000655500000007ddd1111766666000077777760000009aaaaaaaaaaaaaaaaaa999aa9aaa99990088888888000000000000bbbbb000000000000000000000
000000555500000007ddd1117766666000077777776000000999999999999999999999999999999000888888880000000000000bbb0000000000000000000000
0000005555000000077d111177666600000777777760000000000000000000000000000000000000008888888800000000000000000000000000000000000000
00000055550000000071111177666600000077777766000000000000000000000000000000000000008888888800000000000000000000000000000000000000
00000055550000000077111776666000000077777776000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000055550000000007717766660000000077777776000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000055550000000007777666600000000007777776000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000055550000000077776666000000000007777776000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000055550000000077766660000000000007777766000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000055550000000077666600000000000007777766000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000055550000000777666600000000000000777760000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000055550000000776666000000000000000766660000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000055550000000776666000000000000000066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777707777777777770000770000777777777777777700777770007777700000000000000000000000000000000000000000000000000000000000000000
00777777707777777777777000777000777777777777777700777770007777700000000000000000000000000000000000000000000000000000000000000000
00777777707777777777777700777700777777777777777700777770007777700000000000000000000000000000000000000000000000000000000000000000
00777777707777777777777700777770777777777777777700777770007777700000000000000000000000000000000000000000000000000000000000000000
00777777707777777777777700777777700000007000000000777770007777700000000000000000000000000000000000000000000000000000000000000000
00777777707777777777777700777777700000007000000000777770007777700000000000000000000000000000000000000000000000000000000000000000
00777777777777777777777700777777777700007777000000777777777777700000000000000000000000000000000000000000000000000000000000000000
00777777777777707777777700000000777700007777000000777777777777700000000000000000000000000000000000000000000000000000000000000000
00777777777777007777777700000000777700007777000000000777777700000000000000000000000000000000000000000000000000000000000000000000
00777777707777707077777700000000700000007000000000000777777700000000000000000000000000000000000000000000000000000000000000000000
00777777707777777077777700000000700000007000000000000777777700000000000000000000000000000000000000000000000000000000000000000000
00777777707777777077777700000000700000007777777700000777777700000000000000000000000000000000000000000000000000000000000000000000
00777777707777777077777700000000700000007777777700000777777700000000000000000000000000000000000000000000000000000000000000000000
00777777707777777077777700000000700000007777777700000777777700000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077777777777770077777777777700000077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777770077777777777770000777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777770077777770777777007777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777770077777770777777007777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777770077777770777777007777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777700000000077777770777777007777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777770077777770777777007777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777770000000077777777007777777077777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777770000000077777770007777777077777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777770000000070000000007777777077777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777770000000070000000007777777077777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777770000000070000000007777777077777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777770000000070000000007777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777700000000070000000000777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3301010101010101010101010101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0300000000000000000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0300000000000000000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0300000000000000000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000000000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000000000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000000000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000000000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000000000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000000000000000000dd3100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000000000000000000dd3100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000000000000000000dd3100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000000000000000000dd3100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1213131320202121212222232323233000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000c90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
