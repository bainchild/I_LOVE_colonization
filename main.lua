---@diagnostic disable: deprecated, need-check-nil
local love = love or require("love")
local flux = require("flux")
---
local data, last_updated
local transition_out, transition_in = false, false
local hovering_location = nil
local hovering_system, hovering_planet = nil, nil
local viewing_system, viewing_planet = nil, nil
local fluxs = {}
local function ping()
   if data == nil or data.ping_locations == nil then
      return
   end
   flux.to(fluxs, 2, { ping_radius = 4, ping_opacity = 0 }):oncomplete(function()
      fluxs.ping_radius = 0
      fluxs.ping_opacity = 1
      ping()
   end)
end
function love.load()
   hovering_system = nil
   fluxs = { scale = 1, opacity = 0.4, ping_radius = 0, ping_opacity = 1 }
   data, last_updated =
      {
         ping_locations = { { 100, 100, 25, 25, false, 35, 50, -25 }, { 25, 25, 55, 55, true } },
         [25] = {
            [25] = {
               has_sol = false,
               [0] = {
                  [0] = {
                     color = { 0.2, 0.2, 1 },
                     radius = 8000,
                     name = "Lua's Orbitee",
                     has_rings = false,
                     ring_type = nil,
                     type = "Lua",
                     materials = {},
                     ---
                     special = true,
                     players = {},
                     beacons = {},
                     structures = {},
                     teleporters = {},
                     has_blackbox = false,
                     has_cc = false,
                     tainted = false,
                  },
               },
               [55] = {
                  [55] = {
                     color = { 0.2, 0.2, 1 },
                     name = "Lua",
                     radius = 7000,
                     has_rings = false,
                     ring_type = nil,
                     type = "Barren",
                     materials = {},
                     ---
                     special = true,
                     players = {},
                     beacons = {},
                     structures = {},
                     teleporters = {},
                     has_blackbox = false,
                     has_cc = true,
                     tainted = false,
                  },
               },
            },
         },
         [100] = {
            [100] = {
               has_sol = true,
               [25] = {
                  [25] = {
                     color = { 0.5, 0.5, 0.1 },
                     name = "Argon Machine 2",
                     radius = 1600,
                     has_rings = false,
                     ring_type = nil,
                     type = "Tundra",
                     materials = {},
                     ---
                     special = false,
                     players = {},
                     beacons = {},
                     structures = {},
                     teleporters = {},
                     has_blackbox = false,
                     has_cc = false,
                     tainted = false,
                  },
               },
            },
         },
      }, nil
   if data.ping_locations then
      ping()
   end
end
local xs, ys = 100, 100
-- local compass_x,compass_y = 90,10
---@diagnostic disable-next-line: unused-local, unused-function
local function printc(t, x, y, ...)
   local font = love.graphics.getFont()
   local width, height = font:getWidth(t), font:getHeight()
   return love.graphics.print(
      t,
      x - (width / 2 / love.graphics.getWidth() * xs),
      y - (height / 2 / love.graphics.getHeight() * ys),
      ...
   )
end
local function clamp(a, b, c)
   if a < b then
      return b
   end
   if a > c then
      return c
   end
   return a
end
local floor = math.floor
local function get_star_of_system(coord)
   if data == nil or coord == nil then
      return nil
   end
   local step1 = data[coord[1]]
   if step1 == nil then
      return nil
   end
   local step2 = step1[coord[2]]
   if step2 == nil then
      return nil
   end
   local step3 = step2[0]
   if step3 == nil then
      return nil
   end
   return step3[0]
end
local function get_planet_from_system(sys, coord)
   if data == nil then
      return nil
   end
   return data[sys[1]][sys[2]][coord[1]][coord[2]]
end
local function set_viewing_universe()
   viewing_planet = nil
   transition_in = false
   transition_out = true
   flux.to(fluxs, 1.2, { opacity = 0.4 })
   fluxs.scale = 3
   fluxs.body_x, fluxs.body_y = xs * 0.5, ys * 0.5
   flux
      .to(
         fluxs,
         1,
         { scale = 1, body_x = (viewing_system[1] + 1) / 200 * xs, body_y = (viewing_system[2] + 1) / 200 * ys }
      )
      :oncomplete(function()
         transition_in = false
         transition_out = false
         viewing_system = nil
         hovering_system = nil
      end)
end
local function set_viewing_system(system)
   if viewing_planet then
      viewing_system = system
      transition_out = true
      flux.to(fluxs, 1.2, { opacity = 0.4 })
      fluxs.body_x = xs * 0.5
      fluxs.body_y = ys * 0.5
      fluxs.scale = 6
      flux
         .to(fluxs, 1, { scale = 1, body_x = viewing_planet[1] / 100 * xs, body_y = (100 - viewing_planet[2]) / 100 * ys })
         :oncomplete(function()
            transition_out = false
            viewing_planet = nil
            hovering_planet = nil
         end)
   elseif viewing_system then
      viewing_system = system
   else
      viewing_system = system
      transition_in = true
      flux.to(fluxs, 1.2, { opacity = 0.2 })
      fluxs.body_x = (viewing_system[1] + 1) / 200 * xs
      fluxs.body_y = (viewing_system[2] + 1) / 200 * ys
      flux.to(fluxs, 1, { scale = 3, body_x = xs * 0.5, body_y = ys * 0.5 }):oncomplete(function()
         transition_in = false
         hovering_system = nil
         fluxs.scale = 1
      end)
   end
end
local function set_viewing_planet(planet)
   if viewing_planet then
      viewing_planet = planet
   elseif viewing_system then
      viewing_planet = planet
      transition_in = true
      flux.to(fluxs, 1.2, { opacity = 0.1 })
      fluxs.scale = 1
      fluxs.body_x = viewing_planet[1] / 100 * xs
      fluxs.body_y = (100 - viewing_planet[2]) / 100 * ys
      flux.to(fluxs, 1, { scale = 6, body_x = xs * 0.5, body_y = ys * 0.5 }):oncomplete(function()
         transition_in = false
         hovering_planet = nil
         fluxs.scale = 1
      end)
   else
      -- viewing_system = planet
      -- transition_in = true
      -- flux.to(fluxs, 1.2, { opacity = 0.2 })
      -- fluxs.body_x = viewing_system[1] / 200 * xs
      -- fluxs.body_y = viewing_system[2] / 200 * ys
      -- flux.to(fluxs, 1, { scale = 3, body_x = xs * 0.5, body_y = ys * 0.5 }):oncomplete(function()
      --    transition_in = false
      --    hovering_system = nil
      -- end)
   end
end
local function draw_body(xp, yp, star, scale, big)
   if scale == nil then
      scale = 1
   end
   if star == nil then
      love.graphics.setColor(0.7, 0.7, 0.7, (big and 0.2) or 0.5)
      love.graphics.setPointSize(scale * (big and 12 or 4))
      love.graphics.points(xp, yp)
      return
   end
   local rad = star.radius / 25000 -- 0-1 (not clamped, though, just general intention)
   love.graphics.setColor(star.color[1], star.color[2], star.color[3], (big and 0.7) or 1)
   local rad5 = rad * 5 * scale -- scaled to grid coordinate size (when viewing solar system)
   love.graphics.circle("fill", xp, yp, rad5)
   if star and star.special then
      if star.type == "Lua" and not big then
         love.graphics.circle("fill", xp + rad5, yp - rad5, (rad + 0.2) * scale)
         -- love.graphics.setColor(1,0,0,1)
         -- TODO: lines
         -- love.graphics.setLineWidth(.4)
         -- local segments = 7
         -- for i=1,segments do
         --    -- center of line we're gonna draw
         --    local cx,cy = math.sin(math.rad(i-.25/segments*360))*off,math.cos(math.rad(i-.25/segments*360))*off
         --    local nx,ny = math.sin(math.rad(i+.25/segments*360))*off,math.cos(math.rad(i+.25/segments*360))*off
         --    love.graphics.line(xp+cx,yp+cy,xp+nx,yp+ny)
         -- end
      end
   end
end
function love.mousepressed(mx, my, button)
   local rx, ry = mx / love.graphics.getWidth() * xs, my / love.graphics.getHeight() * ys
   if viewing_planet then
   elseif viewing_system then
      if hovering_planet ~= nil then
         set_viewing_planet(hovering_planet)
         return
      end
      local sys = data[viewing_system[1]][viewing_system[2]]
      for x = 1, 100 do
         local row = sys[x]
         if row then
            for y = 1, 100 do
               local planet = row[y]
               if planet then
                  local xp, yp = x / 100 * xs, (100 - y) / 100 * ys
                  local rad = planet.radius / 25000 * 10 -- (5*2)
                  if math.sqrt((xp - rx) ^ 2 + (yp - ry) ^ 2) <= rad then
                     set_viewing_planet({ x, y })
                     return
                  end
               end
            end
         end
      end
   else
      if hovering_system ~= nil then
         set_viewing_system(hovering_system)
         return
      end
      if data == nil then
         return
      end
      local sys
      for x = 1, 200 do
         local row = data[x]
         if row then
            for y = 1, 200 do
               local system = row[y]
               if system then
                  local xp, yp = (x + 1) / 200 * xs, (y + 1) / 200 * ys
                  if system[0] and system[0][0] or system.has_sol then
                     local rad = 2
                     if system[0] and system[0][0] then
                        rad = system[0][0].radius / 25000 * 5
                     end
                     if math.sqrt((xp - rx) ^ 2 + (yp - ry) ^ 2) <= rad then
                        sys = { x, y }
                        break
                     end
                  end
               end
            end
            if sys then
               break
            end
         end
      end
      if sys == nil then
         return
      end
      if button == 1 then
         set_viewing_system(sys)
         return
         -- TODO: action menu
      end
   end
end
function love.mousemoved(mx, my)
   if data == nil then
      return
   end
   local rx, ry = mx / love.graphics.getWidth() * xs, my / love.graphics.getHeight() * ys
   if viewing_system then
      hovering_location = { floor(rx), floor(ry) }
   else
      hovering_location = { floor(rx * 2), floor(ry * 2) }
   end
   if viewing_planet then
   elseif viewing_system then
      if hovering_planet ~= nil then
         local xp, yp = hovering_planet[1] / 100 * xs, hovering_planet[2] / 100 * ys
         local rad = get_planet_from_system(viewing_system, hovering_planet).radius / 25000 * 20 -- (5*4)
         if math.sqrt((xp - rx) ^ 2 + (yp - ry) ^ 2) > rad then
            hovering_planet = nil
         end
      end
      local sys = data[viewing_system[1]][viewing_system[2]]
      for x = 1, 100 do
         local row = sys[x]
         if row then
            for y = 1, 100 do
               local planet = row[y]
               if planet then
                  local xp, yp = x / 100 * xs, (100 - y) / 100 * ys
                  local rad = planet.radius / 25000 * 10 -- (5*2)
                  if math.sqrt((xp - rx) ^ 2 + (yp - ry) ^ 2) <= rad then
                     hovering_planet = { x, y }
                     break
                  end
               end
            end
            if hovering_planet then
               break
            end
         end
      end
   else
      if hovering_system ~= nil then
         local xp, yp = (hovering_system[1] + 1) / 200 * xs, (hovering_system[2] + 1) / 200 * ys
         local rad = 2
         if get_star_of_system(hovering_system) then
            rad = get_star_of_system(hovering_system).radius / 25000 * 5
         end
         if math.sqrt((xp - rx) ^ 2 + (yp - ry) ^ 2) > rad then
            hovering_system = nil
         end
      end
      for x = 1, 200 do
         local row = data[x]
         if row then
            for y = 1, 200 do
               local system = row[y]
               if system then
                  local xp, yp = (x + 1) / 200 * xs, (y + 1) / 200 * ys
                  if system[0] and system[0][0] or system.has_sol then
                     local rad = 2
                     if system[0] and system[0][0] then
                        rad = system[0][0].radius / 25000 * 5
                     end
                     if math.sqrt((xp - rx) ^ 2 + (yp - ry) ^ 2) <= rad then
                        hovering_system = { x, y }
                        break
                     end
                  end
               end
            end
            if hovering_system then
               break
            end
         end
      end
   end
end
function love.keypressed(key)
   if transition_in or transition_out then
      return
   end
   if data == nil then
      return love.event.quit()
   end
   if key == "escape" then
      if viewing_planet then -- planet -> system
         set_viewing_system(viewing_system)
      elseif viewing_system then -- system -> universe
         set_viewing_universe()
      else -- universe -> quit
         love.event.quit()
      end
   end
end
function love.update(dt)
   flux.update(dt)
end
function love.draw()
   love.graphics.setColor(1, 1, 1, 1)
   love.graphics.setDefaultFilter("nearest", "nearest")
   local hovering
   if viewing_planet then
      hovering = nil
   elseif viewing_system then
      hovering = (hovering_planet and { hovering_planet[1], 100 - hovering_planet[2] }) or hovering_location
   else
      hovering = hovering_system or hovering_location
   end
   local width, height = love.graphics.getDimensions()
   -- local sqratio = width/height
   love.graphics.scale(width / xs, height / ys)
   if transition_in then
      love.graphics.push()
      love.graphics.translate(-(fluxs.scale - 1) * xs / 2, -(fluxs.scale - 1) * ys / 2)
      love.graphics.scale(fluxs.scale)
      love.graphics.setLineWidth(0.2 / fluxs.scale)
      love.graphics.setColor(1, 1, 1, clamp((1 - (fluxs.opacity - 0.2) / 0.2) * 0.4, 0, 0.4))
      -- outer, bolder lines
      for x = 0.5, 18.5 do
         local xp = (x / 19) * xs
         love.graphics.line(xp, 0, xp, ys)
      end
      for y = 0.5, 18.5 do
         local yp = (y / 19) * ys
         love.graphics.line(0, yp, xs, yp)
      end
      love.graphics.pop()
      love.graphics.setLineWidth(0.1 * fluxs.scale)
      love.graphics.setColor(1, 1, 1, fluxs.opacity)
      -- inner, more transparent lines
      for x = 0.5, 18.5 do
         local xp = (x / 19) * xs
         love.graphics.line(xp, 0, xp, ys)
      end
      for y = 0.5, 18.5 do
         local yp = (y / 19) * ys
         love.graphics.line(0, yp, xs, yp)
      end
      if viewing_planet then
         draw_body(fluxs.body_x, fluxs.body_y, get_planet_from_system(viewing_system, viewing_planet), fluxs.scale)
      elseif viewing_system then
         draw_body(fluxs.body_x, fluxs.body_y, get_star_of_system(viewing_system), fluxs.scale)
      end
      return
   elseif transition_out then
      love.graphics.push()
      love.graphics.translate(-(fluxs.scale - 1) * xs / 2, -(fluxs.scale - 1) * ys / 2)
      love.graphics.scale(fluxs.scale)
      love.graphics.setLineWidth(0.2 / fluxs.scale)
      love.graphics.setColor(1, 1, 1, clamp((1 - (fluxs.opacity - 0.2) / 0.2) * 0.4, 0, 0.4))
      -- outer, bolder lines
      for x = 0.5, 18.5 do
         local xp = (x / 19) * xs
         love.graphics.line(xp, 0, xp, ys)
      end
      for y = 0.5, 18.5 do
         local yp = (y / 19) * ys
         love.graphics.line(0, yp, xs, yp)
      end
      love.graphics.pop()
      love.graphics.setLineWidth(0.1 * fluxs.scale)
      love.graphics.setColor(1, 1, 1, fluxs.opacity)
      -- inner, more transparent lines
      for x = 0.5, 18.5 do
         local xp = (x / 19) * xs
         love.graphics.line(xp, 0, xp, ys)
      end
      for y = 0.5, 18.5 do
         local yp = (y / 19) * ys
         love.graphics.line(0, yp, xs, yp)
      end
      if viewing_planet then
         draw_body(fluxs.body_x, fluxs.body_y, get_planet_from_system(viewing_system, viewing_planet), fluxs.scale)
      elseif viewing_system then
         draw_body(fluxs.body_x, fluxs.body_y, get_star_of_system(viewing_system), fluxs.scale)
      end
      return
   end
   if viewing_planet then
      local planet = get_planet_from_system(viewing_system, viewing_planet)
      printc(
         "("
            .. viewing_system[1]
            .. ","
            .. viewing_system[2]
            .. ("," .. (viewing_planet[1] - 50) .. "," .. (100 - viewing_planet[2] - 50))
            .. ")"
            .. "\n"
            .. planet.name,
         xs / 2,
         ys - (ys / 12),
         0,
         0.2
      )
      love.graphics.setLineWidth(0.1)
      love.graphics.setColor(1, 1, 1, 0.4)
      -- outer, bolder lines
      for x = 0.5, 18.5 do
         local xp = (x / 19) * xs
         love.graphics.line(xp, 0, xp, ys)
      end
      for y = 0.5, 18.5 do
         local yp = (y / 19) * ys
         love.graphics.line(0, yp, xs, yp)
      end
      local xp, yp = 0.5 * xs, 0.5 * ys
      draw_body(xp, yp, planet, 6, true)
      if data.ping_locations then
         for _, pinged in next, data.ping_locations do
            if
               pinged[1] == viewing_system[1]
               and pinged[2] == viewing_system[2]
               and pinged[3] == viewing_planet[1]
               and pinged[4] == viewing_planet[2]
            then
               local px, py
               if pinged[5] then
                  px, py = xs * 0.5, ys * 0.5
                  love.graphics.setColor(1, 0.2, 0.2, fluxs.ping_opacity)
                  love.graphics.circle("line", px, py, fluxs.ping_radius * 6 + 8)
               else
                  love.graphics.setColor(1, 0.2, 0.2, 1)
                  if pinged[6] and pinged[7] then
                     px, py = (pinged[6] + 50) / 100 * xs, (pinged[7] + 50) / 100 * ys
                     love.graphics.setPointSize(5)
                     love.graphics.points(px, py)
                  else
                     px, py = xs * 0.5, ys * 0.5
                     love.graphics.print("?", px, py, 0, 1)
                  end
                  love.graphics.setColor(1, 0.2, 0.2, fluxs.ping_opacity)
                  love.graphics.circle("line", px, py, fluxs.ping_radius)
               end
            end
         end
      end
   elseif viewing_system then
      local center_star = get_star_of_system(viewing_system)
      if hovering then
         printc(
            "("
               .. viewing_system[1]
               .. ","
               .. viewing_system[2]
               .. ((hovering and "," .. (hovering[1] - 50) .. "," .. (100 - hovering[2] - 50)) or "")
               .. ")"
               .. (hovering_planet and "\n" .. get_planet_from_system(viewing_system, hovering_planet).name or ""),
            xs / 2,
            ys - (ys / 12),
            0,
            0.2
         )
      end
      love.graphics.setLineWidth(0.1)
      love.graphics.setColor(1, 1, 1, 0.4)
      -- outer, bolder lines
      for x = 0.5, 18.5 do
         local xp = (x / 19) * xs
         love.graphics.line(xp, 0, xp, ys)
      end
      for y = 0.5, 18.5 do
         local yp = (y / 19) * ys
         love.graphics.line(0, yp, xs, yp)
      end
      local xp, yp = 0.5 * xs, 0.5 * ys
      draw_body(xp, yp, center_star, 3, true)
      local system = data[viewing_system[1]][viewing_system[2]]
      for x = 1, 100 do
         if system[x] then
            for y = 1, 100 do
               local planet = system[x][y]
               if planet then
                  draw_body(x - 50 / 100 * xs + xp, (100 - y) - 50 / 100 * ys + yp, planet)
               end
            end
         end
      end
      if data.ping_locations then
         for _, pinged in next, data.ping_locations do
            if pinged[1] == viewing_system[1] and pinged[2] == viewing_system[2] then
               local px, py = pinged[3] / 100 * xs, (100 - pinged[4]) / 100 * ys
               love.graphics.setPointSize(5)
               love.graphics.setColor(1, 0.2, 0.2, 1)
               love.graphics.points(px, py)
               love.graphics.setColor(1, 0.2, 0.2, fluxs.ping_opacity)
               love.graphics.circle("line", px, py, fluxs.ping_radius)
            end
         end
      end
   else
      love.graphics.push()
      love.graphics.reset()
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.print(
         "Last updated: "
            .. (last_updated and os.date("%x %I:%M:%S", last_updated) or "N/a")
            .. (data == nil and "\nNo data!" or ""),
         1,
         1
      )
      love.graphics.pop()
      if hovering then
         printc(
            "("
               .. hovering[1]
               .. ","
               .. hovering[2]
               .. (get_star_of_system(hovering_system) and ",0,0" or "")
               .. ")"
               .. (
                  hovering_system
                     and get_star_of_system(hovering_system)
                     and "\n" .. get_star_of_system(hovering_system).name
                  or ""
               ),
            xs / 2,
            ys - (ys / 12),
            0,
            0.2
         )
      end
      love.graphics.setLineWidth(0.1)
      love.graphics.setColor(1, 1, 1, 0.4)
      for x = 0.5, 18.5 do
         local xp = (x / 19) * xs
         love.graphics.line(xp, 0, xp, ys)
      end
      for y = 0.5, 18.5 do
         local yp = (y / 19) * ys
         love.graphics.line(0, yp, xs, yp)
      end
      for x = 1, 200 do
         local row = data[x]
         if row then
            for y = 1, 200 do
               local system = row[y]
               if system then
                  if system[0] and system[0][0] or system.has_sol then
                     local xp, yp = (x + 1) / 200 * xs, (y + 1) / 200 * ys
                     local star = system[0] and system[0][0] or nil
                     draw_body(xp, yp, star, (not star and 4 or 1))
                  end
               end
            end
         end
      end
      if data.ping_locations then
         for _, pinged in next, data.ping_locations do
            local px, py = (pinged[1] + 1) / 200 * xs, (pinged[2] + 1) / 200 * ys
            love.graphics.setPointSize(5)
            love.graphics.setColor(1, 0.2, 0.2, 1)
            love.graphics.points(px, py)
            love.graphics.setColor(1, 0.2, 0.2, fluxs.ping_opacity)
            love.graphics.circle("line", px, py, fluxs.ping_radius)
         end
      end
      -- love.graphics.setColor(1, 1, 1, 1)
      -- printc("W", compass_x - (xs / 40), compass_y, 0, 0.15)
      -- printc("E", compass_x + (xs / 40), compass_y, 0, 0.15)
      -- printc("S", compass_x, compass_y + (ys / 40), 0, 0.15)
      -- love.graphics.setColor(1, 0.5, 0.5, 1)
      -- printc("N", compass_x, compass_y - (ys / 40), 0, 0.15)
   end
end
