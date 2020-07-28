#include "000_Header.hlsl"

struct PixelInput
{
    float4 Position : SV_POSITION;
    float4 dPosition : POSITION0;
};

PixelInput VS_Depth(VertexTextureNormalTangentBlend input)
{
    PixelInput output;

    matrix world = 0;
    
    [branch]
    if(UseBlend == true)
        world = SkinWorld(input.BlendIndices, input.BlendWeights);
    else
        world = BoneWorld();

    output.Position = mul(input.Position, world);
    output.Position = mul(output.Position, View);
    output.Position = mul(output.Position, Projection);

    output.dPosition = output.Position;

    return output;
}

float4 PS_Depth(PixelInput input) : SV_TARGET
{  
    float depth = input.dPosition.z / input.dPosition.w;

    return float4(depth, depth, depth, 1);
}

cbuffer VS_Light : register(b10)
{
    matrix V;
    matrix P;
}

cbuffer PS_Light : register(b10)
{
    float2 MapSize;
    float MapBias;

    int Select;
}

struct PixelInputShadow
{
    float4 Position : SV_POSITION;
    float3 Normal : NORMAL0;
    float2 Uv : UV0;
    float4 ViewPosition : LIGHTVIEW0;
};

PixelInputShadow VS_Shadow(VertexTextureNormalTangentBlend input)
{
    PixelInputShadow output;

    matrix world = 0;
    
    [branch]
    if (UseBlend == true)
        world = SkinWorld(input.BlendIndices, input.BlendWeights);
    else
        world = BoneWorld();

    output.Position = mul(input.Position, world);
    output.Position = mul(output.Position, View);
    output.Position = mul(output.Position, Projection);

    output.ViewPosition = mul(input.Position, world);
    output.ViewPosition = mul(output.ViewPosition, V);
    output.ViewPosition = mul(output.ViewPosition, P);

    output.Normal = WorldNormal(input.Normal, world);
    output.Uv = input.Uv;
    

    return output;
}


Texture2D DepthMap : register(t10);
SamplerComparisonState ShadowSampler : register(s12);

float4 PS_Shadow(PixelInputShadow input) : SV_TARGET
{
    input.ViewPosition.xyz /= input.ViewPosition.w;

    float4 color = 1;
    if (input.ViewPosition.x < -1.0f || input.ViewPosition.x > 1.0f ||
        input.ViewPosition.y < -1.0f || input.ViewPosition.y > 1.0f ||
        input.ViewPosition.z < 0.0f || input.ViewPosition.z > 1.0f)
        return color;

    input.ViewPosition.x = input.ViewPosition.x * 0.5f + 0.5f;
    input.ViewPosition.y = -input.ViewPosition.y * 0.5f + 0.5f;
    input.ViewPosition.z -= MapBias;

    float depth = 0;
    float factor = 0;

    depth = DepthMap.Sample(DiffuseSampler, input.ViewPosition.xy).r;
    factor = (float) input.ViewPosition.z <= depth;

    float4 diffuse = 0;
    DiffuseLighting(diffuse, input.Normal);
    color.rgb = diffuse * factor;

    color.a = 1.0f;
    return color;
}