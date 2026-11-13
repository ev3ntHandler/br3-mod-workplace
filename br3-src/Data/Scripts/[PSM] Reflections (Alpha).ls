property pMember, pReflMember, pDebug, pSpriteNr, pSpriteLoc, pSpriteDebugLoc, pTextureSize, pCamFov, pTextureName, pcamera, pTargetCamera
global gSelectedCar, gSelectedTrack, gStageImage

on new me, pParams
  pMember = pParams[#member]
  pReflMember = pParams[#reflmember]
  pSpriteNr = pParams[#spritechannel]
  pSpriteLoc = pParams[#spriteLoc]
  pSpriteDebugLoc = pParams[#spriteDebugLoc]
  pTextureSize = pParams[#textureSize]
  pDebug = pParams[#debug]
  pCamFov = pParams[#camfov]
  pTextureName = pParams[#TextureName]
  if (pMember = VOID) or (pReflMember = VOID) then
    exit
  end if
  if pSpriteNr = VOID then
    pSpriteNr = 11
  end if
  if pTextureSize = VOID then
    pTextureSize = 128
  end if
  if pDebug = VOID then
    pDebug = 0
  end if
  if pCamFov = VOID then
    pCamFov = 115.0
  end if
  if pTextureName = VOID then
    pTextureName = gSelectedCar & "Reflection_Texture"
  end if
  if pSpriteLoc = VOID then
    pSpriteLoc = point(pTextureSize / 2, pTextureSize / 2)
  end if
  if pSpriteDebugLoc = VOID then
    pSpriteDebugLoc = point(640 + (pTextureSize / 2), pTextureSize / 2)
  end if
  resetWorld(pReflMember.name)
  pcamera = pReflMember.camera("DefaultView")
  pTargetCamera = pMember.camera("DefaultView")
  pcamera.colorBuffer.clearValue = color(0, 0, 0)
  pcamera.fog.enabled = 1
  pcamera.fog.color = rgb(0, 0, 0)
  pcamera.fog.near = -2300.0
  pcamera.fog.far = 1000.0
  pcamera.fog.decayMode = #linear
  SetupReflectionModels()
  return me
end

on enterFrame me
  pcamera.transform = pTargetCamera.transform
  pcamera.transform.position = pMember.model(gSelectedCar & "Proxy").transform.position
  pcamera.transform.position.x = pcamera.transform.position.x * -1
  pcamera.transform.rotation = pcamera.transform.rotation + vector(0, 0, 180)
  pcamera.transform.rotation.z = pcamera.transform.rotation.z * -1
  pcamera.transform.rotation.x = 180 - pTargetCamera.transform.rotation.x
  pStageImage = gStageImage.crop(sprite(pSpriteNr).rect)
  pMember.texture(pTextureName).image = pStageImage
end

on SetupReflectionModels me
  puppetSprite(pSpriteNr, 1)
  pSprite = sprite(pSpriteNr)
  pSprite.member = pReflMember
  pSprite.width = pTextureSize
  pSprite.height = pTextureSize
  if pDebug = 0 then
    pSprite.loc = pSpriteLoc
  end if
  if pDebug = 1 then
    pSprite.loc = pSpriteDebugLoc
  end if
  pModelList = value(member(gSelectedTrack & "Data").text)[#reflectionmodels]
  pGroup = pReflMember.newGroup("ReflGroup")
  pCount = pModelList.count
  repeat with i = 1 to pCount
    pModelName = pModelList[i]
    CLONEMODELS(pReflMember.name, [#cloneMember: pMember, #modelList: [pModelList[i]]])
    pReflMember.model(pModelList[i]).parent = pGroup
  end repeat
  repeat with k = 1 to pCount
    pReflMember.modelResource(pModelList[k]).lod.auto = 0
    pReflMember.modelResource(pModelList[k]).lod.bias = 100
    pReflMember.modelResource(pModelList[k]).lod.level = 100
    pReflMember.model(pModelList[k]).addModifier(#meshDeform)
  end repeat
  pGroup.transform.scale = vector(-1, 1, 1)
  pGroup.removeFromWorld()
  pcamera.rootNode = pGroup
  pcamera.fieldOfView = pCamFov
  pMember.shader(gSelectedCar & "_material").blendFunctionList[2] = #add
end
