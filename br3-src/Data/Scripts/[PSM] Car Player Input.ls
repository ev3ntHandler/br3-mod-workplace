property p
global gGame

on new me, tParams
  p = [:]
  p[#tag] = tParams[#tag]
  p[#ScriptLimit] = 0
  p[#joystick] = tParams[#joystick]
  InitController()
  return me
end

on InitController me
  if p.joystick = 1 then
    if getaProp(gGame, #joystick) = VOID then
      gGame[#joystick] = xtra("joystick").new()
    end if
    p[#joystick] = gGame.joystick
    pNumberOfJoy = p.joystick.numberOfJoy()
    if pNumberOfJoy > 0 then
      p.joystick.useJoy(1)
      gGame.cars[p.tag][#Keys][#leftPerc] = 0.0
      gGame.cars[p.tag][#Keys][#rightPerc] = 0.0
      gGame.cars[p.tag][#Keys][#backwardCam] = 0
    else
      gGame.joystick = VOID
      gGame.deleteProp(#joystick)
      p.joystick = VOID
      p.joystick = 0
      gGame.cars[p.tag][#joystick] = 0
    end if
  end if
end

on enterFrame me
  if gGame.Input = 1 then
    if p.joystick = 0 then
      me.KeyBoardInput()
    else
      me.JoyStickInput()
    end if
  end if
  if gGame.cars[p.tag][#state] = "Done" then
    me.ClearKeys()
  end if
end

on KeyBoardInput me
  gGame.cars[p.tag][#Keys][#forward] = keyPressed(126)
  gGame.cars[p.tag][#Keys][#backward] = keyPressed(125)
  gGame.cars[p.tag][#Keys][#left] = keyPressed(123)
  gGame.cars[p.tag][#Keys][#right] = keyPressed(124)
  gGame.cars[p.tag][#Keys][#brake] = _key.shiftDown
  if (_player.runMode = "Projector") or (_player.runMode = "Author") then
    gGame.cars[p.tag][#specifics][#nitroState] = keyPressed("z")
    if keyPressed(126) = 0 then
      gGame.cars[p.tag][#Keys][#forward] = keyPressed("z")
    end if
  end if
end

on JoyStickInput me
  gGame.cars[p.tag][#Keys][#forward] = p.joystick.button(3)
  gGame.cars[p.tag][#Keys][#backward] = p.joystick.button(2)
  if p.joystick.button(2) = 0 then
    gGame.cars[p.tag][#Keys][#backward] = p.joystick.button(4)
  end if
  pLeft = 0
  if p.joystick.xPos() <= (32768 - 4096) then
    pLeft = 1
  end if
  gGame.cars[p.tag][#Keys][#left] = pLeft
  gGame.cars[p.tag][#Keys][#leftPerc] = (32768.0 - p.joystick.xPos()) / 32768.0
  pRight = 0
  if p.joystick.xPos() >= (32768 + 4096) then
    pRight = 1
  end if
  gGame.cars[p.tag][#Keys][#right] = pRight
  gGame.cars[p.tag][#Keys][#rightPerc] = (p.joystick.xPos() - 32768.0) / 32768.0
  gGame.cars[p.tag][#Keys][#brake] = p.joystick.button(8)
  gGame.cars[p.tag][#Keys][#backwardCam] = p.joystick.button(7)
end

on ClearKeys me
  gGame.cars[p.tag][#Keys][#forward] = 0
  gGame.cars[p.tag][#Keys][#backward] = 0
  gGame.cars[p.tag][#Keys][#left] = random(0, 1)
  gGame.cars[p.tag][#Keys][#right] = random(0, 1)
  gGame.cars[p.tag][#Keys][#brake] = 1
  gGame.cars[p.tag][#Keys][#Nitro] = 0
  gGame.cars[p.tag][#state] = "Finished"
end
