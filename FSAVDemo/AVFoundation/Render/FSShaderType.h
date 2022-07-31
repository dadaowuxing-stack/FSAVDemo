//
//  FSShaderType.h
//  FSAVDemo
//
//  Created by louis on 2022/7/19.
//

#ifndef FSShaderType_h
#define FSShaderType_h

#include <simd/simd.h>

// 存储数据的自定义结构，用于桥接 OC 和 Metal 代码（顶点）。
typedef struct {
    // 顶点坐标，4 维向量。
    vector_float4 position;
    // 纹理坐标。
    vector_float2 textureCoordinate;
} FSVertex;

// 存储数据的自定义结构，用于桥接 OC 和 Metal 代码（顶点）。
typedef struct {
    // YUV 矩阵。
    matrix_float3x3 matrix;
    // 是否为 full range。
    bool fullRange;
} FSConvertMatrix;

// 自定义枚举，用于桥接 OC 和 Metal 代码（顶点）。
// 顶点的桥接枚举值 FSVertexInputIndexVertices。
typedef enum FSVertexInputIndex {
    FSVertexInputIndexVertices = 0,
} FSVertexInputIndex;

// 自定义枚举，用于桥接 OC 和 Metal 代码（片元）。
// YUV 矩阵的桥接枚举值 FSFragmentInputIndexMatrix。
typedef enum FSFragmentBufferIndex {
    FSFragmentInputIndexMatrix = 0,
} FSMetalFragmentBufferIndex;

// 自定义枚举，用于桥接 OC 和 Metal 代码（片元）。
// YUV 数据的桥接枚举值 FSFragmentTextureIndexTextureY、FSFragmentTextureIndexTextureUV。
typedef enum FSFragmentYUVTextureIndex {
    FSFragmentTextureIndexTextureY = 0,
    FSFragmentTextureIndexTextureUV = 1,
} FSFragmentYUVTextureIndex;

// 自定义枚举，用于桥接 OC 和 Metal 代码（片元）。
// RGBA 数据的桥接枚举值 FSFragmentTextureIndexTextureRGB。
typedef enum FSFragmentRGBTextureIndex {
    FSFragmentTextureIndexTextureRGB = 0,
} FSFragmentRGBTextureIndex;

#endif /* FSShaderType_h */
