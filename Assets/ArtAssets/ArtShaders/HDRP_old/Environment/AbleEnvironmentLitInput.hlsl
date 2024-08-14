#ifndef ABLE_ENVIRONMENT_LIT_INPUT_INCLUDED
#define ABLE_ENVIRONMENT_LIT_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"

#if defined(_DETAIL_MULX2) || defined(_DETAIL_SCALED)
#define _DETAIL
#endif


// NOTE: Do not ifdef the properties here as SRP batcher can not handle different layouts.
CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
float4 _DetailAlbedoMap_ST;
float4 _GroundTextureMap_ST;
float4 _GroundTextureTerrainMap_ST;
half4 _BaseColor;
half4 _SpecColor;
half4 _ShadowColor;
half4 _ShadowBoundaryColor;
half4 _EmissionColor;
half4 _DetailTint;
half _Cutoff;
half _BumpScale;
half _ReverseBump;
half _Parallax;
half _ClearCoatMask;
half _ClearCoatSmoothness;
half _DetailAlbedoMapScale;
half _DetailNormalMapScale;
half _Surface;
half _CustomOcclusion;
half _CustomSmoothness;
half _CustomMetal;
half _CustomEmissive;
half _CustomBright;
half _UseGroundInteraction;
half _UseTerrainGroundTexture;
half _GroundWorldPositionY;
half _GroundInteractionHeight;
half _GroundInteractionFeather;
half _UseGroundTextureMaskMap;
half _UseVertexColorTexture;
float _AOPowerFactor2;
float _ShadowPowerFactor;
half _ShadowPowerUseLinear;
float _ShadowPowerFactor2;
half _ShadowPowerUsePow;
float _ShadowPowerPowFactor;
half4 _VertexColorTextureTint;
half _VertexColorTextureBright;
half4 _SecondVertexColorTextureTint;
half _SecondVertexColorTextureBright;
half _VertexColorTextureAreaFactor;
float _VertexColorTextureAreaFeather;
half _VertexColorTextureAreaNoiseFeather;
half _VertexColorTextureNoiseHandler;
half _GroundTextureCustomBright;
CBUFFER_END

// NOTE: Do not ifdef the properties for dots instancing, but ifdef the actual usage.
// Otherwise you might break CPU-side as property constant-buffer offsets change per variant.
// NOTE: Dots instancing is orthogonal to the constant buffer above.
#ifdef UNITY_DOTS_INSTANCING_ENABLED
UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
    UNITY_DOTS_INSTANCED_PROP(float4, _BaseColor)
    UNITY_DOTS_INSTANCED_PROP(float4, _SpecColor)
UNITY_DOTS_INSTANCED_PROP(float4, _ShadowColor)
UNITY_DOTS_INSTANCED_PROP(float4, _ShadowBoundaryColor)
    UNITY_DOTS_INSTANCED_PROP(float4, _EmissionColor)
    UNITY_DOTS_INSTANCED_PROP(float4, _DetailTint)
    UNITY_DOTS_INSTANCED_PROP(float , _Cutoff)
    UNITY_DOTS_INSTANCED_PROP(float , _BumpScale)
    UNITY_DOTS_INSTANCED_PROP(float , _Parallax)
    UNITY_DOTS_INSTANCED_PROP(float , _ClearCoatMask)
    UNITY_DOTS_INSTANCED_PROP(float , _ClearCoatSmoothness)
    UNITY_DOTS_INSTANCED_PROP(float , _DetailAlbedoMapScale)
    UNITY_DOTS_INSTANCED_PROP(float , _DetailNormalMapScale)
    UNITY_DOTS_INSTANCED_PROP(float , _Surface)
UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)

#define _BaseColor              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata_BaseColor)
#define _SpecColor              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata_SpecColor)
#define _ShadowColor              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata_ShadowColor)
#define _ShadowBoundaryColor              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata_ShadowBoundaryColor)
#define _EmissionColor          UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata_EmissionColor)
#define _DetailTint          UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , _DetailTint)
#define _Cutoff                 UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_Cutoff)
#define _BumpScale              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_BumpScale)
#define _Parallax               UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_Parallax)
#define _ClearCoatMask          UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_ClearCoatMask)
#define _ClearCoatSmoothness    UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_ClearCoatSmoothness)
#define _DetailAlbedoMapScale   UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_DetailAlbedoMapScale)
#define _DetailNormalMapScale   UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_DetailNormalMapScale)
#define _Surface                UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_Surface)
#endif

TEXTURE2D(_ParallaxMap);                    SAMPLER(sampler_ParallaxMap);
TEXTURE2D(_SurfaceOptionMap);               SAMPLER(sampler_SurfaceOptionMap);
TEXTURE2D(_DetailMask);                     SAMPLER(sampler_DetailMask);
TEXTURE2D(_DetailAlbedoMap);                SAMPLER(sampler_DetailAlbedoMap);
TEXTURE2D(_DetailNormalMap);                SAMPLER(sampler_DetailNormalMap);
TEXTURE2D(_GroundTextureMap);               SAMPLER(sampler_GroundTextureMap);
TEXTURE2D(_GroundTextureTerrainMap);        SAMPLER(sampler_GroundTextureTerrainMap);
TEXTURE2D(_GroundTextureMaskMap);           SAMPLER(sampler_GroundTextureMaskMap);
TEXTURE2D(_SpecGlossMap);                   SAMPLER(sampler_SpecGlossMap);
TEXTURE2D(_ClearCoatMap);                   SAMPLER(sampler_ClearCoatMap);
TEXTURE2D(_VertexColorTextureMap);          SAMPLER(sampler_VertexColorTextureMap);
TEXTURE2D(_SecondVertexColorTextureMap);    SAMPLER(sampler_SecondVertexColorTextureMap);

#ifdef _SPECULAR_SETUP
    #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_SpecGlossMap, sampler_SpecGlossMap, uv)
#else
    #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_SurfaceOptionMap, sampler_SurfaceOptionMap, uv)
#endif

half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha)
{
    half4 specGloss;
    half4 optionMap = SAMPLE_TEXTURE2D(_SurfaceOptionMap, sampler_SurfaceOptionMap, uv);
    half smoothness = (1 - optionMap.g) * _CustomSmoothness;
#if _SPECULAR_SETUP
    specGloss = SAMPLE_TEXTURE2D(_SpecGlossMap, sampler_SpecGlossMap, uv);
#else
    specGloss = optionMap;
    specGloss.rgb = optionMap.bbb * _CustomMetal;
#endif

#ifdef _METALLICSPECGLOSSMAP
    #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        specGloss.a = albedoAlpha * smoothness;
    #else
        specGloss.a = smoothness;
    #endif
#else // _METALLICSPECGLOSSMAP
    #if _SPECULAR_SETUP
        specGloss.rgb = _SpecColor.rgb;
    #endif

    #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        specGloss.a = albedoAlpha * smoothness;
    #else
        specGloss.a = smoothness;
    #endif
#endif

    return specGloss;
}

half SampleOcclusion(float2 uv)
{
    #ifdef _OCCLUSIONMAP
        // TODO: Controls things like these by exposing SHADER_QUALITY levels (low, medium, high)
        #if defined(SHADER_API_GLES)
            return SAMPLE_TEXTURE2D(_SurfaceOptionMap, sampler_SurfaceOptionMap, uv).r * _CustomOcclusion;
        #else
            half occ = SAMPLE_TEXTURE2D(_SurfaceOptionMap, sampler_SurfaceOptionMap, uv).r * _CustomOcclusion;
            return occ;
            //return LerpWhiteTo(occ, _OcclusionStrength);
        #endif
    #else
        return half(1.0);
    #endif
}


// Returns clear coat parameters
// .x/.r == mask
// .y/.g == smoothness
half2 SampleClearCoat(float2 uv)
{
#if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
    half2 clearCoatMaskSmoothness = half2(_ClearCoatMask, _ClearCoatSmoothness);

#if defined(_CLEARCOATMAP)
    clearCoatMaskSmoothness *= SAMPLE_TEXTURE2D(_ClearCoatMap, sampler_ClearCoatMap, uv).rg;
#endif

    return clearCoatMaskSmoothness;
#else
    return half2(0.0, 1.0);
#endif  // _CLEARCOAT
}

void ApplyPerPixelDisplacement(half3 viewDirTS, inout float2 uv)
{
#if defined(_PARALLAXMAP)
    uv += ParallaxMapping(TEXTURE2D_ARGS(_ParallaxMap, sampler_ParallaxMap), viewDirTS, _Parallax, uv);
#endif
}

// Used for scaling detail albedo. Main features:
// - Depending if detailAlbedo brightens or darkens, scale magnifies effect.
// - No effect is applied if detailAlbedo is 0.5.
half3 ScaleDetailAlbedo(half3 detailAlbedo, half scale)
{
    // detailAlbedo = detailAlbedo * 2.0h - 1.0h;
    // detailAlbedo *= _DetailAlbedoMapScale;
    // detailAlbedo = detailAlbedo * 0.5h + 0.5h;
    // return detailAlbedo * 2.0f;

    // A bit more optimized
    return half(2.0) * detailAlbedo * scale - scale + half(1.0);
}

half3 SampleAbleEnvironmentEmission(float2 uv, half3 emissionColor)
{
#ifndef _EMISSION
    return 0;
#else
    return SAMPLE_TEXTURE2D(_SurfaceOptionMap, sampler_SurfaceOptionMap, uv).a * _CustomEmissive * emissionColor;
#endif
}

half3 ApplyDetailAlbedo(float2 detailUv, half3 albedo, half detailMask)
{
#if defined(_DETAIL_MULX2)
    half3 detailAlbedo = SAMPLE_TEXTURE2D(_DetailAlbedoMap, sampler_DetailAlbedoMap, detailUv).rgb;

    // In order to have same performance as builtin, we do scaling only if scale is not 1.0 (Scaled version has 6 additional instructions)
#if defined(_DETAIL_SCALED)
    detailAlbedo = ScaleDetailAlbedo(detailAlbedo, _DetailAlbedoMapScale);
#else
    detailAlbedo = half(2.0) * detailAlbedo;
#endif
#if defined(_DETAIL_ALBEDO_REPLACE)
    return lerp(albedo ,detailAlbedo * _DetailTint.rgb, detailMask * _DetailTint.a);
#else
    return albedo * LerpWhiteTo(detailAlbedo * _DetailTint.rgb , detailMask * _DetailTint.a);
#endif
#else
    return albedo;
#endif
}

half3 ApplyDetailNormal(float2 detailUv, half3 normalTS, half detailMask)
{
#if defined(_DETAIL_MULX2)
//#if BUMP_SCALE_NOT_SUPPORTED
//    half3 detailNormalTS = UnpackNormal(SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, detailUv));
//#else
//    half3 detailNormalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, detailUv), _DetailNormalMapScale);
//#endif

    half3 baseNormalTS = SampleNormal(detailUv, TEXTURE2D_ARGS(_DetailNormalMap, sampler_DetailNormalMap), 1);
    half reverseNormal = 1.0 - step(_ReverseBump, 0);
    float normalG = lerp(baseNormalTS.g, -baseNormalTS.g, reverseNormal);
    half3 detailNormalTS = SafeNormalize(half3(baseNormalTS.r * _DetailNormalMapScale, normalG * _DetailNormalMapScale, baseNormalTS.b));

    return lerp(normalTS, BlendNormalRNM(normalTS, detailNormalTS), detailMask); // todo: detailMask should lerp the angle of the quaternion rotation, not the normals
#else
    return normalTS;
#endif
}

inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

    half4 specGloss = SampleMetallicSpecGloss(uv, albedoAlpha.a);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

#if _SPECULAR_SETUP
    outSurfaceData.metallic = half(1.0);
    outSurfaceData.specular = specGloss.rgb;
#else
    outSurfaceData.metallic = saturate(specGloss.r);
    outSurfaceData.specular = half3(0.0, 0.0, 0.0);
#endif

    outSurfaceData.smoothness = specGloss.a;
    half3 baseNormal = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), 1);
    half reverseNormal = 1.0 - step(_ReverseBump, 0);
    float normalG = lerp(baseNormal.g, -baseNormal.g, reverseNormal);
    half3 setNormal = SafeNormalize(half3(baseNormal.r * _BumpScale, normalG * _BumpScale, baseNormal.b));
    outSurfaceData.normalTS = setNormal;
    //outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);

    outSurfaceData.occlusion = SampleOcclusion(uv);
    outSurfaceData.emission = SampleAbleEnvironmentEmission(uv, _EmissionColor.rgb);

#if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
    half2 clearCoat = SampleClearCoat(uv);
    outSurfaceData.clearCoatMask       = clearCoat.r;
    outSurfaceData.clearCoatSmoothness = clearCoat.g;
#else
    outSurfaceData.clearCoatMask       = half(0.0);
    outSurfaceData.clearCoatSmoothness = half(0.0);
#endif

#if defined(_DETAIL_MULX2)
    half detailMask = SAMPLE_TEXTURE2D(_DetailMask, sampler_DetailMask, uv).r;
    float2 detailUv = uv * _DetailAlbedoMap_ST.xy + _DetailAlbedoMap_ST.zw;
    outSurfaceData.albedo = ApplyDetailAlbedo(detailUv, outSurfaceData.albedo, detailMask);
    outSurfaceData.normalTS = ApplyDetailNormal(detailUv, outSurfaceData.normalTS, detailMask);
#endif
}
#endif // UNIVERSAL_INPUT_SURFACE_PBR_INCLUDED
