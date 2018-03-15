pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- fireworks
-- by jonic
-- v1.1.0

--[[
  full code is on github here:

  https://github.com/jonic/knifey-spoony
]]

-->8
-- global vars

score             = 0
high_score        = 0
high_score_beaten = false

-->8
-- helpers

function table_has_key(table, key)
  return table[key] ~= nil
end

function update_high_score()
  if (score > high_score) then
    high_score        = score
    high_score_beaten = true
  end
  global_score = score
end

-->8
-- game scenes

function scene_game_over()
  return {
    _update = function()
      if (btnp(5)) scenes:go_to('playing')
    end,

    _draw = function()
      print('game over!', 16, 16, 7)
      print('score:      ' .. score, 16, 32, 7)
      print('high score: ' .. high_score, 16, 40, 7)
      print('press x to play again', 16, 56, 7)
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
      self.current_utensil = rnd(1) > 0.5 and 'knifey' or 'spoony'
    end,

    decrease_timeout = function(self)
      local new_timeout = self.timeout * self.timeout_multiplier
      self.timeout = mid(self.timeout_minimum, new_timeout, self.timeout)
      printh(self.timeout)
    end,

    get_input = function(self)
      if (btnp(0)) then
        if (self.current_utensil == 'knifey') then
          return self:round_passed()
        end

        self:round_failed()
      end

      if (btnp(1)) then
        if (self.current_utensil == 'spoony') then
          return self:round_passed()
        end

        self:round_failed()
      end
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
      self.timeout = 120
      score = 0
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
      print(self.current_utensil, 16, 16, 7)
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
      print('knifey spoony', 16, 16, 6)
      print('-- a game by jonic', 16, 24, 6)
      print('press x to start', 16, 40, 6)
      print('high score: '.. high_score, 16, 56, 6)
      print('how to play:', 16, 72, 6)
      print('knifey \139 | \145 spoony', 16, 80, 6)
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
  scenes:go_to('title')
end

function _update()
  scenes:_update()
end

function _draw()
  cls()
  scenes:_draw()
end
