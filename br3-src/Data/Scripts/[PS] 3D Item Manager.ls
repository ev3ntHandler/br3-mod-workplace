property p
global g

on new me, tParams
  p = [:]
  p[#member] = tParams[#member]
  p[#ScriptName] = "3D Item Manager"
  g[#Items3D] = [:]
  g[#ItemPickers] = []
  g[#ItemOwner] = VOID
  p[#CurrentRoots] = []
  return me
end

on stepFrame me
  if getaProp(g, #Items3D) = VOID then
    exit
  end if
  pCount = g.Items3D.count
  repeat with i = 1 to pCount
    pSubList = g.Items3D[i]
    pHidden = pSubList[#hidden]
    if pHidden = 1 then
      next repeat
    end if
    pCurrentRootNr = g.cars[symbol(g.camera.target)][#specifics][#currentRootNr]
    if pCurrentRootNr = i then
      next repeat
    end if
    pCount2 = pSubList.count
    repeat with j = 1 to pCount2
      pProp = pSubList.getPropAt(j)
      if pProp = #hidden then
        next repeat
      end if
      if pProp = #traffic then
        next repeat
      end if
      pCount3 = pSubList[j].PositionList.count
      repeat with k = 1 to pCount3
        pCheck = pSubList[j].PositionList[k]
        if pCheck <> VOID then
          p.member.model(pSubList[j].modelNames[k]).removeFromWorld()
        end if
      end repeat
    end repeat
  end repeat
  p.CurrentRoots = []
  pCount = g.ItemPickers.count
  repeat with t = 1 to pCount
    pTarget = p.member.model(g.ItemPickers[t])
    pController = g.cars[symbol(g.ItemPickers[t])][#controller]
    if pTarget = VOID then
      next repeat
    end if
    pCurrentRootNr = g.cars[symbol(g.ItemPickers[t])][#specifics][#currentRootNr]
    p.CurrentRoots.add(pCurrentRootNr)
    pFutureNr = pCurrentRootNr + 1
    if pFutureNr > g.Items3D.count then
      pFutureNr = g.Items3D.count
    end if
    if g.cars[symbol(g.ItemPickers[t])][#state] <> "None" then
      next repeat
    end if
    if pFutureNr = pCurrentRootNr then
      pItemList = [g.Items3D[pCurrentRootNr]]
    else
      pItemList = [g.Items3D[pCurrentRootNr], g.Items3D[pFutureNr]]
    end if
    pHidden = pItemList[1][#hidden]
    if pTarget.name = g.camera.target then
      pHidden = 0
      g.Items3D[pCurrentRootNr][#hidden] = 0
      g.Items3D[pFutureNr][#hidden] = 0
    end if
    pItemListCount = pItemList.count
    repeat with t = 1 to pItemListCount
      pItemTypesCount = pItemList[t].count
      repeat with i = 1 to pItemTypesCount
        pCurrentProp = pItemList[t].getPropAt(i)
        if pCurrentProp = #hidden then
          next repeat
        end if
        if pCurrentProp = #traffic then
          next repeat
        end if
        if (pCurrentProp = #ItemHiddenPackage) and (pController = #AI) then
          next repeat
        end if
        pDistance = pItemList[t][i][#distance]
        pevent = pItemList[t][i][#event]
        pPositionList = pItemList[t][i][#PositionList]
        pModelNames = pItemList[t][i][#modelNames]
        pItemCount = pPositionList.count
        repeat with j = 1 to pItemCount
          pItemPos = pPositionList[j]
          if pItemPos = VOID then
            next repeat
          end if
          pItemModel = p.member.model(pModelNames[j])
          if pItemModel = VOID then
            next repeat
          end if
          pTargetPos = pTarget.getWorldTransform().position
          pItemDistance = pItemPos.distanceTo(pTargetPos)
          if (pHidden = 0) and (pItemDistance <= 150.0) then
            pItemModel.addToWorld()
          end if
          if pItemModel.isInWorld() = 1 then
            pPos = p.member.camera("DefaultView").transform.position
            pPos.z = p.member.model(pModelNames[j]).transform.position.z
            p.member.model(pModelNames[j]).pointAt(pPos, vector(0.0, 0.0, 1.0))
          end if
          if t = 1 then
            if pItemDistance <= pDistance then
              if pCurrentProp = #ItemHiddenPackage then
                g.ItemOwner = pTarget.name
                p.member.deleteModel(pModelNames[j])
                pPositionList[j] = VOID
                next repeat
              end if
              g.ItemOwner = pTarget.name
              event(pevent)
              p.member.deleteModel(pModelNames[j])
              pPositionList[j] = VOID
              g.ItemOwner = VOID
            end if
          end if
        end repeat
      end repeat
    end repeat
  end repeat
end

on SetupTraffic me
  p[#TrafficList] = []
  p[#TrafficNameList] = ["Lupo", "Transporter", "Truck"]
  p[#WeightList] = [1500, 3000, 8000]
  p[#TrafficModelList] = []
  pTexture = p.member.texture("Crumpled_Texture")
  if pTexture = VOID then
    pTexture = createTexture(p.member.name, [#fileName: "Crumpled_Texture", #filtering: #lowFiltered])
  end if
  pCount = p.TrafficNameList.count
  repeat with i = 1 to pCount
    event("SetupTraffic" & p.TrafficNameList[i])
    pModelNameList = CLONEMODELS(p.member, [#cloneMember: "Traffic" & p.TrafficNameList[i]])
    pCount2 = pModelNameList.count
    repeat with j = 1 to pCount2
      pmodel = p.member.model(pModelNameList[j])
      if pmodel <> VOID then
        pmodel.removeFromWorld()
        if pmodel.name contains "Crashed" then
          pmodel.shader.texture = pTexture
        end if
        p.TrafficModelList.add(pmodel)
      end if
    end repeat
  end repeat
end

on BuildTraffic tVehicle, tVehicleNr, tCurrentRoot
  if getaProp(g, #WayPointList) = VOID then
    exit
  end if
  if g.WayPointList[1] = [] then
    exit
  end if
  pOldDelimiter = the itemDelimiter
  the itemDelimiter = "_"
  pTagName = string(g.Items3D.getPropAt(tCurrentRoot)).item[1]
  the itemDelimiter = pOldDelimiter
  pNewTraffic = p.member.newModel("Traffic_" & pTagName & "_" & tVehicle & tVehicleNr, p.member.modelResource(tVehicle))
  pNewTraffic.shader = p.member.model(tVehicle).shader
  pNewTraffic.pointAtOrientation = [vector(0.0, 1.0, 0.0), vector(0.0, 0.0, 1.0)]
  pCount = g.WayPointList[tCurrentRoot].count
  case tVehicleNr of
    1:
      pData = [3, 1]
    2:
      pData = [integer(pCount / 4), -1]
    3:
      pData = [pCount - 3, 1]
    4:
      pData = [integer(pCount / 4 * 3), -1]
  end case
  pNewPos = g.WayPointList[tCurrentRoot][pData[1]][1]
  pPointAtPos = g.WayPointList[tCurrentRoot][pData[1] + (1 * pData[2])][1]
  pNewTraffic.transform.position = pNewPos
  pNewTraffic.pointAt(pPointAtPos, vector(0, 0, 1))
  pRandom = random(1, 2)
  pOffSetList = [2.0, 6.5]
  pNewTraffic.translate(vector(pOffSetList[pRandom], 0, 0), #self)
  pWeight = p.WeightList[p.TrafficNameList.getPos(tVehicle)]
  pTraffic = AddObstacle(0, p.member.name, [#model: pNewTraffic.name, #type: #dynamic, #mass: pWeight, #bodyProxy: #convexShape])
  p.TrafficList.add([#car: pNewTraffic, #rbCar: pTraffic, #resource: tVehicle, #state: "Alive", #ROOT: tCurrentRoot])
  AddCollisionReport(EMPTY, [#nameA: pNewTraffic.name, #nameB: #cars])
end

on HandleTraffic me
  PList = p.TrafficList.duplicate()
  pCount = p.TrafficList.count
  repeat with i = 1 to pCount
    pCar = PList[i][#car]
    pPhysicsCar = PList[i][#rbCar]
    pSymbol = symbol(pCar.name)
    pCarRoot = PList[i][#ROOT]
    if pCarRoot < p.CurrentRoots[1] then
      g.Physics.deleteRigidBody(pCar.name)
      p.member.deleteModel(pCar.name)
      PList[i] = []
      next repeat
    end if
    if getaProp(g.collisionReports, pSymbol) <> VOID then
      if g.collisionReports[pSymbol] <> [] then
        pState = PList[i][#state]
        if pState = "Alive" then
          pCar.resource = p.member.modelResource(PList[i][#resource] & "Crashed")
          pCar.shader = p.member.shader(PList[i][#resource] & "Crashed_Material")
          pRandomVector = randomVector()
          pPhysicsCar.applyLinearImpulse(vector(pRandomVector.x * 1000, pRandomVector.y * 1000, 20000.0))
          pPhysicsCar.applyTorque(vector(pRandomVector.x * 450000, pRandomVector.y * 450000, pRandomVector.z * 550000))
          if g.VisibleRootList.getPos(pCarRoot) <> 0 then
            pExplosion = new(script("[PPS] Car Explosion"), p.member, vector(0, 0, 0), p.member.camera("DefaultView"), pCar.name)
            _movie.actorList.add(pExplosion)
          end if
          PlaySound("CrashGlass", [#priority: #low, #surround: 1, #member3DName: p.member.name, #rateShift: random(-4, 4), #sender: pCar.name, #targetName: pCar.name, #referenceName: "DefaultView", #distance: [20, 100], #static: 1])
          PlaySound("Explosion", [#priority: #medium, #surround: 1, #member3DName: p.member.name, #random: [1, 2], #sender: pCar.name, #targetName: pCar.name, #referenceName: "DefaultView", #distance: [20, 100], #static: 1])
          PList[i][#state] = "Death"
          g.collisionReports[pSymbol] = []
        end if
      end if
    end if
  end repeat
  pCount = PList.count
  p.TrafficList = []
  repeat with i = 1 to pCount
    if PList[i] <> [] then
      p.TrafficList.add(PList[i])
    end if
  end repeat
end

on start me
end

on reset me
end
