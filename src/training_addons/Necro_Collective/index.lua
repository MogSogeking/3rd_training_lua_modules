


local necro = {}

function necro.open_menu()
  gui.box(0,0,0,0,0,0)
  menu_stack_clear()
  menu_stack_push(necro.menu)
  menu_stack_draw()
end

necro.menu = make_multitab_menu(
    23, 15, 360, 195, -- same as main menu / screen size 383,223
    {
      {
        name = "Menu 1",
        entries = {
          button_menu_item("Item 1", function() print("hello") end),

        }
      },
      {
        name = "Menu 2",
        entries = {
          button_menu_item("Item 1", function() print("world") end),
        }
      }
    },
    function ()
    end
  )

return necro