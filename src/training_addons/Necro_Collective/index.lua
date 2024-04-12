local _elbow_cannon = require("src/training_addons/Necro_Collective/elbow_cannon")

local necro = {}
local menu = nil
local current_training = 0

local routine = {
  _elbow_cannon
}

local color_button = {
  "LP",
  "MP",
  "HP",
  "LK",
  "MK",
  "HK",
  "LP+MK+HP"
}

local selected_mode = {
  "elbow cannon"
}

necro.constants = {
  timer_cyphers_width = 16,
  timer_cyphers_height = 26
}
necro.config = {}

necro.images = {
  timer_frame = gd.createFromPng("src/training_addons/Necro_Collective/images/timer_frame.png"):gdStr(),
  timer_cyphers = gd.createFromPng("src/training_addons/Necro_Collective/images/timer_cyphers.png"):gdStr(),
}


function necro.open_menu()
  --necro.start_routine()
  menu = menu or set_menu()
  gui.box(0,0,0,0,0,0)
  menu_stack_clear()
  menu_stack_push(menu)
  menu_stack_draw()
end

function necro.set_config(_config)
  necro.config = _config
end

function set_menu()
  return make_multitab_menu(
    23, 15, 360, 195, -- same as main menu / screen size 383,223
    {
      {
        name = "General",
        entries = {
          list_menu_item("Color", necro.config, "color_button", color_button),
          checkbox_menu_item("Routine mode", necro.config, "routine"),
          list_menu_item("Selected mode", necro.config, "selected_mode", selected_mode),
          button_menu_item("Start", necro.start_routine)
        }
      },
      _elbow_cannon.set_menu()
    },
    function ()
    end
  )
end

function character_select(p1, p2)
  start_character_select_sequence()
  select_character(1, p1.character, p1.color - 1, p1.sa)
  select_character(2, p2.character, p2.color - 1, p2.sa)
  emu.speedmode("turbo")
end

function necro.start_routine()
  if necro.config.routine then
    current_training = 1
  else
    current_training = necro.config.selected_mode
  end
  routine[current_training].start()
end

function necro.update()
  if current_training > 0 then
    routine[current_training].update()
    if routine[current_training].has_ended then
      necro.end_training()
    end
  end
  memory.writeword(0x0201543E, 0x10) -- Lock current screen timer
end

function necro.end_training()
  necro.end_routine()
end

function necro.end_routine()
  current_training = 0
  savestate.load(savestate.create("data/"..rom_name.."/savestates/results.fs"))
end

return necro