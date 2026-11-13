property p
global g

on new me, tParams
  p = [:]
  p[#member] = member(tParams[#memberName])
  p[#ProxyModelName] = tParams[#collModelName]
  p[#car] = tParams[#car]
  p[#CarName] = tParams[#CarName]
  p[#wheellist] = tParams[#wheellist]
  p[#sprite] = sprite(tParams[#SpriteNR])
  p[#tag] = tParams[#tag]
  p[#controller] = tParams[#controller]
  p[#collModelName] = symbol(tParams[#collModelName])
  p[#nitroModels] = tParams[#nitroModels]
  p[#CollisionPosition] = VOID
  p[#PhysicsCar] = g.Physics.getRigidBody(tParams[#collModelName])
  p[#mass] = p.PhysicsCar.mass
  p[#ScriptLimit] = 1
  p[#Cleared] = 0
  p.car = p.member.model(p.car)
  SetupLights()
  SetupSparks()
  SetupSmoke()
  SetupSlipParticles()
  SetupNitro()
  return me
end

on enterFrame me
  p.Cleared = 0
  HandleLights()
  HandleSparks()
  HandleSmoke()
  HandleSlipParticles()
  HandleNitro()
end

on clear me
  if p.Cleared = 1 then
    exit
  end if
  p.RearLightModel.parent = VOID
  p.FrontLightModel.parent = VOID
  p.SparksModel.parent = VOID
  p.SmokeModel.removeFromWorld()
  pCount = p.SlipParticles.count
  repeat with i = 1 to pCount
    p.SlipParticles[i][2].removeFromWorld()
  end repeat
  p.Cleared = 1
end

on SetupLights me
  pRearResource = p.member.modelResource(p.CarName & "RearLights")
  if pRearResource = VOID then
    createTexture(p.CarName, [#fileName: "RearLight_Texture", #filtering: #lowFiltered, #renderFormat: #rgba8888])
    CLONEMODELS(p.member, [#cloneMember: p.CarName, #modelList: [p.CarName & "RearLights"], #NameList: [p.tag & "RearLights"]])
    p[#RearLightModel] = p.member.model(p.tag & "RearLights")
    SetAddShader(p.member.shader("RearLight_Material"))
  else
    p[#RearLightModel] = p.member.newModel(p.tag & "RearLights", pRearResource)
    p.RearLightModel.shader = p.member.shader("RearLight_Material")
  end if
  p.RearLightModel.visibility = #both
  p.RearLightModel.transform.position = p.car.transform.position
  p.RearLightModel.parent = VOID
  pFrontResource = p.member.modelResource(p.CarName & "FrontLights")
  if pFrontResource = VOID then
    createTexture(p.CarName, [#fileName: "FrontLight_Texture", #filtering: #lowFiltered, #renderFormat: #rgba8888])
    CLONEMODELS(p.member, [#cloneMember: p.CarName, #modelList: [p.CarName & "FrontLights"], #NameList: [p.tag & "FrontLights"]])
    p[#FrontLightModel] = p.member.model(p.tag & "FrontLights")
    SetAddShader(p.member.shader("FrontLight_Material"))
  else
    p[#FrontLightModel] = p.member.newModel(p.tag & "FrontLights", pFrontResource)
    p.FrontLightModel.shader = p.member.shader("FrontLight_Material")
  end if
  p.FrontLightModel.visibility = #both
  p.FrontLightModel.transform.position = p.car.transform.position
  p.FrontLightModel.parent = VOID
end

on HandleLights me
  p[#backward] = g.cars[p.tag][#Keys][#backward]
  p[#brake] = g.cars[p.tag][#Keys][#brake]
  p[#LMColor] = g.cars[p.tag][#specifics][#LMColor]
  p[#Health] = g.cars[p.tag][#specifics][#Health]
  if p.Health = 0 then
    if p.FrontLightModel.isInWorld() = 1 then
      p.FrontLightModel.parent = VOID
    end if
    if p.RearLightModel.isInWorld() = 1 then
      p.RearLightModel.parent = VOID
    end if
  else
    pTotalColor = p.LMColor.red + p.LMColor.green + p.LMColor.blue
    if p.backward = 1 then
      p.RearLightModel.parent = p.car
    end if
    p[#currentFloor] = g.cars[p.tag][#specifics][#currentFloor]
    if p.currentFloor.name contains "Tunnel" then
      if p.LMColor <> rgb(255, 255, 255) then
        p.RearLightModel.parent = p.car
        p.FrontLightModel.parent = p.car
      else
        if p.FrontLightModel.isInWorld() = 1 then
          p.FrontLightModel.parent = VOID
        end if
        if (p.RearLightModel.isInWorld() = 1) and (p.backward = 0) then
          p.RearLightModel.parent = VOID
        end if
      end if
    else
      if pTotalColor <= 300 then
        p.RearLightModel.parent = p.car
        p.FrontLightModel.parent = p.car
      else
        if p.FrontLightModel.isInWorld() = 1 then
          p.FrontLightModel.parent = VOID
        end if
        if (p.RearLightModel.isInWorld() = 1) and (p.backward = 0) then
          p.RearLightModel.parent = VOID
        end if
      end if
    end if
  end if
end

on SetupSparks me
  pSparksResource = p.member.modelResource("Sparks")
  if pSparksResource = VOID then
    createTexture("Sparks", [#fileName: "Sparks_Texture", #filtering: #lowFiltered, #renderFormat: #rgba8888])
    CLONEMODELS(p.member, [#cloneMember: "Sparks", #modelList: ["Sparks"], #NameList: [p.tag & "Sparks"]])
    p[#SparksModel] = p.member.model(p.tag & "Sparks")
  else
    p[#SparksModel] = p.member.newModel(p.tag & "Sparks", pSparksResource)
    p.SparksModel.shader = p.member.shader("Sparks_Material")
  end if
  p.SparksModel.pointAtOrientation = [vector(0, 1, 0), vector(0, 0, 1)]
  p.SparksModel.visibility = #both
  p.SparksModel.removeFromWorld()
end

on HandleSparks me
  p[#collisionDetails] = g.cars[p.tag][#specifics][#collisionDetails]
  p[#CurrentSpeed] = g.cars[p.tag][#specifics][#speedMS]
  p[#maxSpeed] = g.cars[p.tag][#specifics][#maxSpeed]
  p[#Percentage] = abs(p.CurrentSpeed / p.maxSpeed)
  if p.collisionDetails <> [] then
    if p.SparksModel <> VOID then
      if p.SparksModel.isInWorld() = 0 then
        p.SparksModel.addToWorld()
      end if
      p.SparksModel.transform.position = p.collisionDetails[3]
      rb = g.Physics.getRigidBody(p.ProxyModelName)
      pPos = rb.position
      pLin = rb.linearVelocity
      pAdjLin = pLin / (1.0 / g.tempo)
      pPosFuture = pPos + pAdjLin
      pPointAt = p.collisionDetails[3]
      pPointAt = pPointAt + (pPointAt + pAdjLin)
      p.SparksModel.pointAt(pPointAt, vector(0, 0, 1))
      if p.Percentage < 0.25 then
        p.Percentage = 0.25
      end if
      if p.CurrentSpeed < 0 then
        p.Percentage = p.Percentage * -1
      end if
      p.SparksModel.transform.scale = vector(1.0, 1.0, 1.0) * p.Percentage
    end if
    g.cars[p.tag][#specifics][#collisionDetails] = []
  else
    p.SparksModel.removeFromWorld()
  end if
end

on SetupSmoke me
  p[#SmokeResource] = p.member.newModelResource(p.tag & "Smoke", #particle)
  p.SmokeResource.emitter.numParticles = 45
  p.SmokeResource.emitter.minSpeed = 0.5
  p.SmokeResource.emitter.maxSpeed = 2.0
  p.SmokeResource.emitter.direction = vector(0.0, 0.0, 1.0)
  p.SmokeResource.colorRange.start = color(255, 255, 255)
  p.SmokeResource.colorRange.end = color(0, 0, 0)
  p.SmokeResource.sizeRange.start = 1.30000000000000004
  p.SmokeResource.sizeRange.end = 2.20000000000000018
  p.SmokeResource.emitter.angle = 45.0
  p.SmokeResource.lifeTime = 750.0
  p.SmokeResource.blendRange.start = 100
  p.SmokeResource.blendRange.end = 0
  p.SmokeResource.drag = 0
  pTexture = p.member.texture("Smoke_Texture")
  if pTexture = VOID then
    pTexture = createTexture(p.member.name, [#fileName: "Smoke_Texture", #filtering: #lowFiltered, #renderFormat: #rgba8888])
  end if
  p.SmokeResource.texture = pTexture
  p[#SmokeModel] = p.member.newModel(p.tag & "Smoke", p.SmokeResource)
  p.SmokeModel.removeFromWorld()
  p[#SmokeGroup] = p.member.newGroup(p.car & "Smoke_Group")
  p.SmokeGroup.transform.position = vector(0.0, 0.0, 0.0)
  p.SmokeGroup.parent = p.car
  if member(p.CarName).group(p.CarName & "Smoke_Dummy") <> VOID then
    pDifference = member(p.CarName).group(p.CarName & "Smoke_Dummy").transform.position - member(p.CarName).model(p.CarName).transform.position
    p.SmokeGroup.transform.position = p.SmokeGroup.transform.position + pDifference
  end if
end

on HandleSmoke me
  p[#CurrentState] = g.cars[p.tag][#specifics][#CrashState]
  if p.CurrentState = 3 then
    if p.SmokeModel.isInWorld() = 0 then
      p.SmokeModel.addToWorld()
    end if
    pRegion = p.SmokeGroup.getWorldTransform().position
    p.SmokeResource.emitter.region = [pRegion]
  else
    if p.SmokeModel.isInWorld() = 1 then
      p.SmokeModel.removeFromWorld()
    end if
  end if
end

on SetupSlipParticles me
  p[#SlipParticles] = []
  pCount = p.wheellist.count
  repeat with i = 1 to pCount
    pResource = p.member.newModelResource(p.tag & "PartSlip" & i, #particle)
    pResource.emitter.numParticles = 40
    pResource.emitter.maxSpeed = 0.0
    pResource.colorRange.start = color(255, 255, 255)
    pResource.colorRange.end = color(255, 255, 255)
    pRandom = random(5)
    pString1 = "1." & string(pRandom)
    pString2 = "4." & string(pRandom)
    pResource.sizeRange.start = value(pString1)
    pResource.sizeRange.end = value(pString2)
    pResource.emitter.angle = 0.0
    pResource.lifeTime = 750.0
    pResource.blendRange.start = 0.0
    pResource.blendRange.end = 0
    pResource.drag = 0
    pTexture = p.member.texture("SlipSmoke" & i & "_Texture")
    if pTexture = VOID then
      pTexture = createTexture(p.member.name, [#fileName: "SlipSmoke" & i & "_Texture", #filtering: #lowFiltered, #renderFormat: #rgba8888])
    end if
    pResource.texture = pTexture
    pmodel = p.member.newModel(p.tag & "PartSlip" & i, pResource)
    pmodel.addToWorld()
    p.SlipParticles.add([pResource, pmodel])
  end repeat
  p[#ExtraSlip1] = createTexture(p.member.name, [#fileName: "SlipSmoke5_Texture", #filtering: #lowFiltered, #renderFormat: #rgba8888])
  p[#ExtraSlip2] = createTexture(p.member.name, [#fileName: "SlipSmoke6_Texture", #filtering: #lowFiltered, #renderFormat: #rgba8888])
end

on HandleSlipParticles me
  p[#slip] = g.cars[p.tag][#specifics][#slip]
  p[#falling] = g.cars[p.tag][#specifics][#falling]
  tOverride = 0
  if p.falling = 1 then
    tOverride = 1
  end if
  tPoint = g.cars[p.tag][#specifics][#rcPoint]
  if (tPoint.locH >= 512) and (tPoint.locV >= 512) then
    tOverride = 1
  end if
  if g.cars[p.tag][#Keys][#brake] = 1 then
    p.SlipParticles[1][1].texture = p.ExtraSlip1
    p.SlipParticles[2][1].texture = p.ExtraSlip2
    if (tPoint.locH >= 512) and (tPoint.locV >= 512) then
      p.SlipParticles[3][1].texture = p.ExtraSlip1
      p.SlipParticles[4][1].texture = p.ExtraSlip2
    else
      p.SlipParticles[3][1].texture = p.member.texture("SlipSmoke3_Texture")
      p.SlipParticles[4][1].texture = p.member.texture("SlipSmoke4_Texture")
    end if
    tOverride = 0
  else
    if p.slip = 0 then
      p.SlipParticles[1][1].texture = p.member.texture("SlipSmoke1_Texture")
      p.SlipParticles[2][1].texture = p.member.texture("SlipSmoke2_Texture")
      p.SlipParticles[3][1].texture = p.member.texture("SlipSmoke3_Texture")
      p.SlipParticles[4][1].texture = p.member.texture("SlipSmoke4_Texture")
    end if
  end if
  if tOverride = 1 then
    tTargetBlend = 0
  else
    tTargetBlend = integer(100.0 * abs(p.Percentage))
  end if
  tTargetBlend = min(100, tTargetBlend)
  tBlend = p.SlipParticles[1][1].blendRange.start
  if tTargetBlend > tBlend then
    tBlend = tBlend + 3
  else
    if tTargetBlend < tBlend then
      tBlend = tBlend - 3
    end if
  end if
  tBlend = integer(max(tTargetBlend, min(100, tBlend)))
  repeat with k in p.SlipParticles
    if k[2].isInWorld() = 0 then
      k[2].addToWorld()
    end if
    k[1].blendRange.start = tBlend
  end repeat
  UpdateSlipParticles()
end

on UpdateSlipParticles me
  pTempRandomList = [1, 2, 3, 4]
  pRandomList = []
  repeat with n = 1 to 4
    pRandomNumber = random(1, pTempRandomList.count)
    pRandomList.add(pTempRandomList[pRandomNumber])
    pTempRandomList.deleteAt(pRandomNumber)
  end repeat
  repeat with i = 1 to 4
    pModelResource = p.SlipParticles[i][1]
    pmodel = p.wheellist[pRandomList[i]]
    pPosition = pmodel.transform.position
    pModelResource.emitter.region = [pPosition]
    pNewColor = pNewColor + rgb(40, 40, 40)
    pModelResource.colorRange.start = p.LMColor
    pModelResource.colorRange.end = p.LMColor
  end repeat
end

on SetupNitro me
  p[#NitroModelList] = []
  pAmount = 0
  pCount = member(p.CarName).group.count
  repeat with i = 1 to pCount
    if member(p.CarName).group[i].name contains "Nitro" then
      pAmount = pAmount + 1
    end if
  end repeat
  if pAmount = 0 then
    exit
  end if
  pNitroResource = p.member.modelResource("Nitro")
  if pNitroResource = VOID then
    createTexture("Nitro", [#fileName: "NItro_Texture", #filtering: #lowFiltered, #renderFormat: #rgba8888])
    CLONEMODELS(p.member, [#cloneMember: "Nitro", #modelList: ["Nitro"]])
    SetAddShader(p.member.shader("Nitro_Material"))
    pNitroResource = p.member.modelResource("Nitro")
    p.member.model("Nitro").removeFromWorld()
  end if
  repeat with i = 1 to pAmount
    pNitroModel = p.member.newModel(p.tag & "Nitro" & i, pNitroResource)
    pNitroModel.shader = p.member.shader("Nitro_Material")
    pNitroModel.pointAtOrientation = [vector(0, 1, 0), vector(0, 0, 1)]
    pNitroModel.transform.position = vector(0.0, 0.0, 0.0)
    pNitroModel.parent = p.car
    pDifference = member(p.CarName).group(p.CarName & "Nitro" & i & "_Dummy").transform.position - member(p.CarName).model(p.CarName).transform.position
    pNitroModel.transform.position = pNitroModel.transform.position + pDifference
    pNitroModel.removeFromWorld()
    p.NitroModelList.add(pNitroModel)
  end repeat
end

on HandleNitro me
  p[#GoingForward] = g.cars[p.tag][#Keys][#forward]
  p[#nitroState] = g.cars[p.tag][#specifics][#nitroState]
  if (p.GoingForward = 1) and (p.nitroState = 1) and (g.cars[p.tag][#specifics][#Health] > 0) then
    pmodel = p.NitroModelList[1]
    pScale = pmodel.transform.scale.z
    pVisible = p.NitroModelList[1].isInWorld()
    pRandomScale = value("1." & random(0, 2) & random(0, 9))
    repeat with i = 1 to p.NitroModelList.count
      pmodel = p.NitroModelList[i]
      pScale = pmodel.transform.scale.z
      if pVisible = 0 then
        pmodel.addToWorld()
        pmodel.parent = p.car
      end if
      pScale = pScale + 0.10000000000000001
      if pScale > 1.0 then
        pScale = 1.0
      end if
      pmodel.transform.scale = vector(pScale, pScale, pScale)
      pmodel.transform.scale = pmodel.transform.scale * pRandomScale
      pmodel.transform.scale.x = pmodel.transform.scale.x * pRandomScale
      pmodel.transform.scale.z = pmodel.transform.scale.z * pRandomScale
    end repeat
  else
    pmodel = p.NitroModelList[1]
    pScale = pmodel.transform.scale.z
    pVisible = p.NitroModelList[1].isInWorld()
    if pScale > 0.0 then
      repeat with i = 1 to p.NitroModelList.count
        pmodel = p.NitroModelList[i]
        pScale = pmodel.transform.scale.z
        if pScale > 0.0 then
          pScale = pScale - 0.10000000000000001
          if pScale <= 0.01 then
            pScale = 0.01
          end if
          pmodel.transform.scale = vector(pScale, pScale, pScale)
          if pScale = 0.01 then
            if pVisible = 1 then
              p.NitroModelList[i].removeFromWorld()
            end if
          end if
        end if
      end repeat
    end if
  end if
end
