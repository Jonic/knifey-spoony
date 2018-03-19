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

  outline = function(self, str, x, y, color, outline)
    print(str, x - 1, y, outline)
    print(str, x + 1, y, outline)
    print(str, x, y - 1, outline)
    print(str, x, y + 1, outline)
    print(str, x, y,     color)
  end,

  output = function(self, str, y, color, outline)
    outline = outline or nil
    x       = self:center(str)

    if (outline != nil) then
      return self:outline(str, x, y, color, outline)
    end

    print(str, x, y, color)
  end,

  show = function(self, key, y, color, outline)
    self:output(self:get(key), y, color, outline)
  end
}

-->8
-- game screens

function screen_game_over()
  return {
    _update = function()
      if (btnp(5)) screens:go_to('playing')
    end,

    _draw = function()
      high_score_text = text:get('high_score') .. high_score
      score_text      = text:get('score') .. score

      rectfill(0, 0, 128, 128, 8)

      text:show('game_over',       16, 7, 0)
      text:output(score_text,      32, 7, 0)
      text:output(high_score_text, 40, 7, 0)

      if (high_score_beaten) then
        text:show('high_score_beaten', 56, 7, 0)
      end

      text:show('play_again', 112, 7, 5)
    end
  }
end

function screen_playing()
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
      screens:go_to('game_over')
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
        return screens:go_to('game_over')
      end

      self:get_input()
    end,

    _draw = function(self)
      high_score_text = text:get('high_score') .. high_score
      score_text      = text:get('score') .. score

      rectfill(0, 0, 128, 128, 3)

      text:output(score_text, 16, 7, 0)
      text:output(high_score_text, 24, 7, 5)
      text:output(self.current_utensil, 61, 7, 0)
      text:show('instructions', 112, 7, 5)

      rectfill(0, 0, self:timeout_width() + 1, 5, 0)
      rectfill(0, 0, self:timeout_width(), 4, 9)
    end
  }
end

function screen_title()
  return {
    _update = function()
      if (btnp(5)) screens:go_to('playing')
    end,

    _draw = function()
      high_score_text = text:get('high_score') .. high_score

      rectfill(0, 0, 128, 128, 2)

      text:show('title',           16, 7, 0)
      text:show('about',           24, 7, 5)
      text:show('start_game',      40, 7, 0)
      text:output(high_score_text, 56, 7, 0)
      text:show('how_to_play',     72, 7, 5)
      text:show('instructions',    80, 7, 5)
    end
  }
end

screens = {
  current = {
    name     = nil,
    instance = nil
  },

  definitions = {
    game_over = screen_game_over(),
    playing   = screen_playing(),
    title     = screen_title()
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
  screens:go_to('title')
end

function _update()
  screens:_update()
end

function _draw()
  cls()
  screens:_draw()
end
__gfx__
aaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a9999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a9000000007077077770777707777077770707700000000000000000000000000000000000000000000000000077770777707777077770777707077000000000
a9000000007077070770077007707077000707700000000000000000000000000000000000000000000000000070000707707077070770707707077000000000
a9000000007077070770077007700077700777700000000000000000000000000000000000000000000000000077770777707077070770707707777000000000
a9000000007770070770077007770077000077000000000000000000000000000000000000000000000000000000770700007077070770707700770000000000
a9000000007077070770777707700077770077000000000000000000000000000000000000000000000000000077770700007777077770707700770000000000
a9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a900000000888888888888888888888888888800000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbb00000000000
99000000088888888888888888888888888888800000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000
99000000088888888888888888888888888888800000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000
99000000022222222222222222222222222222200000000000000000000000000000000000000000000000000333333333333333333333333333333000000000
99000000022222222222222222222222222222200000000000000000000000000000000000000000000000000333333333333333333333333333333000000000
a9000000011111111111111111111111111111100000000000000000000000000000000000000000000000000111111111111111111111111111111000000000
99000000007776660000000000000007700000000000000000000007607660000000000000000000076000000000665500000000000066550000000000000000
99000000077777666600000000000077f80000000000000000000766557666600000000000000007665500000006555550000000000655555000000000000000
99000000777777766660000000000778f88000000000000000007665557666660000000000000076655500000065555555000000006555555500000000000000
99000000771777776666000000007788f88800000000000000007665557666666000000000000076655500000655500555500000065550055550000000000000
99000000711177777666600000077888f08880000000000000076655557666666600000000000766555500006555000055550000655500005555000000000000
9900000071d117777666660000778888f00088000000000000076655557666666650000000000766555500006550000555550000655000055555000000000000
990000007ddd11777766660007788888f00008800000000000766555557666666655000000007665555500065500005555555006550000555555500000000000
990000007ddd11177766660007888888f00000800000000000766555557666666655500000007665555500065000055555555006500005555555500000000000
990000007dddd1177766666078888888f00000080000000000766555557666666655550000007665555500065000555555655006500055555565500000000000
990000007dddd111776666608888888ff00000080000000007666555557666666655555000076665555500655000555555665565500055555566550000000000
990000007dddd11177666660888888fff00000080000000007665555557666666655555000076655555500650005555555665565000555555566550000000000
990000007ddddd117776666688888ffff00000080000000007665555557666666655555500076655555500650055555555665565005555555566550000000000
990000007ddddd11777666668888fffff00000080000000007655555557666666655555500076555555500650055555556665565005555555666550000000000
990000007ddddd1117766666888ffffff00000080000000076655555557666666655555550766555555500650555555566665565055555556666550000000000
99aaaaaa7ddddd111776666688fffffff00000080000000076655555557666666655555550766555555500550555555566655555055555556665550000000000
499999997ddddd11177666668ffffffff00000080000000076655555557666666655555550766555555500555555555666655555555555566665550000000000
0000009477dddd1117766666fffffff8f00000080000000066555555557666666655555555665555555500055555556666655005555555666665500000000000
0000009407dddd1117766666ffffff88f00000080000000066555555557666666655555555565555555500055555666666555005555566666655500000000000
0000009407ddd11117766666fffff888f00000080000000066555555557666666655555555055555555500005566666665550000556666666555000000000000
0000009407ddd11117666660ffff8888f00000080000000066555555557666666655555555005555555500000555666655500000055566665550000000000000
0000009407ddd11177666660fff88888f00000080000000066555555557666666655555555075555555500000055555555000000005555555500000000000000
00000094077d111177666600ff888888f00000080000000066555555557666666655555555765555555500000005555550000000000555555000000000000000
999999940071111177666600f8888888f00000080000000065555555557666666655555555655555555500000000555500000000000055550000000000000000
44444444007711177666600088888888f00000080000000065555555557666666655555555655555555500000000055000000000000005500000000000000000
94000000000771776666000088888888f00000080000000065555555557666666655555555655555555500000000055000000000000005500000000000000000
94000000000777766660000088888888f00000080000000065555555557666666655555555655555555500000000055000000000000005500000000000000000
94000000007777666600000088888888f00000080000000065555555557666666655555555655555555500000000055000000000000005500000000000000000
94000000007776666000000088888888f00000080000000065555555557666666655555555655555555500000000055000000000000005500000000000000000
94000000007766660000000088888888f00000080000000065555555557666666655555555655555555500000000055000000000000005500000000000000000
94000000077766660000000088888888f00000080000000065555555557666666655555555655555555500000000055000000000000005500000000000000000
94000000077666600000000088888888f00000080000000065555555557666666655555555655555555500000000055000000000000005500000000000000000
94000000077666600000000088888888f00000080000000055555555557666666655555555555555555500000000055000000000000005500000000000000000
aaaaaaaa077666000000000088888888f00000080000000005555555557666666655555555055555555500000000655500000000000065550000000000000000
99999999777666000000000088888888f00000000000000005555555557666666655555555055555555500000000655500000000000065550000000000000000
00000000777666000000000088888888f00000080000000005555555557666666655555555055555555500000000655500000000000065550000000000000000
00000000777766000000000088888888f00000080000000005555555557666666555555555055555555500000000655500000000000065550000000000000000
00000000777766000000000088888888f00000000000000000555555557666666555555555005555555500000000555500000000000055550000000000000000
00000000777776000000000088888888f00000000000000000555555557666666555555555005555555500000000555500000000000055550000000000000000
00000000777776000000000088888888f00000000000000000555555556666666555555555005555555500000000555500000000000055550000000000000000
00000000777776000000000088888888800000080000000000000000005555555555555555000555555000000000555500000000000055550000000000000000
99999999777776600000000000000000000000000000000000ffffff421111111111100000000055550000000000555500000000000055550000000000000000
99999999777777600000766ddddddddddddddddddd5500000044444442ffff4ff44f444222000055550000000000555500000000000055550000000000000000
000000000777776000076ddd66666666666666650dd5500000444224424444444444442242000055550000000000555500000000000055550000000000000000
0000000007777760000dddd66ddd77777dddddd550dd500000442652424444444444442242000055550000000000555500000000000055550000000000000000
0000000007777766000dddd6ddd6dddddddd5ddd50d5500000442552424444444444444222000055550000000000555500000000000055550000000000000000
00000000077777760000dddd5dddd5555555ddd50555000000444224424444444444442242000055550000000000555500000000000055550000000000000000
00000000007777760000000ddddddddddddddddd5000000000444444424444444444444222000055550000000000555500000000000055550000000000000000
00000000007777760000000005555555555555500000000000444ff4422222222222222242000055550000000000555500000000000055550000000000000000
0000000000777777600000000000111111110000000000000044ffff420000111111110000000655555000000006555550000000001111111100000000000000
000000000077777760000000000022222222000000000000004ff44ff20000222222220000000655555000000006555550000000002222222200000000000000
000000000077777776000000000044444422000000000000004f4444f20000444444220000000655555000000006555550000000004444442200000000000000
000000000007777776000000000044444442000000000000004f4444f20000444444420000000555555000000005555550000000004444444200000000000000
000000000007777777600000000022222222000000000000004f4444420000222222220000000556655000000005566550000000002222222200000000000000
00000000000777777760000000004444444200000000000000444444420000444444420000006565555500000065655555000000004444444200000000000000
aaaaaaaa0000777777660000000044444442000000000000004f4444220000444444420000006565555500000065655555000000004444444200000000000000
99999999000077777776000000004444444200000000000000444222220000444444420000005565555500000055655555000000004444444200000000000000
00000000000077777776000000004444444200000000000000000000000000444444420000005655550500000056555505000000004444444200000000000000
00000000000007777776000000002222222200000000000000666666650000222222220000005655550500000056555505000000002222222200000000000000
00000000000007777776000000004444444200000000000000665555550000444444420000005555500500000055555005000000004444444200000000000000
00000000000007777766000000004444444200000000000000655555550000444444420000000555505000000005555050000000004444444200000000000000
00000000000007777766000000004444442200000000000000555555550000444444220000000555005000000005550050000000004444442200000000000000
00000000000000777760000000002222222100000000000000555555550000222222210000000050050000000000500500000000002222222100000000000000
aa9999a9000000766660000000066666665550000000000000055555500006666666555000000055550000000000555500000000066666665550000000000000
99999999000000066600000000065555555110000000000000005555000006555555511000000005500000000000055000000000065555555110000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000aaaaaaa9aaa9999999999990000000000000000000000000000000000000000000000000000
00000000007077077770777707777077770707700000000000009999999999999999999999999000000000000077770777707777077770777707077000000000
00000000007077077770777707777077770707700000000000009000000000000000000000009000000000000077770777707777077770777707077000000000
00000000007077077770777707777077770707700000000000009000000000000000000000009000000000000077770777707777077770777707077000000000
00000000007077070770077007707077000707700000000000009011111111111111111111109000000000000070000707707077070770707707077000000000
00080000007077070770077007700077700777700000000000009017771777177717771777109000000000000077770777707077070770707707777000000000
00080000007770070770077007770077000077000000000000009017111711171717171711109000000000000000770700007077070770707700770000000000
00080000007077070770777707700077770077000000000000009017771711171717171771109000000000000077770700007777077770707700770000000000
0008000088888888888888888888888888888888000000000000901117171117171771171110900000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000
0008000088888888888888888888888888888888000000000000901777177717771717177710900000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000
0008000088888888888888888888888888888888000000000000901111111111111111111110900000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000
00080000222222222222222222222222222222220000000000009011111111111111111111109000000000003333333333333333333333333333333300000000
00080000111111111111111111111111111111110000000000009011111555155515551111109000000000001111111111111111111111111111111100000000
00000000007077077770777707777077770707700000000000009011111515151515151111109000000000000077770777707777077770777707077000000000
00000000007077070770077007707077000707700000000000009011111515151515151111109000000000000070000707707077070770707707077000000000
00000000007077070770077007700077700777700000000000009011111515151515151111109000000000000077770777707077070770707707777000000000
00000000007770070770077007770077000077000000000000009011111555155515551111109000000000000000770700007077070770707700770000000000
00000000007077070770777707700077770077000000000000009001111111111111111111009000000000000077770700007777077770707700770000000000
00000000000000000000000000000000000000000000000000009000000000000000000000009000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000009aaaaaaaaaaaaaa99aaa99999000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000999999999999999999999990000000000000000000000000000000000000000000000000000
0000000000088888888888888888888888888000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbb00000000000
000000000088888888888888888888888888880000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000
000000000088888888888888888888888888880000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000
00000000002222222222222222222222222222000000000000000000000000000000000000000000000000000033333333333333333333333333330000000000
00000000002222222222222222222222222222000000000000000000000000000000000000000000000000000033333333333333333333333333330000000000
00000000002222222222222222222222222222000000000000000000000000000000000000000000000000000033333333333333333333333333330000000000
00000000001111111111111111111111111111000000000000000000000000000000000000000000000000000011111111111111111111111111110000000000
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
