property pShadowMember, pTrackMember, pSpriteNr, pSpriteLoc, pSpriteDebugLoc, pTag, pOffset, pCamFov, pTextureSize, pShadowSize, pTextureName, pBlend, pcolor, pBlur, pDebug, pShadow, pShadowCamera, pTrackCamera, pCamInvMTX, pCamOrigin2D, pt, pStageImage, pimage, pAlpha
global gStageImage, gSelectedCar, gSelectedTrack, gRayCastList

on new me, pParams
  pShadowMember = pParams[#shadowMember]
  pTrackMember = pParams[#trackMember]
  pSpriteNr = pParams[#spritechannel]
  pSpriteLoc = pParams[#spriteLoc]
  pSpriteDebugLoc = pParams[#spriteDebugLoc]
  pTag = pParams[#tag]
  pOffset = pParams[#CamOffSet]
  pCamFov = pParams[#camfov]
  pTextureSize = pParams[#textureSize]
  pShadowSize = pParams[#ShadowSize]
  pTextureName = pParams[#TextureName]
  pBlend = pParams[#blend]
  pcolor = pParams[#color]
  pBlur = pParams[#blur]
  pDebug = pParams[#debug]
  if (pShadowMember = VOID) or (pTrackMember = VOID) then
    exit
  end if
  if pSpriteNr = VOID then
    pSpriteNr = 11
  end if
  if pTag = VOID then
    pTag = #standard
  end if
  if pOffset = VOID then
    pOffset = vector(100, 100, 100)
  end if
  if pCamFov = VOID then
    pCamFov = 55.0
  end if
  if pTextureSize = VOID then
    pTextureSize = 128
  end if
  if pShadowSize = VOID then
    pShadowSize = [1, 1]
  end if
  if pTextureName = VOID then
    pTextureName = "CarShadow_Texture"
  end if
  if pBlend = VOID then
    pBlend = 80
  end if
  if pcolor = VOID then
    pcolor = rgb(0, 0, 0)
  end if
  if pBlur = VOID then
    pBlur = 0
  end if
  if pDebug = VOID then
    pDebug = 0
  end if
  if pSpriteLoc = VOID then
    pSpriteLoc = point(pTextureSize / 2, pTextureSize / 2)
  end if
  if pSpriteDebugLoc = VOID then
    pSpriteDebugLoc = point(640 + (pTextureSize / 2), pTextureSize / 2)
  end if
  resetWorld(pShadowMember.name)
  SetupCarShadow()
  return me
end

on enterFrame me
  pShadowMember.model(gSelectedCar).transform.position = pTrackMember.model(pTag & gSelectedCar & "Proxy").transform.position
  pShadowMember.model(gSelectedCar).transform.rotation = pTrackMember.model(pTag & gSelectedCar & "Proxy").transform.rotation
  setCamera(pShadowCamera, pShadowMember)
  setCamera(pTrackCamera, pTrackMember)
  pStageImage = gStageImage.crop(sprite(pSpriteNr).rect)
  if pBlur <> 0 then
    repeat with i = 1 to pBlur
      pStageImage = blur(pStageImage)
    end repeat
  end if
  pAlpha.copyPixels(pStageImage, pAlpha.rect, pStageImage.rect)
  pimage.setAlpha(pAlpha)
  pTrackMember.texture(pTextureName).image = pimage
  if gRayCastList[pTag] = [] then
    exit
  end if
  positionShadow = gRayCastList[pTag][1][#isectPosition]
  normalShadow = gRayCastList[pTag][1][#isectNormal]
  pShadow.transform.position = positionShadow + vector(0, 0, 0.025)
  pShadow.pointAtOrientation = [vector(0, 0, 1), vector(0, 1, 0)]
  pShadow.pointAt(pShadow.transform.position + normalShadow)
  pShadow.rotate(0, 0, pTrackMember.model(pTag & gSelectedCar & "Proxy").transform.rotation[3])
  SetCoordinates()
end

on SetCoordinates me
  pCamOrigin2D = point(pTrackCamera.rect.width / 2, pTrackCamera.rect.height / 2)
  pCamDist2Plane = tan(pTrackCamera.projectionAngle * (PI / 360.0))
  pCamProjDist = pCamOrigin2D[2] / pCamDist2Plane
  pCamInvMTX = pTrackCamera.transform.inverse()
  pCamInvMTX.scale(pCamProjDist, pCamProjDist, 1)
  projSize = point(pTrackCamera.rect.width * 1.0, pTrackCamera.rect.height * 1.0)
  pt = point(0, 0)
  zVector = vector(0, 0, 0)
  tm = pTrackMember.model(pTag & gSelectedCar & "ShadowCaster")
  repeat with m = 1 to tm.meshDeform.mesh.count
    vertexList = tm.meshDeform.mesh[m].vertexList
    textureCoordinateList = tm.meshDeform.mesh[m].textureLayer[1].textureCoordinateList
    t = vertexList.count
    repeat with i = 1 to t
      tp = worldSpaceToSpriteSpace((tm.transform * vertexList[i]) + zVector) / projSize
      textureCoordinateList[i][1] = (tp[1] * -1) + 1
      textureCoordinateList[i][2] = tp[2]
    end repeat
    tm.meshDeform.mesh[m].textureLayer[1].textureCoordinateList = textureCoordinateList
  end repeat
end

on worldSpaceToSpriteSpace tVect
  tEyeSp = pCamInvMTX * tVect
  pt[1] = (tEyeSp.x / tEyeSp.z) + pCamOrigin2D[1]
  pt[2] = -(tEyeSp.y / tEyeSp.z) + pCamOrigin2D[2]
  return pt
end

on blur tImg
  if ilk(tImg) <> #image then
    return VOID
  end if
  buffer = image(tImg.width, tImg.height, 32)
  myRect = rect(0, 0, tImg.width, tImg.height)
  offsetL = [[0, 0], [2, 2], [0, 2], [2, 0], [0, 1], [2, 1], [1, 0], [1, 2], [1, 1]]
  myBlend = 255 / offsetL.count * 1.69999999999999996
  repeat with j = 1 to 9
    destRect = myRect.offset(offsetL[j][1], offsetL[j][2])
    buffer.copyPixels(tImg, destRect, myRect, [#blendLevel: myBlend])
  end repeat
  return buffer
end

on SetupCarShadow me
  puppetSprite(pSpriteNr, 1)
  pSprite = sprite(pSpriteNr)
  pSprite.member = pShadowMember
  pSprite.width = pTextureSize
  pSprite.height = pTextureSize
  if pDebug = 0 then
    pSprite.loc = pSpriteLoc
  end if
  if pDebug = 1 then
    pSprite.loc = pSpriteDebugLoc
  end if
  pModelList = [gSelectedCar, gSelectedCar & "Wheel_LB", gSelectedCar & "Wheel_RB", gSelectedCar & "Wheel_RF", gSelectedCar & "Wheel_LF"]
  CLONEMODELS(pShadowMember.name, [#cloneMember: gSelectedCar, #modelList: pModelList])
  pNitroBlastList = []
  pCount = pShadowMember.model.count
  repeat with i = 1 to pCount
    pModelName = pShadowMember.model[i].name
    if pModelName contains "NitroBlast" then
      pShadowMember.model(pModelName).removeFromWorld()
    end if
  end repeat
  pWheelOffSet = member(gSelectedCar).model(gSelectedCar).transform.position.z
  repeat with j = 2 to pModelList.count
    pShadowMember.model(pModelList[j]).parent = pShadowMember.model(gSelectedCar)
    pShadowMember.model(pModelList[j]).transform.position.z = pShadowMember.model(pModelList[j]).transform.position.z - pWheelOffSet
  end repeat
  repeat with k = 1 to pModelList.count
    pShadowMember.modelResource(pModelList[k]).lod.auto = 0
    pShadowMember.modelResource(pModelList[k]).lod.bias = 100
    pShadowMember.modelResource(pModelList[k]).lod.level = 100
    pShadowMember.model(pModelList[k]).addModifier(#meshDeform)
  end repeat
  pCount = pShadowMember.shader.count
  PList = []
  repeat with l = 1 to pCount
    pShaderName = pShadowMember.shader[l].name
    PList.add(pShaderName)
  end repeat
  pListCount = PList.count
  repeat with i = 1 to pListCount
    pShadowMember.deleteShader(PList[i])
  end repeat
  pShader = pShadowMember.newShader("White_Material", #standard)
  pShader.ambient = rgb(0, 0, 0)
  pShader.diffuse = rgb(0, 0, 0)
  pShader.emissive = rgb(0, 0, 0)
  pShader.specular = rgb(0, 0, 0)
  pShader.shininess = 0.0
  pShader.textureList = VOID
  pCount = pShadowMember.model.count
  repeat with j = 1 to pCount
    pShadowMember.model[j].shaderList = pShader
  end repeat
  pimage = image(pTextureSize, pTextureSize, 32)
  pimage.fill(pimage.rect, rgb(255, 255, 255))
  pimage.useAlpha = 1
  pAlpha = image(pTextureSize, pTextureSize, 8, #grayscale)
  pAlpha.fill(pAlpha.rect, rgb(0, 0, 0))
  pShadowResource = pTrackMember.newModelResource(pTag & gSelectedCar & "ShadowCaster", #plane)
  pShadowResource.width = float(pShadowSize[1])
  pShadowResource.length = float(pShadowSize[2])
  pShadow = pTrackMember.newModel(pTag & gSelectedCar & "ShadowCaster", pShadowResource)
  pShadow.addModifier(#meshDeform)
  if pTrackMember.texture(pTextureName) = VOID then
    pTrackMember.newTexture(pTextureName)
    pTexture = pTrackMember.texture(pTextureName)
    pTexture.member = member(pTextureName)
    pTexture.quality = #lowFiltered
    pTexture.renderFormat = #rgba8888
  else
    pTexture = pTrackMember.texture(pTextureName)
  end if
  pTrackMember.newShader(pTag & gSelectedCar & "ShadowCaster_Material", #standard)
  pShader = pTrackMember.shader(pTag & gSelectedCar & "ShadowCaster_Material")
  pShader.emissive = rgb(0, 0, 0)
  pShader.shininess = 0.0
  pShader.blend = pBlend
  pShader.textureList[1] = pTexture
  pShader.textureRepeatList[1] = 0
  if pcolor <> rgb(0, 0, 0) then
    pShader.useDiffuseWithTexture = 1
    pShader.diffuse = pcolor
  end if
  pShadow.shaderList = pShader
  pShadowCamera = pShadowMember.newCamera("ShadowCam")
  pShadowCamera.rect = rect(0, 0, pTextureSize, pTextureSize)
  pShadowCamera.fieldOfView = pCamFov
  setCamera(pShadowCamera, pShadowMember)
  pSprite.camera = pShadowCamera
  pTrackCamera = member(gSelectedTrack).newCamera("LightCam")
  pTrackCamera.rect = rect(0, 0, pTextureSize, pTextureSize)
  pTrackCamera.fieldOfView = pCamFov
  setCamera(pTrackCamera, pTrackMember)
end

on setCamera tCam, tmember
  pPos = pTrackMember.model(pTag & gSelectedCar & "Proxy").transform.position + pOffset
  pPointAt = pTrackMember.model(pTag & gSelectedCar & "Proxy").transform.position
  tCam.transform.position = pPos
  tCam.pointAt(pPointAt, vector(0, 0, 1))
end
