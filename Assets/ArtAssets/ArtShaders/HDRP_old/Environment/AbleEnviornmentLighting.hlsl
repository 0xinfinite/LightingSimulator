
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
//#include "../CharacterToonForwardPassCore.hlsl"

////////////////////////////////////////////////////////////////////////////////
/// PBR lighting...
////////////////////////////////////////////////////////////////////////////////

half3 CalculateEnvLitCoreLightingColor(LightingData lightingData, half3 albedo)
{
    half3 lightingColor = 0;

    if (IsOnlyAOLightingFeatureEnabled())
    {
        return lightingData.giColor; // Contains white + AO
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_GLOBAL_ILLUMINATION))
    {
        lightingColor += lightingData.giColor;
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_MAIN_LIGHT))
    {
        lightingColor += lightingData.mainLightColor;
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_ADDITIONAL_LIGHTS))
    {
        lightingColor += lightingData.additionalLightsColor;
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_VERTEX_LIGHTING))
    {
        lightingColor += lightingData.vertexLightingColor;
    }

    lightingColor *= albedo;

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_EMISSION))
    {
        lightingColor += lightingData.emissionColor;
    }

    return lightingColor;
}

half4 CalculateEnvLitCoreFinalColor(LightingData lightingData, half alpha)
{
    half3 finalColor = CalculateEnvLitCoreLightingColor(lightingData, 1);

    return half4(finalColor, alpha);
}

half4 CalculateEnvLitCoreFinalColor(LightingData lightingData, half3 albedo, half alpha, float fogCoord)
{
#if defined(_FOG_FRAGMENT)
#if (defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2))
    float viewZ = -fogCoord;
    float nearToFarZ = max(viewZ - _ProjectionParams.y, 0);
    half fogFactor = ComputeFogFactorZ0ToFar(nearToFarZ);
#else
    half fogFactor = 0;
#endif
#else
    half fogFactor = fogCoord;
#endif
    half3 lightingColor = CalculateEnvLitCoreLightingColor(lightingData, albedo);
    half3 finalColor = MixFog(lightingColor, fogFactor);
    return half4(finalColor, alpha);
}

half3 LightingEnvLitCorePhysicallyBased(BRDFData brdfData, BRDFData brdfDataClearCoat,
    half3 lightColor, half3 lightDirectionWS, half lightAttenuation,
    half3 normalWS, half3 viewDirectionWS,
    half clearCoatMask, bool specularHighlightsOff,
    half shadowFactor, half setLinear,
    half shadowPowFactor, half3 shadowColor = 0, half3 shadowBoundaryColor = half3(1, 0, 0))
{
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half shadowValue = lightAttenuation * NdotL;
    
    half shadowRate = 1 - saturate(shadowValue);
    half passSetShadow = step(1, shadowValue);
    half reverseShadowValueLinear = lerp(shadowFactor, 0, passSetShadow);
    half reverseShadowValueRate = lerp(0, shadowFactor, shadowRate);
    half reverseShadowValue = lerp(reverseShadowValueRate, reverseShadowValueLinear, setLinear);
    
#if defined(_USE_SHADOWCOLOR)
    half3 finalShadowValue = lerp( 
    lerp(shadowColor, shadowBoundaryColor,saturate((shadowValue - reverseShadowValue)*0.5))
    ,
    1,    shadowValue - reverseShadowValue);
#else
    half finalShadowValue = shadowValue - reverseShadowValue;
#endif
    
#if defined(_USE_SHADOW_POWER_POW) && _USE_SHADOW_POWER_POW
    finalShadowValue = pow(saturate(finalShadowValue ), shadowPowFactor);
#endif

    half3 radiance = lightColor * finalShadowValue;

    half3 brdf = brdfData.diffuse;
#ifndef _SPECULARHIGHLIGHTS_OFF
    [branch]
    if (!specularHighlightsOff)
    {
        half specularValue = brdfData.specular * DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);

#if defined(_USE_SHADOW_POWER_POW) && _USE_SHADOW_POWER_POW
        specularValue = pow(saturate(specularValue), shadowPowFactor);
#else
        half specularShadowRate = 1 - saturate(specularValue);
        half specularPassSetShadow = step(1, specularValue);
        half specularReverseShadowValueLinear = lerp(shadowFactor, 0, specularPassSetShadow);
        half specularReverseShadowValueRate = lerp(0, shadowFactor, specularShadowRate);
        half specularReverseShadowValue = lerp(specularReverseShadowValueRate, specularReverseShadowValueLinear, setLinear);
        specularValue = specularValue - specularReverseShadowValue;
#endif

        //return brdfData.specular * DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);
        radiance += specularValue;
        //brdf = saturate(brdf);// lerp(half3(0, 0, 0), brdf, brdf);

#if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
        // Clear coat evaluates the specular a second timw and has some common terms with the base specular.
        // We rely on the compiler to merge these and compute them only once.
        half brdfCoat = kDielectricSpec.r * DirectBRDFSpecular(brdfDataClearCoat, normalWS, lightDirectionWS, viewDirectionWS);

            // Mix clear coat and base layer using khronos glTF recommended formula
            // https://github.com/KhronosGroup/glTF/blob/master/extensions/2.0/Khronos/KHR_materials_clearcoat/README.md
            // Use NoV for direct too instead of LoH as an optimization (NoV is light invariant).
            half NoV = saturate(dot(normalWS, viewDirectionWS));
            // Use slightly simpler fresnelTerm (Pow4 vs Pow5) as a small optimization.
            // It is matching fresnel used in the GI/Env, so should produce a consistent clear coat blend (env vs. direct)
            half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * Pow4(1.0 - NoV);

        brdf = brdf * (1.0 - clearCoatMask * coatFresnel) + brdfCoat * clearCoatMask;
#endif // _CLEARCOAT
    }
#endif // _SPECULARHIGHLIGHTS_OFF
    return brdf * radiance;
}

half3 LightingEnvLitCorePhysicallyBased(BRDFData brdfData, BRDFData brdfDataClearCoat, Light light, half3 normalWS, half3 viewDirectionWS, half clearCoatMask, bool specularHighlightsOff, half shadowFactor, half setLinear, half shadowPowFactor, half3 shadowColor = 0, half3 shadowBoundaryColor = half3(1, 0, 0))
{
    return LightingEnvLitCorePhysicallyBased(brdfData, brdfDataClearCoat, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, clearCoatMask, specularHighlightsOff, shadowFactor, setLinear, shadowPowFactor, shadowColor, shadowBoundaryColor);
}