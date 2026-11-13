property p
global gGame

on new me, tParams
  p = [:]
  p[#member] = tParams[#member]
  p[#tag] = tParams[#tag]
  p[#model] = tParams[#RayCastModel]
  p[#parent] = tParams[#parent]
  p[#ScriptLimit] = 0
  PrepareAI()
  p[#me] = me
  return p.me
end

on PrepareAI me
  CLONEMODELS(p.member, [#cloneMember: "LeaderHelper", #modelList: ["LeaderHelper"], #NameList: [p.tag & "LeaderHelper"]])
  p[#LeaderHelper] = p.member.model(p.tag & "LeaderHelper")
  p.LeaderHelper.shader.blend = 0
  p.LeaderHelper.pointAtOrientation = [vector(0.0, 1.0, 0.0), vector(0.0, 0.0, 1.0)]
  p[#TargetList] = []
  p[#TargetEntries] = 8
  p[#DefaultEntries] = 8
  p[#DifferenceList] = []
  p[#StartEntry] = 3
  p[#minDistance] = 5.0
  p[#LocalDown] = vector(0.0, 0.0, -1.0)
  p[#LocalForward] = vector(0.0, 1.0, 0.0)
  p[#LocalRight] = vector(1.0, 0.0, 0.0)
  p[#state] = "Drive"
  p[#subState] = EMPTY
  p[#PreviousLeft] = 0
  p[#PreviousRight] = 0
  p[#stuckCounter] = 0
  p[#StuckAngle] = 0
  p[#ForwardCounter] = 0
  p[#OldRootNr] = 0
  p[#Sphere1] = VOID
  p[#Sphere2] = VOID
  if getaProp(gGame, #AIHelpers) <> VOID then
    if gGame.AIHelpers = 1 then
      theModelResource = p.member.newModelResource(p.tag & "sphere_1", #sphere)
      theModelResource.radius = 0.5
      p[#Sphere1] = p.member.newModel(p.tag & "TestSphere1", theModelResource)
      p.Sphere1.shader = p.LeaderHelper.shader
      p[#Sphere2] = p.member.newModel(p.tag & "TestSphere2", theModelResource)
      p.Sphere2.shader = p.LeaderHelper.shader
      p.LeaderHelper.shader.blend = 65
    end if
  end if
end

on enterFrame me
  if gGame.Input = 0 then
    exit
  end if
  if gGame.cars[p.tag][#state] = "Finished" then
    exit
  end if
  if gGame.cars[p.tag][#specifics][#Health] = 0 then
    exit
  end if
  CreateAIData()
  case p.state of
    "Drive":
      Drive()
    "Unstuck":
      Unstuck()
    "Reset":
      reset()
    EMPTY:
      nothing()
  end case
  if gGame.cars[p.tag][#state] = "Done" then
    gGame.cars[p.tag][#Keys][#forward] = 0
    gGame.cars[p.tag][#Keys][#backward] = 0
    gGame.cars[p.tag][#Keys][#left] = random(0, 1)
    gGame.cars[p.tag][#Keys][#right] = random(0, 1)
    gGame.cars[p.tag][#Keys][#Nitro] = 0
    gGame.cars[p.tag][#Keys][#brake] = 1
    gGame.cars[p.tag][#state] = "Finished"
  end if
end

on CreateAIData me
  p[#CarPos] = p.model.worldPosition
  p[#CurrentSpeed] = gGame.cars[p.tag][#specifics][#speedMS]
  p.LeaderHelper.worldPosition = p.model.worldPosition + vector(0.0, 0.0, 1.5)
  pCurrentRoot = gGame.cars[p.tag][#specifics][#currentRootNr]
  if pCurrentRoot = VOID then
    pCurrentRoot = p.OldRootNr
  end if
  if pCurrentRoot = 0 then
    pCurrentRoot = 1
  end if
  if p.OldRootNr <> pCurrentRoot then
    pFutureRoot = gGame.cars[p.tag][#specifics][#currentRootNr] + 1
    if pFutureRoot > gGame.RootList.count then
      pFutureRoot = pCurrentRoot
    end if
    p[#MyWayPointList] = gGame.WayPointList[symbol("TrackRoot" & pCurrentRoot & "_Group")].duplicate()
    if pFutureRoot <> pCurrentRoot then
      pExtraList = gGame.WayPointList[symbol("TrackRoot" & pFutureRoot & "_Group")].duplicate()
      pCount = pExtraList.count
      repeat with i = 1 to pCount
        p.MyWayPointList.add(pExtraList[i])
      end repeat
    end if
    gGame.cars[p.tag][#specifics][#WayPointList] = p.MyWayPointList.duplicate()
    p.OldRootNr = pCurrentRoot
  end if
  pCount = p.MyWayPointList.count
  pNearestWaypoint = 1
  pNearestWaypointPos = vector(0.0, 0.0, 0.0)
  pNearestDistance = 15.0
  repeat with i = 1 to pCount
    pWaypointPos = p.MyWayPointList[i][1]
    pTempDistance = pWaypointPos.distanceTo(p.CarPos)
    if pTempDistance <= pNearestDistance then
      pNearestWaypoint = i + 1
      if pNearestWaypoint > p.MyWayPointList.count then
        pNearestWaypoint = p.MyWayPointList.count
      end if
      pNearestWaypointPos = p.MyWayPointList[pNearestWaypoint][1]
      gGame.cars[p.tag][#specifics][#currentWaypoint] = pNearestWaypoint
      gGame.cars[p.tag][#specifics][#currentDistance] = pTempDistance
      exit repeat
    end if
  end repeat
  if p.Sphere2 <> VOID then
    if pNearestWaypoint <> 0 then
      p.Sphere2.transform.position = pNearestWaypointPos
    end if
  end if
  p.TargetList = []
  repeat with j = 1 to p.TargetEntries
    pNR = pNearestWaypoint + j
    if pNR > p.MyWayPointList.count then
      pNR = p.MyWayPointList.count
    end if
    if pNR = 0 then
      next repeat
    end if
    pEntry = p.MyWayPointList[pNR]
    p.TargetList.append(pEntry)
  end repeat
  p.DifferenceList = []
  repeat with i = 1 to p.TargetEntries
    thisWorldPosn = p.TargetList[i][1].duplicate()
    thisWorldPosn.z = p.LeaderHelper.transform.position.z
    if thisWorldPosn = p.LeaderHelper.transform.position then
      p.DifferenceList.append(0.0)
      next repeat
    end if
    p.LeaderHelper.pointAt(thisWorldPosn, vector(0.0, 0.0, 1.0))
    pChassisAxis = abs(p.model.transform.axisAngle[2])
    pLeaderHelperAxis = abs(p.LeaderHelper.transform.axisAngle[2])
    pDifferenceEntry = abs(pLeaderHelperAxis - pChassisAxis)
    p.DifferenceList.append(pDifferenceEntry)
  end repeat
end

on Drive me
  pTarget = p.TargetList[p.StartEntry]
  pDifference = p.DifferenceList[p.StartEntry]
  if p.Sphere1 <> VOID then
    p.Sphere1.transform.position = pTarget[1]
  end if
  thisWorldPosn = pTarget[1].duplicate()
  thisWorldPosn.z = p.LeaderHelper.transform.position.z
  p.LeaderHelper.pointAt(thisWorldPosn, vector(0.0, 0.0, 1.0))
  pos1 = pTarget[1] - p.CarPos
  pos1.normalize()
  TempTrans = p.model.transform.duplicate()
  TempTrans.position = vector(0, 0, 0)
  TempTrans.scale = vector(1, 1, 1)
  WorldForward = TempTrans * p.LocalForward
  WorldAxis = TempTrans * -p.LocalDown
  WorldRight = WorldForward.cross(WorldAxis)
  pLeftRight = pos1.dot(WorldRight)
  pCheckNr1 = p.StartEntry
  pCheckNr2 = p.TargetEntries
  pAmount = 0
  repeat with j = 1 to pCheckNr1
    pAmount = pAmount + p.DifferenceList[j]
  end repeat
  pGeneralDifference1 = pAmount / pCheckNr1
  pAmount = 0
  repeat with k = 1 to pCheckNr2
    pAmount = pAmount + p.DifferenceList[k]
  end repeat
  pGeneralDifference2 = pAmount / pCheckNr2
  gGame.cars[p.tag][#Keys][#forward] = 1
  pBackwardDifference = abs(pDifference - pGeneralDifference1)
  pBrakingDifference = abs(pDifference - pGeneralDifference2)
  if pBrakingDifference > 14.0 then
    gGame.cars[p.tag][#Keys][#brake] = 1
  else
    gGame.cars[p.tag][#Keys][#brake] = 0
  end if
  pNitroState = gGame.cars[p.tag][#specifics][#nitroState]
  if (pNitroState <> 1) and (pBrakingDifference <= 2.0) then
    if (gGame.cars[p.tag][#Keys][#right] = 0) and (gGame.cars[p.tag][#Keys][#left] = 0) then
      if random(1, 50) = 1 then
        gGame.cars[p.tag][#Keys][#Nitro] = 1
      end if
    end if
  end if
  if pDifference > 3.5 then
    if pLeftRight < 0.0 then
      gGame.cars[p.tag][#Keys][#right] = 0
      gGame.cars[p.tag][#Keys][#left] = 1
    else
      gGame.cars[p.tag][#Keys][#right] = 1
      gGame.cars[p.tag][#Keys][#left] = 0
    end if
  else
    gGame.cars[p.tag][#Keys][#right] = 0
    gGame.cars[p.tag][#Keys][#left] = 0
  end if
  pPreviousLeft = gGame.cars[p.tag][#Keys][#left]
  pPreviousRight = gGame.cars[p.tag][#Keys][#right]
  if p.CurrentSpeed <= 1.5 then
    p.stuckCounter = p.stuckCounter + 1
    if p.stuckCounter = 50 then
      p.parent.Flip()
    end if
  else
    if p.CurrentSpeed >= 1.5 then
      p.stuckCounter = 0
    end if
  end if
end

on AutoUnstuck me
  pangle = abs(p.StuckAngle - p.model.transform.axisAngle[2])
  if pangle <= 10.0 then
    p.subState = "Forwards"
    timeout("AutoUnstuck").forget()
  end if
end

on Unstuck me
  if p.subState = "Backwards" then
    gGame.cars[p.tag][#Keys][#forward] = 0
    gGame.cars[p.tag][#Keys][#backward] = 1
    gGame.cars[p.tag][#Keys][#left] = p.PreviousRight
    gGame.cars[p.tag][#Keys][#right] = p.PreviousLeft
    pangle = abs(p.StuckAngle - p.model.transform.axisAngle[2])
    if pangle >= 45.0 then
      p.subState = "Forwards"
      if _movie.timeoutList.getPos(timeout("AutoUnstuck")) <> 0 then
        timeout("AutoUnstuck").forget()
      end if
    end if
    p.ForwardCounter = 0
  else
    gGame.cars[p.tag][#Keys][#forward] = 1
    gGame.cars[p.tag][#Keys][#backward] = 0
    gGame.cars[p.tag][#Keys][#left] = 0
    gGame.cars[p.tag][#Keys][#right] = 0
    p.ForwardCounter = p.ForwardCounter + 1
    if p.ForwardCounter = 20 then
      p.state = "Drive"
      p.subState = EMPTY
    end if
  end if
end
