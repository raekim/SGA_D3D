#include "000_Header2.hlsl"

struct VertexOutput
{
    float4 Position : SV_POSITION;
    float2 Uv : UV0;
};

VertexOutput VS(VertexTexture input)
{
    VertexOutput output;

    output.Position = mul(input.Position, World);
    output.Position = mul(output.Position, View);
    output.Position = mul(output.Position, Projection);

    output.Uv = input.Uv;

    return output;
}

///////////////////////////////////////////////////////////////////////////////

struct GeometryOutput
{
    float4 Position : SV_POSITION;
    float3 wPosition : POSITION0;
    float2 Uv : UV0;
    float Fog : FOG0;
};

void SubDivide(VertexOutput vertices[3], out VertexOutput outVertices[6])
{
    VertexOutput m[3];

    m[0].Position = 0.5f * (vertices[0].Position + vertices[1].Position);
    m[1].Position = 0.5f * (vertices[1].Position + vertices[2].Position);
    m[2].Position = 0.5f * (vertices[2].Position + vertices[0].Position);

    m[0].Position = normalize(m[0].Position);
    m[1].Position = normalize(m[1].Position);
    m[2].Position = normalize(m[2].Position);

    m[0].Uv = 0.5f * (vertices[0].Uv + vertices[1].Uv);
    m[1].Uv = 0.5f * (vertices[1].Uv + vertices[2].Uv);
    m[2].Uv = 0.5f * (vertices[2].Uv + vertices[0].Uv);

    outVertices[0] = vertices[0];
    outVertices[1] = m[0];
    outVertices[2] = m[2];
    outVertices[3] = m[1];
    outVertices[4] = vertices[2];
    outVertices[5] = vertices[1];
}

void OutputSubdivision(VertexOutput v[6], inout TriangleStream<GeometryOutput> stream)
{
    GeometryOutput output[6];

    [unroll]
    for (int i = 0; i < 6; i++)
    {
        output[i].wPosition = mul(v[i].Position, World).xyz;

        float4 position = 0;
        position = mul(v[i].Position, World);
        position = mul(position, View);
        position = mul(position, Projection);

        output[i].Position = position;

        output[i].Uv = v[i].Uv;
    }

    [unroll]
    for (int j = 0; j < 5; j++)
    {
        GeometryOutput o = output[j];
        stream.Append(o);
    }
        

    stream.RestartStrip();

    stream.Append(output[1]);
    stream.Append(output[5]);
    stream.Append(output[3]);
}

[maxvertexcount(8)]
void GS(triangle VertexOutput gin[3], inout TriangleStream<GeometryOutput> stream)
{
    VertexOutput v[6];
    SubDivide(gin, v);
    OutputSubdivision(v, stream);
}

///////////////////////////////////////////////////////////////////////////////

float4 PS(VertexOutput input) : SV_TARGET
{
    return float4(1, 0, 0, 1);
}