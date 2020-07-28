#include "000_Header.hlsl"

struct PixelInput
{
    float4 Position : SV_POSITION;
    float3 Normal : NORMAL0;
    float2 Uv : UV0;
    float4 wPosition : POSITION0;
    float3 cPosition : POSITION1;
};

PixelInput VS(VertexTextureNormal input)
{
    PixelInput output;

    matrix world = BoneWorld();
    output.Position = mul(input.Position, world);
    output.wPosition = output.Position;

    output.Position = mul(output.Position, View);
    output.Position = mul(output.Position, Projection);

    output.Normal = WorldNormal(input.Normal, world);

    output.Uv = input.Uv;
    output.cPosition = CameraPosition();

    return output;
}

struct Material
{
    float3 Normal;
    float4 DiffuseColor;
    float SpecularExp;
    float SpecularIntensity;
};

cbuffer PS_Ambient : register(b10)
{
    float4 DirectionColor;

    float3 AmbientFloor;
    float PS_Ambient_Padding;

    float3 AmbientCeil;
}

cbuffer PS_Specular : register(b11)
{
    float SpecularExp;
    float SpecularIntensity;
}

cbuffer PS_Point : register(b12)
{
    float3 PointLightPosition;
    float PointLightRange;
    float4 PointLightColor;
}

cbuffer PS_Spot : register(b13)
{
    float4 SpotLightColor;

    float3 SpotLightPosition;
    float SpotLightRange;

    float3 SpotLightDirToLight;
    float SpotLightOuter;
    
    float SpotLightInner;
}

cbuffer PS_Capsule : register(b9)
{
    float4 CapsuleLightColor;

    float3 CapsuleLightPosition;
    float CapsuleLightRange;
    
    float3 CapsuleLightDirection;
    float CapsuleLightLength;
}

float3 CalcAmbient(float3 normal, float3 color)
{
    float up = normal.y * 0.5f + 0.5f;
    float3 ambient = AmbientFloor + up * AmbientCeil;

    return ambient * color;
}

float3 CalcDirectional(float3 wPosition, float3 cPosition, Material material)
{
    float d = dot(-Direction, material.Normal);
    float3 color = DirectionColor.rgb * saturate(d);

    float3 toEye = normalize(cPosition - wPosition);
    float3 halfWay = normalize(toEye + -Direction);
    float h = saturate(dot(halfWay, material.Normal));
    color += DirectionColor.rgb * pow(h, material.SpecularExp) * material.SpecularIntensity;

    return color * material.DiffuseColor.rgb;
}

float3 CalcPoint(float3 wPosition, float3 cPosition, Material material)
{
    //PointLight
    float3 toLight = PointLightPosition.xyz - wPosition;
    float distanceToLight = length(toLight);
    toLight /= distanceToLight;

    //Diffuse
    float d = dot(toLight, material.Normal);
    float3 color = PointLightColor.rgb * saturate(d);
    
    //Specular
    float3 toEye = normalize(cPosition - wPosition);
    float3 halfWay = normalize(toEye + toLight);
    float h = saturate(dot(halfWay, material.Normal));
    color += PointLightColor.rgb * pow(h, material.SpecularExp) * material.SpecularIntensity;

    //Attenuation
    float distanceToLightNormal = 1.0f - saturate(distanceToLight * 1 / PointLightRange);
    float attention = distanceToLightNormal * distanceToLightNormal;
    color *= material.DiffuseColor * attention;

    return color;
}

float3 CalcSpot(float3 wPosition, float3 cPosition, Material material)
{
    //PointLight
    float3 toLight = SpotLightPosition.xyz - wPosition;
    float distanceToLight = length(toLight);
    toLight /= distanceToLight;

    //Diffuse
    float d = dot(toLight, material.Normal);
    float3 color = SpotLightColor.rgb * saturate(d);
    
    //Specular
    float3 toEye = normalize(cPosition - wPosition);
    float3 halfWay = normalize(toEye + toLight);
    float h = saturate(dot(halfWay, material.Normal));
    color += SpotLightColor.rgb * pow(h, material.SpecularExp) * material.SpecularIntensity;


    //Attenuation
    float3 dir = -normalize(SpotLightDirToLight);
    float cosAngle = dot(dir, toLight);

    float outer = cos(radians(SpotLightOuter));
    float inner = 1.0f / cos(radians(SpotLightInner));

    float conAttention = saturate((cosAngle - outer) * inner);
    conAttention *= conAttention;

    float distanceToLightNormal = 1.0f - saturate(distanceToLight * 1 / SpotLightRange);
    float attention = distanceToLightNormal * distanceToLightNormal;
    color *= material.DiffuseColor * attention * conAttention;

    return color;
}

float3 CalcCapsule(float3 wPosition, float3 cPosition, Material material)
{
    float3 nor = normalize(CapsuleLightDirection);
    float3 start = wPosition - CapsuleLightPosition;
    float distanceOnLine = dot(start, nor) / CapsuleLightLength;
    distanceOnLine = saturate(distanceOnLine) * CapsuleLightLength;

    float3 pointOnLine = CapsuleLightPosition + nor * distanceOnLine;
    float3 toLight = pointOnLine - wPosition;
    float distanceToLight = length(toLight);

    //Diffuse
    toLight /= distanceToLight;
    float d = dot(toLight, material.Normal);
    float3 color = material.DiffuseColor.rgb * saturate(d);
    
    //Specular
    float3 toEye = normalize(cPosition - wPosition);
    float3 halfWay = normalize(toEye + toLight);
    float h = saturate(dot(halfWay, material.Normal));
    color += pow(h, material.SpecularExp) * material.SpecularIntensity;


    //Attenuation
    float distanceToLightNormal = 1.0f - saturate(distanceToLight * 1 / CapsuleLightRange);
    float attention = distanceToLightNormal * distanceToLightNormal;
    color *= CapsuleLightColor.rgb * attention;

    return color;
}

Material CreateMaterial(float3 normal, float2 uv)
{
    Material material;
    material.Normal = normalize(normal);
    
    //material.DiffuseColor = DiffuseMap.Sample(DiffuseSampler, uv);
    material.DiffuseColor = Diffuse;
    material.DiffuseColor.rgb *= material.DiffuseColor.rgb;

    material.SpecularExp = SpecularExp;
    material.SpecularIntensity = SpecularIntensity;

    return material;
}

//CapsuleLight
float4 PS(PixelInput input) : SV_TARGET
{
    Material material = CreateMaterial(input.Normal, input.Uv);
    
    float4 color = 1;
    color.rgb *= CalcCapsule(input.wPosition.xyz, input.cPosition, material);
    color.a = 1.0f;
    
    return color;
}

////SpotLight
//float4 PS(PixelInput input) : SV_TARGET
//{
//    Material material = CreateMaterial(input.Normal, input.Uv);
    
//    float4 color = 1;
//    color.rgb *= CalcSpot(input.wPosition.xyz, input.cPosition, material);
//    color.a = 1.0f;
    
//    return color;
//}

//PointLight
//float4 PS(PixelInput input) : SV_TARGET
//{
//    Material material = CreateMaterial(input.Normal, input.Uv);
    
//    float4 color = 1;
//    color.rgb *= CalcPoint(input.wPosition.xyz, input.cPosition, material);
//    color.a = 1.0f;
    
//    return color;
//}

////Directional
//float4 PS(PixelInput input) : SV_TARGET
//{
//    Material material = CreateMaterial(input.Normal, input.Uv);
    
//    float4 color = 0;
//    color.rgb = CalcAmbient(material.Normal, material.DiffuseColor.rgb);
//    color.rgb *= CalcDirectional(input.wPosition.xyz, input.cPosition, material);
//    color.a = 1.0f;
    
//    return color;
//}

////Ambient
//float4 PS(PixelInput input) : SV_TARGET
//{  
//    float3 normal = normalize(input.Normal);
//    float4 color = float4(Diffuse.rgb * Diffuse.rgb, Diffuse.a);
    
//    color.rgb = CalcAmbient(normal, color.rgb);
//    color.a = 1.0f;
    
//    return color;
//}