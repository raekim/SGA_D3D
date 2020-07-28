#include "000_Header2.hlsl"

struct VertexInput
{
    float4 Position : POSITION0;
    float2 Uv : UV0;
    float3 Instance : INSTANCE0;
    uint InstanceId : SV_INSTANCEID;
};

struct VertexOutput
{
    float4 Position : SV_POSITION;
    float2 Uv : UV0;
    uint Id : INSTANCEID0;
};

VertexOutput VS(VertexInput input)
{
    VertexOutput output;

    output.Position.x = input.Position.x + input.Instance.x;
    output.Position.y = input.Position.y + input.Instance.y;
    output.Position.z = input.Position.z + input.Instance.z;
    output.Position.w = 1;

    output.Position = mul(output.Position, World);
    output.Position = mul(output.Position, View);
    output.Position = mul(output.Position, Projection);

    output.Uv = input.Uv;
    output.Id = input.InstanceId;

    return output;
}

Texture2DArray Maps : register(t10);
SamplerState Sampler : register(s10);

float4 PS(VertexOutput input) : SV_TARGET
{  
    float uvw = float3(input.Uv, input.Id % 6);
    float4 color = Maps.Sample(Sampler, uvw);
    
    return color;
}