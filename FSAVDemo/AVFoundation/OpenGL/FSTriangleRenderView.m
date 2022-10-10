//
//  FSTriangleRenderView.m
//  FSAVDemo
//
//  Created by louis on 2022/10/10.
//

#import "FSTriangleRenderView.h"
#import <OpenGLES/ES2/gl.h>

// 定义顶点的数据结构：包括顶点坐标和颜色维度。
#define PositionDimension 3 // 顶点坐标
#define ColorDimension 4    // 颜色维度
typedef struct {
    GLfloat position[PositionDimension]; // { x, y, z }
    GLfloat color[ColorDimension]; // {r, g, b, a}
} SceneVertex;

@interface FSTriangleRenderView ()

@property (nonatomic, assign) GLsizei width;
@property (nonatomic, assign) GLsizei height;

@property (nonatomic, strong) CAEAGLLayer *eaglLayer;
@property (nonatomic, strong) EAGLContext *eaglContext;

@property (nonatomic, assign) GLuint simpleProgram;

@property (nonatomic, assign) GLuint renderBuffer;
@property (nonatomic, assign) GLuint frameBuffer;

@end

@implementation FSTriangleRenderView

#pragma mark - init

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _width = frame.size.width;
        _height = frame.size.height;
        [self render];
    }
    return self;
}

#pragma mark - Action

- (void)render {
    // 1.设置 layer 类型
    _eaglLayer = (CAEAGLLayer *)self.layer;
    _eaglLayer.opacity = 1.0;
    _eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking: @(NO),
                                      kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};
    
    // 2.创建 OpenGL 上下文
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2; // 使用 OpenGL API 的版本
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:api];
    if (!context) {
        NSLog(@"Create context failed!");
        return;
    }
    // 设置当前上下文
    BOOL r = [EAGLContext setCurrentContext:context];
    if (!r) {
        NSLog(@"setCurrentContext failed!");
        return;
    }
    _eaglContext = context;
    
    // 3.申请并绑定渲染缓冲区对象 RBO 用来存储即将绘制到屏幕上的图像数据
    glGenRenderbuffers(1, &_renderBuffer); // 创建 RBO
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer); // 绑定 RBO 到 OpenGL 渲染管线
    [_eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer]; // 将渲染图层（_eaglLayer）的存储绑定到 RBO
    
    // 4.申请并绑定帧缓冲区对象 FBO; FBO 本身不能用于渲染，只有绑定了纹理（Texture）或者渲染缓冲区（RBO）等作为附件之后才能作为渲染目标
    glGenFramebuffers(1, &_frameBuffer); // 创建 FBO
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer); // 绑定 FBO 到 OpenGL 渲染管线
    // 将 RBO 绑定为 FBO 的一个附件，绑定后，OpenGL 对 FBO 的绘制会同步到 RBO 后再上屏
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    
    // 5.清理窗口颜色，并设置渲染窗口
    glClearColor(0.5, 0.5, 0.5, 1.0); // 设置渲染窗口颜色; 这里是灰色
    glClear(GL_COLOR_BUFFER_BIT); // 清空旧渲染缓存
    glViewport(0, 0, _width, _height); // 设置渲染窗口区域
    
    // 6.加载和编译 shader，并链接到着色器程序
    
    // 7.根据三角形顶点信息申请顶点缓冲区对象 VBO 和拷贝顶点数据
    
    // 8.绘制三角形
    
    // 9.关闭 | 解绑
    
}

#pragma mark - Utility

#pragma mark - Override

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

@end
