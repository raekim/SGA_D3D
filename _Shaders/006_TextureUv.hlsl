cbuffer VS_ViewProjection : register(b0)
{
    matrix _view;
    matrix _projection;
}

cbuffer VS_World : register(b1)
{
    matrix _world;
}

cbuffer PS_Color : register(b0)
{
    float4 Color;
}

struct VertexInput
{
    float4 position : POSITION0;
    float2 uv : UV0;
};

struct PixelInput
{
    float4 position : SV_POSITION;
    float2 uv : UV0;
};

SamplerState Sampler : register(s0);
Texture2D Map : register(t0);
Texture2D Map2 : register(t1);

PixelInput VS(VertexInput input)
{
    PixelInput output;

    input.position.w = 1.0f;

    output.position = mul(input.position, _world);
    output.position = mul(output.position, _view);
    output.position = mul(output.position, _projection);

    output.uv = input.uv;

    return output;
}

float4 PS(PixelInput input) : SV_TARGET
{
    float4 color = Map.Sample(Sampler, input.uv);

    float x = input.uv.x;
    if(x < 0.5f)
        color = Map2.Sample(Sampler, input.uv);

    return color;
}