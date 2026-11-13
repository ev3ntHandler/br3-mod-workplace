property p
global g

on new me, tParams
  p = [:]
  p[#member] = member(tParams[#memberName])
  if (p.member = VOID) or (p.member.type <> #shockwave3d) then
    ShowError("Script: [PSM] Ray Caster. " & tParams & " No such member or type is NOT shockwave3d")
    exit
  end if
  p[#model] = VOID
  pModelName = tParams[#ModelName]
  if pModelName = VOID then
    p[#model] = tParams[#RayCastModel]
  else
    p.model = p.member.model(pModelName)
  end if
  if p.model = VOID then
    ShowError("Script: [PSM] Ray Caster. " & tParams & " No model found based upon modelName AND/OR no model returned from parent script")
    exit
  end if
  p[#direction] = tParams[#direction]
  if (p.direction = VOID) or (p.direction.ilk <> #vector) then
    p.direction = vector(0.0, 0.0, -1.0) + vector(0.0001, 0.0001, 0.0001)
    ShowError("Script: [PSM] Ray Caster. " & tParams & " No direction found. Default direction set (=down).")
  else
    p.direction = p.direction + vector(0.0001, 0.0001, 0.0001)
  end if
  p[#modelList] = tParams[#modelList]
  p[#OrigModelList] = tParams[#modelList]
  p[#OptionList] = tParams[#OptionList]
  p[#controller] = tParams[#controller]
  p[#tag] = tParams[#tag]
  p[#ScriptLimit] = 1
  p[#Cleared] = 0
  if p.OptionList = VOID then
    if (p.modelList = VOID) or (p.modelList = []) then
      p.OptionList = [#maxNumberOfModels: 1, #levelOfDetail: #detailed, #maxDistance: 1]
    else
      if p.modelList = #floors then
        if getaProp(g, #FloorList) = VOID then
          p[#modelList] = []
        else
          p[#modelList] = g.FloorList
        end if
      end if
      p.OptionList = [#maxNumberOfModels: 1, #levelOfDetail: #detailed, #maxDistance: 1, #modelList: p.modelList]
    end if
  end if
  if p.tag = VOID then
    p.tag = #standard
  end if
  if getaProp(g, #RayCastList) = VOID then
    g[#RayCastList] = [:]
  end if
  return me
end

on enterFrame me
  p.Cleared = 0
  if p.OrigModelList = #floors then
    if getaProp(g, #FloorList) = VOID then
      p[#modelList] = []
    else
      pCurrentRoot = g.cars[p.tag][#specifics][#currentRootNr]
      p[#modelList] = []
      pSubList = [pCurrentRoot]
      pFutureRoot = pCurrentRoot + 1
      if pFutureRoot <= g.RootList.count then
        pSubList.add(pFutureRoot)
      end if
      pCount = pSubList.count
      repeat with i = 1 to pCount
        pRootName = "TrackRoot" & pSubList[i] & "_"
        pCount2 = g.FloorList.count
        repeat with j = 1 to pCount2
          pModelName = g.FloorList[j].name
          if pModelName contains pRootName then
            p.modelList.add(g.FloorList[j])
          end if
        end repeat
      end repeat
    end if
    p.OptionList = [#maxNumberOfModels: 1, #levelOfDetail: #detailed, #maxDistance: 1, #modelList: p.modelList]
  end if
  intersectInfo = p.member.modelsUnderRay(p.model.worldPosition, p.direction, p.OptionList)
  g.RayCastList[p.tag] = intersectInfo
end

on clear me
  if p.Cleared = 1 then
    exit
  end if
  p.Cleared = 1
end
