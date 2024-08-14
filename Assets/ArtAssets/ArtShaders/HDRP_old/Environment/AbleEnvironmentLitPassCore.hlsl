#ifndef ABLE_ENVIRONMENT_FORWARD_LIT_PASS_CORE_INCLUDED
#define ABLE_ENVIRONMENT_FORWARD_LIT_PASS_CORE_INCLUDED

#include "./AbleEnviornmentLighting.hlsl"

float GetUseGroundTextureRateValue(float targetValue, float checkFactor, float feather)
{
    float minFeather = checkFactor - feather;
    half useOnlyGroundTexture = step(targetValue, minFeather);
    half noUseGroundTexture = step(checkFactor, targetValue);
    return lerp(lerp(1.0 - LinearStep(minFeather, checkFactor, targetValue), 0.0f, noUseGroundTexture), 1.0f, useOnlyGroundTexture);
}

half3 CalculateFinalDiffuseByGroundTexture(InputData inputData, SurfaceData surfaceData, float3 positionWS, half3 diffuse, half2 baseUv)
{
    half positionY = positionWS.y - _GroundWorldPositionY;
#if _USE_TERRAIN_GROUND_TEXTURE
    float2 uv = TRANSFORM_TEX(baseUv, _GroundTextureTerrainMap);
    half3 groundTextureAlbedo = SAMPLE_TEXTURE2D(_GroundTextureTerrainMap, sampler_GroundTextureTerrainMap, uv).rgb * _GroundTextureCustomBright;
#else
    float2 uv = float2((positionWS.x % 1), (positionWS.z % 1));
    half3 groundTextureAlbedo = SAMPLE_TEXTURE2D(_GroundTextureMap, sampler_GroundTextureMap, uv).rgb * _GroundTextureCustomBright;
#endif

    float useGroundTextureRate = GetUseGroundTextureRateValue(positionY, _GroundInteractionHeight, _GroundInteractionFeather);
    half3 finalDiffuse = lerp(diffuse, groundTextureAlbedo, useGroundTextureRate);
    return finalDiffuse;
}

half3 CalculateFinalDiffuseByGroundTextureUseVertextColor(float vertexColor, float3 positionWS, half3 diffuse)
{
    float2 uv = float2((positionWS.x % 1), (positionWS.z % 1));
#if _USE_TERRAIN_GROUND_TEXTURE
    half3 groundTextureAlbedo = SAMPLE_TEXTURE2D(_GroundTextureTerrainMap, sampler_GroundTextureTerrainMap, TRANSFORM_TEX(uv, _GroundTextureTerrainMap)).rgb  * _GroundTextureCustomBright;
#else
    half3 groundTextureAlbedo = SAMPLE_TEXTURE2D(_GroundTextureMap, sampler_GroundTextureMap, TRANSFORM_TEX(uv, _GroundTextureMap)).rgb * _GroundTextureCustomBright;
#endif
    half3 finalDiffuse = lerp(groundTextureAlbedo, diffuse, vertexColor);
    return finalDiffuse;
}

half3 CalculateFinalDiffuseByGroundTextureMaskMap(float2 uv, float3 positionWS, half3 diffuse)
{
    float2 groundUv = float2((positionWS.x % 1), (positionWS.z % 1)) * uv;
    half4 subTextureAlbedo = SAMPLE_TEXTURE2D(_GroundTextureMaskMap, sampler_GroundTextureMaskMap, uv);
#if _USE_TERRAIN_GROUND_TEXTURE
    half3 groundTextureAlbedo = SAMPLE_TEXTURE2D(_GroundTextureTerrainMap, sampler_GroundTextureTerrainMap, TRANSFORM_TEX(uv, _GroundTextureTerrainMap)).rgb  * _GroundTextureCustomBright;
#else
    half3 groundTextureAlbedo = SAMPLE_TEXTURE2D(_GroundTextureMap, sampler_GroundTextureMap, TRANSFORM_TEX(uv, _GroundTextureMap)).rgb * _GroundTextureCustomBright;
#endif

    half groundTextureMaskMap = SAMPLE_TEXTURE2D(_GroundTextureMaskMap, sampler_GroundTextureMaskMap, uv).r;
    half3 finalDiffuse = lerp(diffuse, groundTextureAlbedo, groundTextureMaskMap);
    return finalDiffuse;
}

half3 GetAppliedGroundTextureDiffuseForUsingGrountInteraction(InputData inputData, SurfaceData surfaceData, float2 uv, float3 positionWS, half3 diffuse)
{
#if _USE_GROUND_TEXTURE_MASK
    return CalculateFinalDiffuseByGroundTextureMaskMap(uv, positionWS, diffuse);
#else
    return CalculateFinalDiffuseByGroundTexture(inputData, surfaceData, positionWS, diffuse, uv);
#endif
}

half3 GetAppliedGroundTextureDiffuse(InputData inputData, SurfaceData surfaceData, float2 uv, float3 positionWS, half3 diffuse)
{
#if _USE_GROUND_INTERACTIVE
    return GetAppliedGroundTextureDiffuseForUsingGrountInteraction(inputData, surfaceData, uv, positionWS, diffuse);
#else
    return diffuse;
#endif
}


half4 AbleEnvironmentPBR(InputData inputData, SurfaceData surfaceData, BRDFData brdfData, float2 uv, float3 positionWS, half setLinear = 0, half shadowPowFactor = 1,
 half3 shadowColor = 0, half3 shadowBoundaryColor = half3(1, 0, 0))
{
    #if defined(_SPECULARHIGHLIGHTS_OFF)
    bool specularHighlightsOff = true;
    #else
    bool specularHighlightsOff = false;
    #endif

    brdfData.diffuse = GetAppliedGroundTextureDiffuse(inputData, surfaceData, uv, positionWS, brdfData.diffuse);

    #if defined(DEBUG_DISPLAY)
    half4 debugColor;

    if (CanDebugOverrideOutputColor(inputData, surfaceData, brdfData, debugColor))
    {
        return debugColor;
    }
    #endif

    // Clear-coat calculation...
    BRDFData brdfDataClearCoat = CreateClearCoatBRDFData(surfaceData, brdfData);
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    half addAOFactor = step(aoFactor.indirectAmbientOcclusion, 0.8);
    aoFactor.indirectAmbientOcclusion -= lerp(0, _AOPowerFactor2, addAOFactor);
    uint meshRenderingLayers = GetMeshRenderingLightLayer();
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);
    //half addShadowFactor = step(mainLight.shadowAttenuation, 0.8);
    //mainLight.shadowAttenuation  -= lerp(0, _ShadowPowerFactor2, addShadowFactor);//= pow(mainLight.shadowAttenuation, _ShadowPowerFactor);
    // NOTE: We don't apply AO to the GI here because it's done in the lighting calculation below...
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

    LightingData lightingData = CreateLightingData(inputData, surfaceData);

    lightingData.giColor = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                                              inputData.bakedGI, aoFactor.indirectAmbientOcclusion, inputData.positionWS,
                                              inputData.normalWS, inputData.viewDirectionWS);

    if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
    {
        lightingData.mainLightColor = LightingEnvLitCorePhysicallyBased(brdfData, brdfDataClearCoat,
                                                                                    mainLight,
                                                                                    inputData.normalWS, inputData.viewDirectionWS,
                                                                                    surfaceData.clearCoatMask, specularHighlightsOff,
                                                                                    _ShadowPowerFactor2, setLinear,
                                                                                    shadowPowFactor, shadowColor, shadowBoundaryColor);
    }

    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    #if USE_CLUSTERED_LIGHTING
    for (uint lightIndex = 0; lightIndex < min(_AdditionalLightsDirectionalCount, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
        {
            lightingData.additionalLightsColor += LightingEnvLitCorePhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                                                inputData.normalWS, inputData.viewDirectionWS,
                                                                                                surfaceData.clearCoatMask, specularHighlightsOff,
                                                                                                _ShadowPowerFactor2, setLinear,
                                                                                                shadowPowFactor);
        }
    }
    #endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
        {
            lightingData.additionalLightsColor += LightingEnvLitCorePhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                                                inputData.normalWS, inputData.viewDirectionWS,
                                                                                                surfaceData.clearCoatMask, specularHighlightsOff,
                                                                                                _ShadowPowerFactor2, setLinear,
                                                                                                shadowPowFactor);
        }
    LIGHT_LOOP_END
    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
    lightingData.vertexLightingColor += inputData.vertexLighting * brdfData.diffuse;
    #endif

    //lightingData.vertexLightingColor = pow(lightingData.vertexLightingColor, _ShadePowerFactor);

    return CalculateEnvLitCoreFinalColor(lightingData, surfaceData.alpha);
}

//half4 AbleEnvironmentPBR(InputData inputData, SurfaceData surfaceData, BRDFData brdfData, float2 uv, float3 positionWS,
//half3 shadowColor = 0, half3 shadowBoundaryColor = half3(1, 0, 0))
//{
//    return AbleEnvironmentPBR(inputData, surfaceData, brdfData, uv, positionWS, 0, 1, shadowColor, shadowBoundaryColor);
//}

#endif

