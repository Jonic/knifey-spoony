pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- knifey spoony
-- by jonic
-- v1.1.0

--[[
  "i see you've played knifey spoony before"

  full code is on github here:
  https://github.com/jonic/knifey-spoony
]]

-->8
-- global setup

score             = 0
high_score        = 0
high_score_beaten = false

-->8
-- helpers

function text_center(str)
  return 64 - #str * 2
end

function table_has_key(table, key)
  return table[key] ~= nil
end

function update_high_score()
  if (score > high_score) then
    high_score        = score
    high_score_beaten = true
    dset(0, high_score)
  end

  global_score = score
end

-->8
-- message strings
text = {
  about             = 'a game by jonic',
  game_over         = 'game over!',
  high_score        = 'high score: ',
  high_score_beaten = '** new high score **',
  how_to_play       = 'how to play:',
  instructions      = 'knifey \139 | \145 spoony',
  knifey            = 'knifey',
  play_again        = 'press x to play again',
  score             = 'score: ',
  spoony            = 'spoony',
  start_game        = 'press x to start',
  title             = 'knifey spoony',

  center = function(self, str)
    return 64 - #str * 2
  end,

  get = function(self, key)
    return self[key]
  end,

  output = function(self, str, y, color)
    x = self:center(str)
    print(str, x, y, color)
  end,

  show = function(self, key, y, color)
    self:output(self:get(key), y, color)
  end
}

-->8
-- game scenes

function scene_game_over()
  return {
    _update = function()
      if (btnp(5)) scenes:go_to('playing')
    end,

    _draw = function()
      high_score_text = text:get('high_score') .. high_score
      score_text      = text:get('score') .. score

      rectfill(0, 0, 128, 128, 8)

      text:show('game_over',       16, 7)
      text:output(score_text,      32, 7)
      text:output(high_score_text, 40, 7)

      if (high_score_beaten) then
        text:show('high_score_beaten', 56, 7)
      end

      text:show('play_again', 112, 7)
    end
  }
end

function scene_playing()
  return {
    current_utensil    = nil,
    round_timeout      = 0,
    timeout            = 0,
    timeout_minimum    = 20,
    timeout_multiplier = 0.95,

    choose_utensil = function(self)
      self.current_utensil = rnd(1) > 0.5 and text.knifey or text.spoony
    end,

    decrease_timeout = function(self)
      local new_timeout = self.timeout * self.timeout_multiplier
      self.timeout = mid(self.timeout_minimum, new_timeout, self.timeout)
    end,

    evaluate_input = function(self, choice)
      if (choice == self.current_utensil) then
        self:round_passed()
      else
        self:round_failed()
      end
    end,

    get_input = function(self)
      if (btnp(0)) self:evaluate_input(text.knifey)
      if (btnp(1)) self:evaluate_input(text.spoony)
    end,

    new_round = function(self)
      self.round_timeout = self.timeout
      self:choose_utensil()
    end,

    round_failed = function()
      update_high_score()
      scenes:go_to('game_over')
    end,

    round_passed = function(self)
      score += 1
      update_high_score()
      self:decrease_timeout()
      self:new_round()
    end,

    timeout_width = function(self)
      return flr((self.round_timeout / self.timeout) * 128)
    end,

    _init = function(self)
      high_score_beaten = false
      score             = 0

      self.timeout = 120
      self:new_round()
    end,

    _update = function(self)
      self.round_timeout -= 1

      if (self.round_timeout < 0) then
        return scenes:go_to('game_over')
      end

      self:get_input()
    end,

    _draw = function(self)
      high_score_text = text:get('high_score') .. high_score
      score_text      = text:get('score') .. score

      rectfill(0, 0, 128, 128, 3)

      text:output(score_text, 16, 7)
      text:output(high_score_text, 24, 7)
      text:output(self.current_utensil, 61, 7)
      text:show('instructions', 112, 7)

      rectfill(0, 0, self:timeout_width(), 4, 9)
    end
  }
end

function scene_title()
  return {
    _update = function()
      if (btnp(5)) scenes:go_to('playing')
    end,

    _draw = function()
      high_score_text = text:get('high_score') .. high_score

      rectfill(0, 0, 128, 128, 2)

      text:show('title',           16, 7)
      text:show('about',           24, 7)
      text:show('start_game',      40, 7)
      text:output(high_score_text, 56, 7)
      text:show('how_to_play',     72, 7)
      text:show('instructions',    80, 7)
    end
  }
end

scenes = {
  current = {
    name     = nil,
    instance = nil
  },

  definitions = {
    game_over = scene_game_over(),
    playing   = scene_playing(),
    title     = scene_title()
  },

  get_instance = function(self)
    self.current.instance = self.definitions[self.current.name]

    if (self.just_updated) then
      self:_init()
      self.just_updated = false
    end
  end,

  go_to = function(self, name)
    self.current.name = name
    self.just_updated = true
    self:get_instance()
  end,

  _init = function(self)
    if (table_has_key(self.current.instance, '_init')) then
      self.current.instance:_init()
    end
  end,

  _update = function(self)
    self.current.instance:_update()
  end,

  _draw = function(self)
    self.current.instance:_draw()
  end
}

-->8
-- game loop

function _init()
  cartdata('knifeyspoony')
  high_score = dget(0)
  scenes:go_to('title')
end

function _update()
  scenes:_update()
end

function _draw()
  cls()
  scenes:_draw()
end
