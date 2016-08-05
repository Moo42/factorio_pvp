
script.on_init(function()
  
  global.players = {}
  
  game.forces.enemy.set_cease_fire(game.forces.player ,true);
  game.forces.player.disable_research();
  game.forces.player.disable_all_prototypes();

end)

script.on_event(defines.events.on_player_created, function(event)
  local player = game.players[event.player_index]
  player.print("Info: PVP server mod v0.1 (c) byte")
  guiNewPlayer(player.gui.left);
  
  player.insert{name="light-armor", count=1}
  player.insert{name="iron-plate", count=8}
  player.insert{name="pistol", count=1}
  player.insert{name="firearm-magazine", count=10}
  player.insert{name="burner-mining-drill", count = 1}
  player.insert{name="stone-furnace", count = 1}
  player.force.chart(player.surface, {{player.position.x - 200, player.position.y - 200}, {player.position.x + 200, player.position.y + 200}})
end)

script.on_event(defines.events.on_player_respawned, function(event)
  local player = game.players[event.player_index]
  
  player.insert{name="light-armor", count=1}
  player.insert{name="pistol", count=1}
  player.insert{name="firearm-magazine", count=10}
end)

script.on_event(defines.events.on_rocket_launched, function(event)
  local force = event.rocket.force
  if event.rocket.get_item_count("satellite") > 0 then
    if global.satellite_sent == nil then
      global.satellite_sent = {}
    end
    if global.satellite_sent[force.name] == nil then
      game.set_game_state{game_finished=true, player_won=true, can_continue=true}
      global.satellite_sent[force.name] = 1
    else
      global.satellite_sent[force.name] = global.satellite_sent[force.name] + 1
    end
    for index, player in pairs(force.players) do
      if player.gui.left.rocket_score == nil then
        local frame = player.gui.left.add{name = "rocket_score", type = "frame", direction = "horizontal", caption={"score"}}
        frame.add{name="rocket_count_label", type = "label", caption={"", {"rockets-sent"}, ":"}}
        frame.add{name="rocket_count", type = "label", caption=tostring(global.satellite_sent[force.name])}
      else
        player.gui.left.rocket_score.rocket_count.caption = tostring(global.satellite_sent[force.name])
      end
    end
  else
    if (#game.players <= 1) then
      game.show_message_dialog{text = {"gui-rocket-silo.rocket-launched-without-satellite"}}
    else
      for index, player in pairs(force.players) do
        player.print({"gui-rocket-silo.rocket-launched-without-satellite"})
      end
    end
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local player = game.players[event.player_index]
  local gui = player.gui.left;

  if player.force == game.forces.player and event.element.name == "new_button" then
    if neForceNear(player.position) then
      local force = game.create_force(player.name);
      force.set_spawn_position(player.position, game.surfaces[1]);
      player.force = force;
      killBitters(player.position);
      player.force.chart(player.surface, {{player.position.x - 200, player.position.y - 200}, {player.position.x + 200, player.position.y + 200}})
      gui.new_force.destroy();
      guiForcePlayer(gui);
      player.print("New Force Created!")
    else
      player.print("This position to close from another force!")
    end
  elseif event.element.name == "inv_button" then
    local name = gui.inv_force.inv_name.text;
    if name ~= nil and validPlayer(name) then
      local iplayer = game.players[name];
      local igui = iplayer.gui.left;
      
      iplayer.force = player.force;
      iplayer.teleport(player.force.get_spawn_position(game.surfaces[1]));
      
      igui.new_force.destroy();
      guiForcePlayer(igui);
      player.print("Player ".. name .. " invated to you force.");
      iplayer.print("You invated by  ".. player.name);
    else
      player.print("Player name invalid of player in another force!")
    end
  elseif event.element.name == "leave_button" then
    if #player.force.players == 1 then 
      game.merge_forces(player.force.name, game.forces.player.name);
      gui.own_force.destroy();
      guiNewPlayer(gui);
      player.print("You force destroyed!");
    elseif #player.force.players > 1 then
      player.force = game.forces.player;
      player.character.die();
      gui.own_force.destroy();
      guiNewPlayer(gui);
      player.print("You leave force!");
    end    
  end
end)

function neForceNear(pos)
  for k, v in pairs(game.forces) do
    if dist(pos, v.get_spawn_position(game.surfaces[1]))  <= 250 then
      return false;
    end
  end
  return true;
end

function killBitters(pos)
   for k, v in pairs(game.surfaces[1].find_entities_filtered({area={{pos.x - 250, pos.y - 250}, {pos.x + 250, pos.y + 250}}, force= "enemy"})) do
       v.destroy();
   end
end

function dist(position1, position2)
  return ((position1.x - position2.x)^2 + (position1.y - position2.y)^2)^0.5
end

function validPlayer(name)
  if name ~= nil and game.players[name] ~= nil and game.players[name].force == game.forces.player then
    return true;
  end
  return false;
end

function guiNewPlayer(gui)
  local frame = gui.add{type="frame", name="new_force", caption="Create Force", direction="vertical"}
  frame.add{type="button", name="new_button", caption="New Force"}
  frame.add{type="label", name="new_label", caption="You can create your own force OR wait for another invitation."}
  frame.add{type="label", name="new_label2", caption="Do not click if you are waiting for an invitation!"}
  frame.add{type="label", name="new_label3", caption="Before creating his team select the location for the base and press the button."}
  frame.add{type="label", name="new_label4", caption="Respawn point will be installed where you stand."}
  frame.add{type="label", name="new_label5", caption="Bitters will run away from you."}
end

function guiForcePlayer(gui)
  local frame = gui.add{type="frame", name="own_force", caption="Force", direction="vertical"}
  frame.add{type="textfield", name="inv_name", caption="Invite Player"}
  frame.add{type="button", name="inv_button", caption="Invite Player"}
  frame.add{type="button", name="leave_button", caption="Leave"}
end