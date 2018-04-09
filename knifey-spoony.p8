pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- knifey spoony
-- by jonic + ribbon black
-- v0.12.0

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
-- global vars and helpers

local high_score        = 0
local high_score_beaten = false
local score             = 0

local update_objects = true
local objects        = {}
local screens        = {}
local screen         = nil

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

function reset_globals()
  high_score        = dget(0)
  high_score_beaten = false
  score             = 0
  update_objects    = true
end

function rndint(min, max)
  return flr(rnd(max)) + min
end

function update_high_score()
  if (score > high_score) then
    high_score        = score
    high_score_beaten = true
    dset(0, high_score)
  end
end

function update_score()
  score += 1
  update_high_score()
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
-- sprites

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
  start_game        = 'press x to start'
}

local tiles = {
  playing = {
    transition_buttons = {
      knifey = {
        { i = 4,  w = 4, h = 2 },
      },
      spoony = {
        { i = 36, w = 4, h = 2 },
      },
    },
    buttons = {
      knifey = {
        { i = 4,  x = 10, y = 95, w = 4, h = 2 },
        { i = 8,  x = 10, y = 95, w = 4, h = 2 },
        { i = 12, x = 10, y = 95, w = 4, h = 2 },
        { i = 8,  x = 10, y = 95, w = 4, h = 2 },
      },
      spoony = {
        { i = 36, x = 86, y = 95, w = 4, h = 2 },
        { i = 40, x = 86, y = 95, w = 4, h = 2 },
        { i = 44, x = 86, y = 95, w = 4, h = 2 },
        { i = 40, x = 86, y = 95, w = 4, h = 2 },
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

function init_object(props)
  local o = {}

  o.color            = props.color or 7
  o.delay            = props.delay or 0
  o.duration         = props.duration or 0
  o.easing           = props.easing or 'linear'
  o.frame_count      = 0
  o.pos_x            = 0
  o.pos_y            = 0
  o.outline          = props.outline or nil
  o.repeat_after     = props.repeat_after or nil
  o.repeat_countdown = props.repeat_after or nil
  o.repeating        = props.repeat_after ~= nil
  o.tiles            = props.tiles or nil
  o.rects            = props.rects or nil
  o.text             = props.text  or nil
  o.updated          = false
  o.x                = props.x or { start = props.x1 or 0, dest = props.x2 or nil }
  o.y                = props.y or { start = props.y1 or 0, dest = props.y2 or nil }

  o.calculate_pos = function(pos_key)
    local pos = o[pos_key]

    if (pos.dest == nil or o.delay > 0) return pos.start
    if (o.is_complete()) return pos.dest

    local t = o.frame_count        -- elapsed time
    local b = pos.start            -- begin
    local c = pos.dest - pos.start -- change == ending - beginning
    local d = o.duration           -- duration (total time)
    local e = o.easing
    local new_pos = 0

    if     e == 'outBack'   then new_pos = outBack(t, b, c, d)
    elseif e == 'inBack'    then new_pos = inBack(t, b, c, d)
    elseif e == 'outBounce' then new_pos = outBounce(t, b, c, d)
    elseif e == 'inBounce'  then new_pos = inBounce(t, b, c, d)
    else                         new_pos = linear(t, b, c, d)
    end

    return flr(new_pos)
  end

  o.center_x = function()
    return 64 - #o.text * 2
  end

  o.draw_rect = function(r)
    local x1    = (r.x or 0) + o.pos_x
    local y1    = (r.y or 0) + o.pos_y
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
    local x       = o.x == 'center' and o.center_x() or o.pos_x
    local y       = o.pos_y

    if outline ~= nil then
      print(text, x - 1, y, outline)
      print(text, x + 1, y, outline)
      print(text, x, y - 1, outline)
      print(text, x, y + 1, outline)
    end

    print(text, x, y, color)
  end

  o.draw_tile = function(t)
    local x  = (t.x or 0) + o.pos_x
    local y  = (t.y or 0) + o.pos_y
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

  o.is_complete = function()
    return o.frame_count > o.duration
  end

  o.set_pos = function()
    o.pos_x = o.x
    o.pos_y = o.y

    if (type(o.x) == 'table') o.pos_x = o.calculate_pos('x')
    if (type(o.y) == 'table') o.pos_y = o.calculate_pos('y')
  end

  o.should_draw = function()
    return update_objects and o.updated
  end

  o.should_update = function()
    return update_objects and not o.is_complete()
  end

  o.tick = function()
    if o.delay > 0 then
      o.delay -= 1
      return
    end

    o.frame_count += 1
  end

  o.update = function()
    if (not o.should_update()) return

    o.tick()
    o.set_pos()
    o.updated = true
  end

  o.draw = function()
    if (not o.should_draw()) return

    if (o.type == 'tiles') o.draw_tiles(o.tiles)
    if (o.type == 'rects') o.draw_rects(o.rects)
  end

  add(objects, o)

  return o
end

function destroy_object(o)
  if (o == nil) return
  del(objects, o)
end

function destroy_objects()
  objects = copy({})
end

-->8
-- text

text = {
  about             = '2018 jonic + ribbon black',
  game_over         = 'game over!',
  high_score        = 'high score: ',
  high_score_beaten = '** new high score **',
  knifey            = 'knifey',
  play_again        = 'press x to play again',
  score             = 'score',
  spoony            = 'spoony',
  start_game        = 'press x to start',

  center_x = function(str)
    str = str .. ''
    return 64 - #str * 2
  end,

  get = function(key)
    return text[key]
  end,

  outline = function(str, x, y, color, outline)
    print(str, x - 1, y, outline)
    print(str, x + 1, y, outline)
    print(str, x, y - 1, outline)
    print(str, x, y + 1, outline)
    print(str, x, y,     color)
  end,

  output = function(str, x, y, color, outline)
    local outline = outline or nil

    if (outline != nil) then
      return text.outline(str, x, y, color, outline)
    end

    print(str, x, y, color)
  end,

  output_center = function(str, y, color, outline)
    local x = text.center_x(str)
    text.output(str, x, y, color, outline)
  end,

  show = function(key, x, y, color, outline)
    text.output(text[key], x, y, color, outline)
  end,

  show_center = function(key, y, color, outline)
    text.output_center(text[key], y, color, outline)
  end
}

-->8
-- screens

function init_screen(name, props)
  local s = {}

  -- take everything from level object and add it to this `props` key
  s.props = props()

  s.frame_count = 0

  s.init = function()
    destroy_objects()
    s.frame_count = 0
    if (s.props.init) s.props.init()
  end

  s.draw_flash = function()
    rectfill(0, 0, 127, 127, s.props.flash.color)
  end

  s.should_flash = function()
    return (s.props.flash ~= nil) and (s.props.flash.on == s.frame_count)
  end

  s.update = function()
    s.frame_count += 1

    if (s.props.transition ~= nil) then
      if (s.frame_count == s.props.transition.timeout) then
        go_to(s.props.transition.destination)
      end
    end

    if (s.props.update) s.props.update()
  end

  s.draw = function()
    if (s.should_flash()) return s.draw_flash()
    if (s.props.draw) s.props.draw()
    map(0, 0)
  end

  screens[name] = s

  return s
end

function go_to(name)
  screen = screens[name]
  screen.init()
end

-->8
-- init screens

init_screen('title_transition_in', function()
  local s = {}

  s.transition = {
    destination = 'title',
    timeout     = 85,
  }

  s.transition_in_text_animation = function()
    local d   = 20
    local e   = 'outBack'
    local kx1 = 200
    local ky  = 48
    local sx1 = -200
    local sy  = 64
    local t   = tiles.title.text

    init_object({ tiles = t.k1, x1 = kx1, x2 = 16, y = ky, delay = 20, duration = d, easing = e })
    init_object({ tiles = t.n1, x1 = kx1, x2 = 32, y = ky, delay = 23, duration = d, easing = e })
    init_object({ tiles = t.i1, x1 = kx1, x2 = 48, y = ky, delay = 26, duration = d, easing = e })
    init_object({ tiles = t.f1, x1 = kx1, x2 = 56, y = ky, delay = 29, duration = d, easing = e })
    init_object({ tiles = t.e1, x1 = kx1, x2 = 72, y = ky, delay = 32, duration = d, easing = e })
    init_object({ tiles = t.y1, x1 = kx1, x2 = 88, y = ky, delay = 35, duration = d, easing = e })

    init_object({ tiles = t.y2, x1 = sx1, x2 = 96, y = sy, delay = 20, duration = d, easing = e })
    init_object({ tiles = t.n2, x1 = sx1, x2 = 80, y = sy, delay = 23, duration = d, easing = e })
    init_object({ tiles = t.o2, x1 = sx1, x2 = 64, y = sy, delay = 26, duration = d, easing = e })
    init_object({ tiles = t.o1, x1 = sx1, x2 = 48, y = sy, delay = 29, duration = d, easing = e })
    init_object({ tiles = t.p1, x1 = sx1, x2 = 32, y = sy, delay = 32, duration = d, easing = e })
    init_object({ tiles = t.s1, x1 = sx1, x2 = 16, y = sy, delay = 35, duration = d, easing = e })
  end

  s.init = function()
    local bline = tiles.title.bottom_line
    local knife = tiles.title.knife
    local spoon = tiles.title.spoon
    local tline = tiles.title.top_line

    s.transition_in_text_animation()

    init_object({ tiles = knife, x1 = 16,   y1 = -100, x2 = 16, y2 = 24, delay = 40, duration = 30, easing = 'outBounce' })
    init_object({ tiles = spoon, x1 = 96,   y1 = 227,  x2 = 96, y2 = 80, delay = 40, duration = 30, easing = 'outBounce' })
    init_object({ tiles = tline, x1 = 200,  y  = 40,   x2 = 32,          delay = 10, duration = 10, easing = 'outBack'   })
    init_object({ tiles = bline, x1 = -328, y  = 80,   x2 = 16,          delay = 10, duration = 10, easing = 'outBack'   })
  end

  s.update = function()
    if (btnp(5)) go_to('title')
  end

  return s
end)

init_screen('title',  function ()
  local s = {}

  s.flash = {
    color = 7,
    on    = 0,
  }
  s.start_text_flash = 0

  s.idle_text_animation = function()
    local d   = 10
    local dir = 'inOut'
    local ky1 = 48
    local ky2 = 44
    local sy1 = 64
    local sy2 = 68
    local t   = tiles.title.text

    init_object({ tiles = t.k1, x = 16, y = ky1 })
    init_object({ tiles = t.n1, x = 32, y = ky1 })
    init_object({ tiles = t.i1, x = 48, y = ky1 })
    init_object({ tiles = t.f1, x = 56, y = ky1 })
    init_object({ tiles = t.e1, x = 72, y = ky1 })
    init_object({ tiles = t.y1, x = 88, y = ky1 })

    init_object({ tiles = t.y2, x = 96, y = sy1 })
    init_object({ tiles = t.n2, x = 80, y = sy1 })
    init_object({ tiles = t.o2, x = 64, y = sy1 })
    init_object({ tiles = t.o1, x = 48, y = sy1 })
    init_object({ tiles = t.p1, x = 32, y = sy1 })
    init_object({ tiles = t.s1, x = 16, y = sy1 })
  end

  s.show_start_text = function()
    s.start_text_flash += 1

    if (s.start_text_flash == 24) s.start_text_flash = 0
    if (s.start_text_flash < 12) text.show_center('start_game', 100, 7)
  end

  s.init = function()
    local bline = tiles.title.bottom_line
    local knife = tiles.title.knife
    local spoon = tiles.title.spoon
    local tline = tiles.title.top_line

    init_object({ tiles = knife, x = 16, y = 24 })
    init_object({ tiles = tline, x = 32, y = 40 })
    init_object({ tiles = bline, x = 16, y = 80 })
    init_object({ tiles = spoon, x = 96, y = 80 })

    s.idle_text_animation()
  end

  s.update = function()
    if (btnp(5)) go_to('title_transition_out')
  end

  s.draw = function()
    s.show_start_text()
    text.show_center('about', 117, 7)
  end

  return s
end)

init_screen('title_transition_out', function()
  local s = {}

  s.flash = {
    color = 7,
    on    = 0,
  }
  s.transition = {
    destination = 'playing_transition_in',
    timeout     = 35,
  }

  s.transition_out_text_animation = function()
    local d   = 20
    local e   = 'inBack'
    local kx2 = 200
    local ky  = 48
    local sx2 = -200
    local sy  = 64
    local t   = tiles.title.text

    init_object({ tiles = t.k1, x1 = 16, x2 = kx2, y = ky, delay = 15, duration = d, easing = e })
    init_object({ tiles = t.n1, x1 = 32, x2 = kx2, y = ky, delay = 12, duration = d, easing = e })
    init_object({ tiles = t.i1, x1 = 48, x2 = kx2, y = ky, delay = 9,  duration = d, easing = e })
    init_object({ tiles = t.f1, x1 = 56, x2 = kx2, y = ky, delay = 6,  duration = d, easing = e })
    init_object({ tiles = t.e1, x1 = 72, x2 = kx2, y = ky, delay = 3,  duration = d, easing = e })
    init_object({ tiles = t.y1, x1 = 88, x2 = kx2, y = ky, delay = 0,  duration = d, easing = e })

    init_object({ tiles = t.y2, x1 = 96, x2 = sx2, y = sy, delay = 15, duration = d, easing = e })
    init_object({ tiles = t.n2, x1 = 80, x2 = sx2, y = sy, delay = 12, duration = d, easing = e })
    init_object({ tiles = t.o2, x1 = 64, x2 = sx2, y = sy, delay = 9,  duration = d, easing = e })
    init_object({ tiles = t.o1, x1 = 48, x2 = sx2, y = sy, delay = 6,  duration = d, easing = e })
    init_object({ tiles = t.p1, x1 = 32, x2 = sx2, y = sy, delay = 3,  duration = d, easing = e })
    init_object({ tiles = t.s1, x1 = 16, x2 = sx2, y = sy, delay = 0,  duration = d, easing = e })
  end

  s.init = function()
    local bline = tiles.title.bottom_line
    local knife = tiles.title.knife
    local spoon = tiles.title.spoon
    local tline = tiles.title.top_line

    init_object({ tiles = knife, x1 = 16, y1 = 24, x2 = 16,   y2 = -100, delay = 5,  duration = 30, easing = 'inBack' })
    init_object({ tiles = spoon, x1 = 96, y1 = 80, x2 = 96,   y2 = 227,  delay = 5,  duration = 30, easing = 'inBack' })
    init_object({ tiles = tline, x1 = 32, y  = 40, x2 = 200,             delay = 15, duration = 10, easing = 'inBack' })
    init_object({ tiles = bline, x1 = 16, y  = 80, x2 = -328,            delay = 15, duration = 10, easing = 'inBack' })

    s.transition_out_text_animation()
  end

  return s
end)

init_screen('playing_transition_in', function()
  local s = {}

  s.count_in       = 0
  s.count_in_timer = 0
  s.transition     = {
    destination = 'playing',
    timeout     = 130,
  }

  s.init = function()
    s.count_in       = 0
    s.count_in_timer = 0

    local k = tiles.playing.transition_buttons.knifey
    local s = tiles.playing.transition_buttons.spoony

    init_object({ tiles = k, x = 10, y1 = 127, y2 = 95, duration = 20, delay = 5, easing = 'outBounce' })
    init_object({ tiles = s, x = 86, y1 = 127, y2 = 95, duration = 20, delay = 5, easing = 'outBounce' })
    init_object({ tiles = tiles.playing.score, x = 48, y1 = -24, y2 = 87, duration = 20, delay = 5, easing = 'outBounce' })
    init_object({ type  = 'rects', rects = rects.floor, x = 4, y1 = 143, y2 = 111, duration = 20, easing = 'outBounce' })
  end

  s.update = function()
    s.count_in_timer += 1
  end

  s.draw = function()
    if (s.count_in_timer >= 40)  s.count_in = 3
    if (s.count_in_timer >= 70)  s.count_in = 2
    if (s.count_in_timer >= 100) s.count_in = 1

    if (s.count_in > 0) print(s.count_in, 62, 44, 7)
  end

  return s
end)

init_screen('playing', function()
  local s = {}

  s.defaults = {
    button_animations = {
      knifey = {
        animating = false,
        frame     = 1,
      },
      spoony = {
        animating = false,
        frame     = 1,
      },
    },
    failed_state = {
      animating   = false,
      flash       = false,
      timeout     = 50,
      dissolve_y1 = 7,
      dissolve_y2 = 80,
    },
    timeout = {
      max        = 150,
      min        = 20,
      multiplier = 0.95,
      remaining  = 0,
      start      = 120,
    },
  }

  s.button_animations = {}
  s.flash = {
    color = 7,
    on    = 0,
  }
  s.floor = nil
  s.failed_state = {}
  s.score_display = nil
  s.timeout = {}
  s.timer = {
    color     = 8,
    height    = 2,
    max_width = 120,
    start_x   = 4,
    start_y   = 4,
  }
  s.utensil = {
    type     = nil,
    index    = 0,
    sprites  = {},
    previous = {
      index = nil,
      type  = nil,
    }
  }

  s.animate_button = function(button)
    s.button_animations[button].animating = true
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

    destroy_object(s.utensil.sprites)

    s.utensil.type    = utensil_type
    s.utensil.index   = utensil_index
    s.utensil.sprites = init_object({
      tiles    = utensil_array[utensil_index],
      x        = 48,
      y1       = 10,
      y2       = 16,
      duration = 3,
    })
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
    local x1, x2, color = 39, 87, 0
    local dissolve_y1 = s.failed_state.dissolve_y1
    local dissolve_y2 = s.failed_state.dissolve_y2

    rectfill(x1, dissolve_y1, x2, dissolve_y1, color)
    rectfill(x1, dissolve_y2, x2, dissolve_y2, color)
  end

  s.draw_button = function(button)
    local button_animation = s.button_animations[button]
    local button_sprites   = tiles.playing.buttons[button]

    if (button_animation.animating) button_animation.frame += 1

    draw_sprite(button_sprites[button_animation.frame])

    if (button_animation.frame == #button_sprites) then
      button_animation.animating = false
      button_animation.frame     = 1
    end
  end

  s.draw_buttons = function()
    s.draw_button(text.knifey)
    s.draw_button(text.spoony)
  end 

  s.draw_failed_state = function()
    if (s.failed_state.flash) then
      rectfill(0, 0, 127, 127, 8)
      s.failed_state.flash = false
      return
    end

    update_objects = false

    s.dissolve_utensil()
  end

  s.draw_timer = function()
    x = s.timer.start_x + s.timer_width()
    y = s.timer.start_y + s.timer.height - 1

    rectfill(s.timer.start_x, s.timer.start_y, x, y, s.timer.color)
  end

  s.evaluate_input = function(choice)
    if (choice == s.utensil.type) return s.round_passed()
    s.round_failed()
  end

  s.get_input = function()
    if (s.failed_state.animating) return

    if (btnp(0)) then
      s.animate_button(text.knifey)
      s.evaluate_input(text.knifey)
    end

    if (btnp(1)) then
      s.animate_button(text.spoony)
      s.evaluate_input(text.spoony)
    end
  end

  s.new_round = function()
    s.timeout.remaining = s.timeout.start
    s.update_score_display()
    s.choose_utensil()
  end

  s.reset = function()
    s.reset_button_animations()

    s.score_display = nil
    s.failed_state  = copy(s.defaults.failed_state)
    s.timeout       = copy(s.defaults.timeout)

    reset_globals()
  end

  s.reset_button_animations = function()
    s.button_animations = clone(s.defaults.button_animations)
  end

  s.round_failed = function()
    s.reset_button_animations()
    s.failed_state.animating = true
    s.failed_state.flash     = true
  end

  s.round_passed = function()
    update_score()
    s.decrease_timeout_start()
    s.new_round()
  end

  s.timer_width = function()
    local elapsed_percentage = s.timeout.remaining / s.timeout.start
    return flr(elapsed_percentage * s.timer.max_width)
  end

  s.update_failed_state = function()
    s.failed_state.dissolve_y1 += 2
    s.failed_state.dissolve_y2 -= 2
    s.failed_state.timeout     -= 1

    if (s.failed_state.dissolve_y1 > s.defaults.failed_state.dissolve_y2) then
      s.failed_state.dissolve_y1 = s.defaults.failed_state.dissolve_y2
    end

    if (s.failed_state.dissolve_y2 < s.defaults.failed_state.dissolve_y1) then
      s.failed_state.dissolve_y2 = s.defaults.failed_state.dissolve_y1
    end

    if (s.failed_state.timeout == 0) go_to('game_over')
  end

  s.update_score_display = function()
    local score_display_y1 = 87

    if s.score_display ~= nil then
      score_display_y1 = 86
      destroy_object(s.score_display)
    end

    s.score_display = init_object({
      tiles    = tiles.playing.score,
      x        = 48,
      y1       = score_display_y1,
      y2       = 87,
      delay    = 3,
      duration = 2,
    })
  end

  s.init = function()
    s.reset()
    s.new_round()

    s.floor = init_object({
      type  = 'rects',
      rects = rects.floor,
      x     = 4,
      y     = 111,
    })
  end

  s.update = function()
    if (s.failed_state.animating) s.update_failed_state()

    s.decrease_timeout_remaining()
    s.get_input()
  end

  s.draw = function()
    if (s.failed_state.animating) s.draw_failed_state()

    s.draw_buttons()
    s.draw_timer()

    text.output(high_score, 113, 8, 7, 0)
    text.show_center('score', 92, 7)
    text.output_center(score, 99, 7)
  end

  return s
end)

init_screen('game_over', function()
  local s = {}

  s.init = function()
    update_objects = true
  end

  s.update = function()
    if (btnp(4)) go_to('title_transition_in')
    if (btnp(5)) go_to('playing')
  end

  s.draw = function()
    local high_score_text = text['high_score'] .. high_score
    local score_text      = text['score'] .. ': ' .. score

    rectfill(8, 8, 119, 119, 8)

    text.show_center('game_over',       16, 7, 0)
    text.output_center(score_text,      32, 7, 0)
    text.output_center(high_score_text, 40, 7, 0)

    if (high_score_beaten) text.show_center('high_score_beaten', 56, 7, 0)
    text.show_center('play_again', 112, 7, 5)
  end

  return s
end)

-->8
-- game loop

function _init()
  cartdata('knifeyspoony')
  reset_globals()
  go_to('title_transition_in')
end

function _update()
  foreach(objects, function(o)
    o.update()
  end)

  screen.update()
end

function _draw()
  if (update_objects) cls()

  foreach(objects, function(o)
    o.draw()
  end)

  screen.draw()
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
0066555555550000000044ffff42000000000055550000000000000076666666555555550000111111110000fffffff8f0000008000000665500000000000000
006655555555000000004ff44ff2000000000055550000000000000076666666555555550000222222220000ffffff88f0000008000006555550000000000000
006655555555000000004f4444f2000000000055550000000000000076666666555555550000444444220000fffff888f0000008000065555555000000000000
006655555555000000004f4444f2000000000055550000000000000076666666555555550000444444420000ffff8888f0000008000655500555500000000000
006655555555000000004f444442000000000055550000000000000076666666555555550000222222220000fff88888f0000008006555000055550000000000
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
