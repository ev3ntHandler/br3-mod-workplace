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
    ShowError("Script: [PSM] Car Shadow. " & tParams & " No model found based upon modelName AND/OR no model returned from parent script")
    exit
  end if
  p[#ShadowSize] = tParams[#size]
  p[#TextureName] = tParams[#texture]
  p[#CarName] = tParams[#CarName]
  p[#controller] = tParams[#controller]
  p[#tag] = tParams[#tag]
  p[#ScriptLimit] = 1
  p[#Cleared] = 0
  if (p.ShadowSize = VOID) or (p.ShadowSize.ilk <> #list) then
    p.ShadowSize = [1, 1]
  end if
  if p.TextureName = VOID then
    pTestTextureName = p.CarName & "Shadow_Texture"
    if member(pTestTextureName) = VOID then
      p.TextureName = "SimpleShadow_Texture"
    else
      p.TextureName = pTestTextureName
    end if
  end if
  if (p.tag = VOID) or (p.tag.ilk <> #symbol) then
    p.tag = #standard
  end if
  pShadowResource = p.member.newModelResource(p.model.name & "Shadow", #plane)
  pShadowResource.width = float(p.ShadowSize[1])
  pShadowResource.length = float(p.ShadowSize[2])
  p[#shadowmodel] = p.member.newModel(p.model.name & "Shadow", pShadowResource)
  if p.member.texture(p.TextureName) = VOID then
    p.member.newTexture(p.TextureName)
    pTexture = p.member.texture(p.TextureName)
    pTexture.member = member(p.TextureName)
    pTexture.quality = #lowFiltered
    pTexture.renderFormat = #rgba8888
  else
    pTexture = p.member.texture(p.TextureName)
    pTexture.quality = #lowFiltered
  end if
  p.member.newShader(p.model.name & "Shadow_Material", #standard)
  pShader = p.member.shader(p.model.name & "Shadow_Material")
  pShader.emissive = rgb(255, 255, 255)
  pShader.shininess = 0.0
  pShader.textureList[1] = pTexture
  pShader.blend = 75.0
  p.shadowmodel.shaderList = pShader
  p.shadowmodel.transform.position = vector(0.0, 0.0, -150.0)
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
  if p.shadowmodel.isInWorld() = 0 then
    p.shadowmodel.parent = p.member.group("World")
  end if
  positionShadow = g.RayCastList[p.tag][1][#isectPosition]
  normalShadow = g.RayCastList[p.tag][1][#isectNormal]
  distance = g.RayCastList[p.tag][1][#distance]
  p.shadowmodel.transform.position = positionShadow + vector(0, 0, 0.05)
  p.shadowmodel.pointAtOrientation = [vector(0, 0, 1), vector(0, 1, 0)]
  p.shadowmodel.pointAt(p.shadowmodel.transform.position + normalShadow)
  p.shadowmodel.rotate(0, 0, p.model.transform.rotation[3])
end

on clear me
  if p.Cleared = 1 then
    exit
  end if
  p.shadowmodel.parent = VOID
  p.Cleared = 1
end
