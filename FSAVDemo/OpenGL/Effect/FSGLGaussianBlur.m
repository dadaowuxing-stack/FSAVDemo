//
//  FSGLGaussianBlur.m
//  FSAVDemo
//
//  Created by liufengshuo on 2023/4/20.
//

#import "FSGLGaussianBlur.h"

NSString *const FSGLGaussianBlurVertexShader = SHADER_STRING
(
    attribute vec4 position; // 通过 attribute 通道获取顶点信息. 4 维向量.
    attribute vec4 inputTextureCoordinate; // 通过 attribute 通道获取纹理坐标信息. 4 维向量.
    varying vec2 textureCoordinate; // 用于 vertex shader 和 fragment shader 间传递纹理坐标. 2 维向量.

    const int GAUSSIAN_SAMPLES = 9; // 被参考的点数目.
    uniform float wOffset; // 水平方向单位偏移. Offset 越大结果越模糊.
    uniform float hOffset; // 垂直方向单位偏移. Offset 越大结果越模糊.

    varying vec2 blurCoordinates[GAUSSIAN_SAMPLES]; // 被参考点的纹理坐标数组，将在 vertex shader 和 fragment shader 间传递. 2 维向量数组.

    void main()
    {
        gl_Position = position;

        textureCoordinate = inputTextureCoordinate.xy; // 将通过 attribute 通道获取的纹理坐标数据中的 2 维分量传给 fragment shader.

        int multiplier = 0;
        vec2 blurStep;
        vec2 singleStepOffset = vec2(hOffset, wOffset);

        for (int i = 0; i < GAUSSIAN_SAMPLES; i++)
        {
            multiplier = (i - ((GAUSSIAN_SAMPLES - 1) / 2)); // 每一个被参考点距离当前纹理坐标的偏移乘数
            blurStep = float(multiplier) * singleStepOffset; // 每一个被参考点距离当前纹理坐标的偏移
            blurCoordinates[i] = inputTextureCoordinate.xy + blurStep; // 每一个被参考点的纹理坐标
        }
    }
);

NSString *const FSGLGaussianBlurFragmentShader = SHADER_STRING
(
    varying highp vec2 textureCoordinate; // 从 vertex shader 传递来的纹理坐标.
    uniform sampler2D inputImageTexture; // 通过 uniform 通道获取纹理信息. 2D 纹理.

    const lowp int GAUSSIAN_SAMPLES = 9; // 被参考的点数目.

    varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES]; // 从 vertex shader 传递来的被参考点的纹理坐标数组.

    void main()
    {
        lowp vec4 sum = vec4(0.0);

        // 根据距离当前点距离远近分配权重. 分配原则越近权重越大.
        sum += texture2D(inputImageTexture, blurCoordinates[0]) * 0.05;
        sum += texture2D(inputImageTexture, blurCoordinates[1]) * 0.09;
        sum += texture2D(inputImageTexture, blurCoordinates[2]) * 0.12;
        sum += texture2D(inputImageTexture, blurCoordinates[3]) * 0.15;
        sum += texture2D(inputImageTexture, blurCoordinates[4]) * 0.18;
        sum += texture2D(inputImageTexture, blurCoordinates[5]) * 0.15;
        sum += texture2D(inputImageTexture, blurCoordinates[6]) * 0.12;
        sum += texture2D(inputImageTexture, blurCoordinates[7]) * 0.09;
        sum += texture2D(inputImageTexture, blurCoordinates[8]) * 0.05;

        // 加权. 
        gl_FragColor = sum;
    }
);
