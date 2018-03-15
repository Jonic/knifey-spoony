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

score      = 0
high_score = 0

-->8
-- helpers

function table_has_key(table, key)
  return table[key] ~= nil
end

-->8
-- game scenes

scenes = {
  current = {
    name     = nil,
    instance = nil
  },
  definitions = {
    title = {
      _update = function(s)
        if (btn(5)) scenes:go_to('game')
      end,

      _draw = function(s)
        print('knifey spoony', 16, 16, 6)
        print('high score: '.. high_score, 16, 32, 6)
        print('press x to start', 16, 48, 6)
        print('x: knife', 16, 64, 6)
        print('c: spoon', 16, 72, 6)
      end
    },

    game = {
      round_timeout      = 0,
      score              = 0,
      timeout            = 0,
      timeout_multiplier = 0,

      timeout_width = function(s)
        return flr((s.round_timeout / s.timeout) * 128)
      end,

      _init = function(s)
        s.round_timeout      = 90
        s.timeout            = 90
        s.timeout_multiplier = 0.98
        score                = 0
      end,

      _update = function(s)
        s.round_timeout = s.round_timeout - 1

        if (s.round_timeout < 0) then
          scenes:go_to('game_over')
        end
      end,

      _draw = function(s)
        print(s.round_timeout, 16, 16, 7)
        rectfill(0, 0, s:timeout_width(), 4, 9)
      end
    },

    game_over = {
      _update = function(s)
        if (btn(4)) scenes:go_to('game')
      end,

      _draw = function(s)
        print('game over - you suck', 16, 16, 7)
        print('your score was ' .. score, 16, 24, 7)
        print('press c', 16, 32, 7)
      end
    }
  },

  get_instance = function(self)
    printh(self.current.name)
    self.current.instance = self.definitions[self.current.name]

    if (self.just_updated and self:instance_can_init()) then
      self.current.instance:_init()
    end
  end,

  go_to = function(self, name)
    self.current.name = name
    self.just_updated = true
    self:get_instance()
  end,

  instance_can_init = function(self)
    table_has_key(self.current.instance, '_init')
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
