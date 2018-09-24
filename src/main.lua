function love.load()
end

local patches = {
  {x = 32, y = 240 - 32, name = "Texture 1", lports = {}, rports = {{}}},
  {x = 640 - 96 - 32, y = 240 - 32, name = "output", lports = {{}}, rports = {}}
}

function linktwohits(lhit, rhit)
  local lpatch, lport = lhit[2], lhit[4]
  local rpatch, rport = rhit[2], rhit[4]
  if lpatch == rpatch then return end -- don't connect ourselves!
  lpatch.lports[lport] = rpatch
  rpatch.rports[rport] = lpatch
end

local lastport
function love.mousepressed(x, y, button, istouch)
  if button == 2 then
    patches[#patches + 1] = {
      x = x,
      y = y,
      name = tostring(#patches + 1),
      lports = {{},{}},
      rports = {{}}
    }
  end
  if button == 1 then
    hits = hittest(love.mouse.getPosition())
    if hits then
      print('--')
      for _,v in ipairs(hits) do
        print(v)
      end
    end
    if not lastport then
      lastport = {x = love.mouse.getX(), y = love.mouse.getY()}
    else
      local hit1 = hittest(love.mouse.getPosition())
      local hit2 = hittest(lastport.x, lastport.y)
      local rhit = (hit1[3] == 'r' and hit1) or (hit2[3] == 'r' and hit2) or false
      local lhit = (hit1[3] == 'l' and hit1) or (hit2[3] == 'l' and hit2) or false
      if lhit and rhit then
        linktwohits(lhit, rhit)
      end

      lastport = false
    end
  end
end

local patchheight = 60
local patchwidth = 1.6 * 60
local portheight = 16
local porty
local height2

do
  height2 = patchheight/2 -- split evenly in 2
  middley = height2/2 -- find middle of new split
  portmiddle = portheight/2
  porty = middley - portmiddle
end

function patch_getsize(patch)
  local height = height2 * math.max(#patch.lports, #patch.rports)
  return patchwidth, height
end

function patch_getaabb(patch)
  local w, h = patch_getsize(patch)
  return patch.x, patch.y, w + patch.x, h + patch.y
end

function aabbtest(x, y, x_, y_, x_2, y_2)
  return x_ < x and x < x_2 and y_ < y and y < y_2
end

function findpatch(x, y)
  for _,v in ipairs(patches) do
    if aabbtest(x, y, patch_getaabb(v)) then
      return v
    end
  end
  return nil
end

function patch_getportposright(patch, num)
  local x, y = patch_getportpos(patch, num)
  x = x + patchwidth - portheight
  return x, y
end

function patch_getportpos(patch, num)
  local x = patch.x
  local num0 = num - 1
  local y = patch.y + num0 * height2 + porty
  return x, y
end

function patch_getportaabbright(patch, num)
  local x_, y_ = patch_getportposright(patch, num)
  return x_, y_, x_ + portheight, y_ + portheight
end

function patch_getportaabb(patch, num)
  local x_, y_ = patch_getportpos(patch, num)
  return x_, y_, x_ + portheight, y_ + portheight
end

function patch_findport(patch, x, y)
  for i=1, #patch.rports do
    if aabbtest(x, y, patch_getportaabbright(patch, i)) then
      return 'r', i
    end
  end
  for i=1, #patch.lports do
    if aabbtest(x, y, patch_getportaabb(patch, i)) then
      return 'l', i
    end
  end
  return nil, nil
end

function hittest(x, y)
  local patch = findpatch(x, y)
  if patch then
    local t, i = patch_findport(patch, x, y)
    if t then
      return {'patch', patch, t, i}
    else
      return {'patch', patch}
    end
  end
  return {}
end

function drawpipe(x, y, x_, y_)
  love.graphics.setColor(1,1,1)
  curve = love.math.newBezierCurve({
    x, y,
    x_, y,
    x, y_,
    x_, y_
  })
  love.graphics.line(curve:render())
end

function getportcenterpos(portx, porty)
  return portx + portheight/2, porty + portheight/2
end

function love.draw()
  for i,v in ipairs(patches) do
    love.graphics.setColor(16/256, 60/256, 173/256)
    love.graphics.rectangle("fill", v.x, v.y, patch_getsize(v))

    love.graphics.setColor(9/256, 47/256, 93/256)
    local x, y
    for i=1, #v.lports do
      x, y = patch_getportpos(v, i)
      love.graphics.rectangle("fill", x, y, portheight, portheight)
    end
    for i=1, #v.rports do
      x, y = patch_getportposright(v, i)
      love.graphics.rectangle("fill", x, y, portheight, portheight)
    end

    love.graphics.setColor(1,1,1)
    love.graphics.print(v.name, v.x, v.y)
  end

  for _,v in ipairs(patches) do
    for i=1, #v.lports do
      local otherpatch = v.lports[i]
      -- if the port we're looking at is an empty table, leave
      if not otherpatch or next(otherpatch) == nil then goto continue end

      -- get the position of our port
      local x, y = getportcenterpos(patch_getportpos(v, i))
      -- find the port on the other patch that refers to our patch
      for j,w in ipairs(otherpatch.rports) do
        if w == v then -- if we have found ourselves
          -- then draw the pipe
          drawpipe(x, y, getportcenterpos(patch_getportposright(otherpatch, j)))
        end -- we're assuming there's only one ever connected in this way
        -- like i hope theres no more than that but if it happens i guess its good to see
      end
      ::continue::
    end
    -- note: no need for rports, pipes always connect only lports and rports
  end
  if lastport then
    drawpipe(lastport.x, lastport.y, love.mouse.getX(), love.mouse.getY())
  end
end

function love.update(dt)

end
