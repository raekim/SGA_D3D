#include "000_Header.fx"

//-----------------------------------------------------------------------------
// VertexShader
//-----------------------------------------------------------------------------
struct VertexInput
{
    float4 Position : POSITION0;
    float2 UV : UV0;
};

struct VertexOuput
{
    float4 Position : SV_POSITION;
    float2 UV : UV0;
};

VertexOuput VS(VertexInput input)
{
    VertexOuput output;

    output.Position = mul(input.Position, World);
    output.Position = mul(output.Position, View);
    output.Position = mul(output.Position, Projection);

    output.UV = input.UV;

    return output;
}

//-----------------------------------------------------------------------------
// PixelShader
//-----------------------------------------------------------------------------
float4 PS(VertexOuput input) : SV_TARGET
{
    return float4(1, 0, 0, 1);
}

//-----------------------------------------------------------------------------
// Technique
//-----------------------------------------------------------------------------
technique11 T0
{
    pass P0
    {
        SetVertexShader(CompileShader(vs_5_0, VS()));
        SetPixelShader(CompileShader(ps_5_0, PS()));
    }
}