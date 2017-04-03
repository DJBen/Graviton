//
//  orthographic_label.metal
//  Graviton
//
//  Created by Ben Lu on 3/31/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>

struct NodeBuffer {
    float4x4 modelTransform;
    float4x4 modelViewTransform;
    float4x4 normalTransform;
    float4x4 modelViewProjectionTransform;
};

typedef struct {
    float3 position [[ attribute(SCNVertexSemanticPosition) ]];
} MyVertexInput;

struct SimpleVertex
{
    float4 position [[position]];
};

vertex SimpleVertex myVertex(MyVertexInput in [[ stage_in ]],
                             constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                             constant NodeBuffer& scn_node [[buffer(1)]])
{
    SimpleVertex vert;
    vert.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    
    return vert;
}

fragment half4 myFragment(SimpleVertex in [[stage_in]])
{
    half4 color;
    color = half4(1.0 ,0.0 ,0.0, 1.0);
    
    return color;
}
