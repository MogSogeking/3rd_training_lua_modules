local _hit_confirm = require("src/training_addons/Hit_Confirm/hit_confirm")
local _punish = require("src/training_addons/Punish/punish")

local generic = {}
local menu = nil
local current_training = 0
local is_routine = false

local routine = {
  _hit_confirm,
  _punish,
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
  "hit confirm",
  "punish",
}

local _routine_menu = make_menu(100, 79, 283, 160, -- screen size 383,223,
  {
    button_menu_item("Skip", function()
      generic.end_training()
    end),
    button_menu_item("Quit", function()
      generic.end_routine()
    end),
  }
)

generic.constants = {
  whole_cast = {
    "Alex",
    "ChunLi",
    "Dudley",
    "Elena",
    "Gill",
    "Gouki",
    "Hugo",
    "Ibuki",
    "Ken",
    "Makoto",
    "generic",
    "Oro",
    "Q",
    "Remy",
    "Ryu",
    "Sean",
    "Twelve",
    "Urien",
    "Yang",
    "Yun",
  },
  training_data_to_keep = {
    display_frame_advantage = true,
    music_volume = true,
    display_p1_input_history = true,
    display_distances = true,
    display_p1_input_history_dyanamic = true,
    display_input = true,
    display_gauges = true,
    display_attack_data = true,
    display_p2_input_history = true,
    display_hitboxes = true,
  }
}
generic.config = {}

generic.images = {

}


function generic.open_menu()
  menu = menu or set_menu()
  gui.box(0,0,0,0,0,0)
  menu_stack_clear()
  menu_stack_push(menu)
  menu_stack_draw()
end

function generic.set_config(_config)
  generic.config = _config
end

function set_menu()
  return make_multitab_menu(
    23, 15, 360, 195, -- same as main menu / screen size 383,223
    {
      {
        name = "General",
        entries = {
          list_menu_item("Color", generic.config, "color_button", color_button),
          list_menu_item("Favorite opponent", generic.config, "favorite_opponent", generic.constants.whole_cast),
          checkbox_menu_item("Routine mode", generic.config, "routine"),
          list_menu_item("Selected mode", generic.config, "selected_mode", selected_mode),
          button_menu_item("Start", generic.start_routine)
        }
      },
      _hit_confirm.set_menu(),
      _punish.set_menu(),
    },
    function (_menu)
      if _menu.content[_menu.main_menu_selected_index].name == "Hit confirm" then
        _hit_confirm.update_menu(_menu)
      elseif _menu.content[_menu.main_menu_selected_index].name == "Punish" then
        _punish.update_menu(_menu)
      end
    end
  )
end

function character_select(p1, p2)
  start_character_select_sequence()
  select_character(1, p1.character, p1.color - 1, p1.sa - 1)
  select_character(2, p2.character, p2.color - 1, p2.sa - 1)
  emu.speedmode("turbo")
end

function generic.start_routine()
  reset_training_data(generic.constants.training_data_to_keep)
  if generic.config.routine then
    current_training = 1
    is_routine = true
    current_menu = _routine_menu
  else
    current_training = generic.config.selected_mode
    is_routine = false
    current_menu = routine[current_training].training_menu
  end
  while is_routine and current_training <= #routine and not routine[current_training].is_enabled do
    current_training = current_training + 1
  end

  if current_training > #routine then
    print("No training enabled in routine. Enable at least one training.")
  else
    routine[current_training].start()
  end
end

function generic.start()
  reset_training_data(generic.constants.training_data_to_keep)
  current_training = menu.main_menu_selected_index - 1
  is_routine = false
  current_menu = routine[current_training].training_menu
  routine[current_training].start()
end

function generic.update()
  if current_training > 0 and current_training <= #routine then
    routine[current_training].update()
    if routine[current_training].has_ended then
      generic.end_training()
    end
  end
  memory.writeword(0x0201543E, 0x10) -- Lock current screen timer
end

function generic.end_training()
  if not is_routine then
    generic.end_routine()
  else
    repeat
      current_training = current_training + 1
    until current_training > #routine or routine[current_training].is_enabled

    if current_training > #routine then
      generic.end_routine()
    else
      routine[current_training].start()
    end
  end
end

function generic.end_routine()
  current_training = 0
  savestate.load(savestate.create("data/"..rom_name.."/savestates/results.fs"))
end

function generic.quit_training()
  current_training = 0
  current_menu = main_menu
  _current_module = nil
  is_menu_open = false
  menu_stack_clear()
  load_training_data()
end

return generic