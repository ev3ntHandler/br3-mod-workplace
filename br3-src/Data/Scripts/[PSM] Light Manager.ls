property p
global g

on new me, tParams
  p = [:]
  p[#member] = member(tParams[#memberName])
  if (p.member = VOID) or (p.member.type <> #shockwave3d) then
    ShowError("Script: [PSM] Car Shadow. " & tParams & " No such member or type is NOT shockwave3d")
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
    ShowError("Script: [PSM] Light Manager. " & tParams & " No model found based upon modelName AND/OR no model returned from parent script")
    exit
  end if
  p[#tag] = #standard
  if getaProp(tParams, #tag).ilk = #symbol then
    p.tag = tParams[#tag]
  end if
  p[#ScriptLimit] = 1
  p[#Cleared] = 0
  p[#adjColor] = rgb(0, 0, 0)
  if getaProp(tParams, #adjColor).ilk = #color then
    p.adjColor = tParams[#adjColor]
  end if
  p[#shaderList] = []
  p[#modelList] = VOID
  p.modelList = tParams[#TotalModelList]
  if p.modelList = VOID then
    ShowError("Script: [PSM] Light Manager. " & tParams & " No modellist. Can't compile shaderlist. Exit script.")
    exit
  end if
  pCount = p.modelList.count
  repeat with i = 1 to pCount
    pmodel = p.member.model(p.modelList[i])
    if pmodel <> VOID then
      pTempList = pmodel.shaderList
      pCount2 = pTempList.count
      repeat with j = 1 to pCount2
        pShader = pTempList[j]
        if pShader.name contains "proxy" then
          next repeat
        end if
        if p.shaderList.getPos(pShader) = 0 then
          p.shaderList.add(pShader)
        end if
      end repeat
    end if
  end repeat
  p[#LastImageData] = [VOID, VOID]
  p[#CoordList1] = VOID
  p[#CoordList2] = VOID
  return me
end

on enterFrame me
  p.Cleared = 0
  if getaProp(g, #RayCastList) = VOID then
    exit
  end if
  if getaProp(g.RayCastList, p.tag) = VOID then
    exit
  end if
  if g.RayCastList[p.tag] = [] then
    exit
  end if
  pIsectModel = g.RayCastList[p.tag][1][#model]
  pimage = p.member.model(pIsectModel.name).shader.textureList[2]
  if pimage = VOID then
    exit
  end if
  if pimage.name <> p.LastImageData[1] then
    p.LastImageData[1] = pimage.name
    p.LastImageData[2] = member(pimage.name).image
    p.CoordList1 = pIsectModel.meshDeform.mesh[g.RayCastList[p.tag][1][#meshID]].face.textureLayer[1].textureCoordinateList
    p.CoordList2 = pIsectModel.meshDeform.mesh[g.RayCastList[p.tag][1][#meshID]].face.textureLayer[2].textureCoordinateList
  end if
  pPos = mMapPointToTexture(g.RayCastList[p.tag][1], p.LastImageData[2].width, p.LastImageData[2].height, p.CoordList2)
  g.cars[p.tag][#specifics][#rcPoint] = mMapPointToTexture(g.RayCastList[p.tag][1], 1024, 1024, p.CoordList1)
  if pPos = 0 then
    pcolor = rgb(255, 255, 255)
  else
    pcolor = p.LastImageData[2].getPixel(pPos)
  end if
  pcolor = pcolor - p.adjColor
  if (pcolor = 0) or (pcolor = VOID) then
    pcolor = rgb(255, 255, 255)
  end if
  g.cars[p.tag][#specifics][#LMColor] = pcolor
  pCount = p.shaderList.count
  repeat with i = 1 to pCount
    pShader = p.shaderList[i]
    pShader.emissive = pcolor
    pShader.specular = pcolor
  end repeat
end

on mMapPointToTexture pRayCastData, tWidth, tHeight, tCoordList
  tModel2 = pRayCastData[#model]
  tFace = pRayCastData[#faceID]
  tUVCoord = pRayCastData[#uvCoord]
  tFaceList = tModel2.meshDeform.mesh[pRayCastData[#meshID]].face[tFace]
  tLocA = tCoordList[tFaceList[1]]
  tLocA = point(tLocA[1] * tWidth, (1 - tLocA[2]) * tHeight)
  tLocB = tCoordList[tFaceList[2]]
  tLocB = point(tLocB[1] * tWidth, (1 - tLocB[2]) * tHeight)
  tLocC = tCoordList[tFaceList[3]]
  tLocC = point(tLocC[1] * tWidth, (1 - tLocC[2]) * tHeight)
  tUVector = (tLocB - tLocA) * tUVCoord.u
  tVVector = (tLocC - tLocA) * tUVCoord.V
  return tLocA + tUVector + tVVector
end

on clear me
  if p.Cleared = 1 then
    exit
  end if
  p.Cleared = 1
end
