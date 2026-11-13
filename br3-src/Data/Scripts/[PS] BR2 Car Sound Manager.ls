property p
global g

on new me, tParams
  p = [:]
  p[#member] = member(tParams[#memberName])
  p[#controller] = tParams[#controller]
  p[#tag] = tParams[#tag]
  p[#CarName] = "Car"
  p[#collModelName] = tParams[#collModelName]
  tParams = VOID
  p[#EngineStarted] = 0
  p[#SoundsCleared] = 0
  p[#Stationair] = 0
  p[#rollOut] = 0
  p[#Forwards] = 0
  p[#Backwards] = 0
  p[#CrashedSound] = 0
  p[#topSpeed] = 0
  p[#MyNitro] = 0
  p[#rateShift] = 0
  p[#timer] = 0
  p[#BasicChannel] = [VOID, VOID]
  p[#MotorChannel] = [VOID, VOID]
  p[#BrakeChannel] = [VOID, VOID]
  p[#SlipChannel] = [VOID, VOID]
  p[#ScrapeChannel] = [VOID, VOID]
  p[#me] = me
  p[#ScriptLimit] = 0
  return me
end

on enterFrame me
  me.GetData()
  pCollisionDetails = g.cars[p.tag][#specifics][#collisionDetails]
  if (p.Crashed = 4) and (p.SoundsCleared = 0) then
    me.reset()
    exit
  end if
  if (p.Crashed = 4) and (p.SoundsCleared = 1) then
    exit
  end if
  if (p.Started = 1) and (p.EngineStarted = 0) then
    p.BasicChannel[1] = PlaySound(p.CarName & "Stationair", [#priority: #high, #loopCount: 0, #rateShift: p.rateShift, #Override: 1])
    p.BasicChannel[2] = p.CarName & "Stationair"
    p.rateShift = 0
    p.EngineStarted = 1
    p.Stationair = 1
  end if
  if pCollisionDetails <> [] then
    if p.ScrapeChannel[1] = VOID then
      p.ScrapeChannel[1] = PlaySound(p.CarName & "Scrape", [#priority: #medium, #loopCount: 0])
      p.ScrapeChannel[2] = p.CarName & "Scrape"
    else
      if p.falling = 1 then
        if p.ScrapeChannel[1] <> VOID then
          p.ScrapeChannel[1].setVolume(0.0)
        end if
      else
        if p.ScrapeChannel[1] <> VOID then
          p.ScrapeChannel[1].setVolume(p.Percentage)
        end if
      end if
    end if
  else
    if p.ScrapeChannel[1] <> VOID then
      if p.ScrapeChannel[1] <> VOID then
        p.ScrapeChannel[1] = p.ScrapeChannel[1].StopSound()
      end if
      p.ScrapeChannel[2] = VOID
    end if
  end if
  if (p.slip = 1) and (p.brake = 1) then
    if p.SlipChannel[1] = VOID then
      p.SlipChannel[1] = PlaySound(p.CarName & "Skid", [#priority: #medium, #loopCount: 0])
      p.SlipChannel[2] = p.CarName & "Skid"
    else
      if p.falling = 1 then
        if p.SlipChannel[1] <> VOID then
          p.SlipChannel[1].setVolume(0.0)
        end if
      else
        if p.SlipChannel[1] <> VOID then
          p.SlipChannel[1].setVolume(p.Percentage)
        end if
      end if
    end if
  else
    if p.SlipChannel[1] <> VOID then
      if p.SlipChannel[1] <> VOID then
        p.SlipChannel[1] = p.SlipChannel[1].StopSound()
      end if
      p.SlipChannel[2] = VOID
    end if
  end if
  if (p.MotorChannel[1] <> VOID) and (p.MotorChannel[2] = (p.CarName & "TopSpeed")) then
    pMaxSpeed = p.maxSpeed
    pMaxSpeed = pMaxSpeed / 3.0
    pPercentage = abs(p.Speed) / pMaxSpeed
    if p.MotorChannel[1] <> VOID then
      p.MotorChannel[1].setVolume(pPercentage)
    end if
  end if
  if p.BasicChannel[1] <> VOID then
    pMaxSpeed = p.maxSpeed
    if p.Speed < 0 then
      pMaxSpeed = pMaxSpeed / 2.0
    end if
    pPercentage = abs(p.Speed) / pMaxSpeed
    if p.BasicChannel[2] = (p.CarName & "Stationair") then
      pVolume = 1.0 - pPercentage
    end if
    if p.BasicChannel[2] = "NitroStart" then
      pVolume = pPercentage
    end if
    if p.BasicChannel[1] <> VOID then
      p.BasicChannel[1].setVolume(pVolume)
    end if
  end if
  if (p.nitroState = 1) and (p.MyNitro = 0) then
    if p.MotorChannel[1] <> VOID then
      p.MotorChannel[1] = p.MotorChannel[1].StopSound()
    end if
    p.MotorChannel[1] = PlaySound(p.CarName & "TopSpeed", [#priority: #high, #loopCount: 0, #rateShift: 3, #Override: 1])
    p.MotorChannel[2] = p.CarName & "TopSpeed"
    if p.BasicChannel[1] <> VOID then
      p.BasicChannel[1] = p.BasicChannel[1].StopSound()
    end if
    p.BasicChannel[1] = PlaySound("NitroStart", [#priority: #high, #loopCount: 0, #loopStartTime: 3021, #rateShift: p.rateShift, #Override: 1])
    p.BasicChannel[2] = "NitroStart"
    p.MyNitro = 1
  else
    if (p.nitroState = 0) and (p.MyNitro = 1) then
      if p.MotorChannel[1] <> VOID then
        p.MotorChannel[1] = p.MotorChannel[1].StopSound()
      end if
      p.MotorChannel[1] = PlaySound(p.CarName & "TopSpeed", [#priority: #high, #loopCount: 0, #rateShift: p.rateShift, #Override: 1])
      p.MotorChannel[2] = p.CarName & "TopSpeed"
      if p.BasicChannel[1] <> VOID then
        p.BasicChannel[1] = p.BasicChannel[1].StopSound()
      end if
      p.BasicChannel[1] = PlaySound(p.CarName & "Stationair", [#priority: #high, #loopCount: 0, #rateShift: p.rateShift, #Override: 1])
      p.BasicChannel[2] = p.CarName & "Stationair"
      p.MyNitro = 0
    end if
  end if
  if p.forward = 1 then
    DriveForward()
  end if
  if (p.forward = 0) and (p.backward = 1) then
    DriveBackward()
  end if
  if (p.forward = 0) and (p.backward = 0) then
    p.rollOut = 1
  end if
end

on GetData me
  p[#forward] = g.cars[p.tag][#Keys][#forward]
  p[#backward] = g.cars[p.tag][#Keys][#backward]
  p[#brake] = g.cars[p.tag][#Keys][#brake]
  p[#slip] = g.cars[p.tag][#specifics][#slip]
  p[#Started] = g.cars[p.tag][#specifics][#Started]
  p[#falling] = g.cars[p.tag][#specifics][#falling]
  p[#maxSpeed] = g.cars[p.tag][#specifics][#maxSpeed]
  p[#Speed] = g.cars[p.tag][#specifics][#speedMS]
  p[#Crashed] = g.cars[p.tag][#specifics][#CrashState]
  p[#nitroState] = g.cars[p.tag][#specifics][#nitroState]
  p[#Percentage] = abs(p.Speed) / p.maxSpeed
end

on StartCar me
  if p.Stationair = 1 then
    if p.MotorChannel[1] <> VOID then
      p.MotorChannel[1] = p.MotorChannel[1].StopSound()
    end if
    p.MotorChannel[1] = PlaySound(p.CarName & "TopSpeed", [#priority: #high, #loopCount: 0, #rateShift: p.rateShift, #Override: 1])
    p.MotorChannel[2] = p.CarName & "TopSpeed"
    p[#timer] = _system.milliSeconds
    p.Stationair = 0
  end if
end

on DriveForward me
  if p.Stationair = 1 then
    StartCar()
  end if
  if p.Speed < 0.0 then
    if (p.BrakeChannel[2] = VOID) and (p.falling = 0) then
      PlaySound(p.CarName & "Brake", [#priority: #medium])
      p.BrakeChannel[2] = "Brake"
    end if
  end if
  if p.Speed > 0 then
    p.BrakeChannel[2] = VOID
  end if
  if (p.rollOut = 1) or (p.Backwards = 1) then
    PlaySound(p.CarName & "GearShift", [#priority: #medium])
    p.rollOut = 0
    p.Backwards = 0
    p.Forwards = 1
  end if
end

on DriveBackward me
  if p.Stationair = 1 then
    StartCar()
  end if
  if p.Speed > 0 then
    if (p.BrakeChannel[2] = VOID) and (p.falling = 0) then
      PlaySound(p.CarName & "Brake", [#priority: #medium])
      p.BrakeChannel[2] = "Brake"
    end if
  end if
  if p.Speed < 0 then
    p.BrakeChannel[2] = VOID
  end if
  if (p.rollOut = 1) or (p.Forwards = 1) then
    PlaySound(p.CarName & "GearShift", [#priority: #medium])
    p.rollOut = 0
    p.Forwards = 0
    p.Backwards = 1
  end if
end

on reset me
  p.timer = 0
  p.EngineStarted = 0
  p.Stationair = 0
  p.rollOut = 0
  p.Forwards = 0
  p.Backwards = 0
  p.CrashedSound = 0
  p.topSpeed = 0
  p.rateShift = 0
  p.timer = 0
  if p.BasicChannel[1] <> VOID then
    p.BasicChannel[1] = p.BasicChannel[1].StopSound()
  end if
  if p.MotorChannel[1] <> VOID then
    p.MotorChannel[1] = p.MotorChannel[1].StopSound()
  end if
  if p.BrakeChannel[1] <> VOID then
    p.BrakeChannel[1] = p.BrakeChannel[1].StopSound()
  end if
  if p.SlipChannel[1] <> VOID then
    p.SlipChannel[1] = p.SlipChannel[1].StopSound()
  end if
  if p.ScrapeChannel[1] <> VOID then
    p.ScrapeChannel[1] = p.ScrapeChannel[1].StopSound()
  end if
  p.SoundsCleared = 1
  p.BasicChannel = [VOID, VOID]
  p.MotorChannel = [VOID, VOID]
  p.BrakeChannel = [VOID, VOID]
  p.SlipChannel = [VOID, VOID]
  p.ScrapeChannel = [VOID, VOID]
  if _movie.timeoutList.getPos(timeout("DrivingStationair")) <> 0 then
    timeout("DrivingStationair").forget()
  end if
  if _movie.timeoutList.getPos(timeout("TopSpeed")) <> 0 then
    timeout("TopSpeed").forget()
  end if
end
