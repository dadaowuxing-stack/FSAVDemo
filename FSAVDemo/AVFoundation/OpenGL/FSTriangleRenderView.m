//
//  FSTriangleRenderView.m
//  FSAVDemo
//
//  Created by louis on 2022/10/10.
//

#import "FSTriangleRenderView.h"
#import <OpenGLES/ES2/gl.h>

// 定义顶点的数据结构：包括顶点坐标和颜色维度
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
    if (_simpleProgram) {
        glDeleteProgram(_simpleProgram);
        _simpleProgram = 0;
    }
    
    /**
     创建显卡执行程序
     1.创建 Shader（着色器）
     2.创建 Program
     */
    // 加载和编译 shader
    NSString *simpleVSH = [[NSBundle mainBundle] pathForResource:@"simple" ofType:@"vsh"];
    NSString *simpleFSH = [[NSBundle mainBundle] pathForResource:@"simple" ofType:@"fsh"];
    _simpleProgram = [self loadShaderWithVertexShader:simpleVSH fragmentShader:simpleFSH];
    
    // 当顶点着色器和片元着色器都被附加到程序中之后，最后一步就是链接程序
    // 链接 shader program
    glLinkProgram(_simpleProgram);
    
    /**
     检查这个程序的状态使用 glGetProgramiv 函数
     第一个参数就是传入程序容器的句柄，
     第二个参数代表要检查这个程序的哪一个状态，这里面传入 GL_LINK_STATUS，
     最后一个参数就是返回值. 返回值是 1 则代表链接成功，如果返回值是 0 则代表链接失败. 类似于编译 Shader 的操作，如果链接失败了，可以获取错误信息，以便修改程序.
     */
    // 打印链接日志
    GLint linkStatus;
    glGetProgramiv(_simpleProgram, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {
        GLint infoLength;
        glGetProgramiv(_simpleProgram, GL_INFO_LOG_LENGTH, &infoLength);
        if (infoLength > 0) {
            GLchar *infoLog = malloc(sizeof(GLchar) * infoLength);
            glGetProgramInfoLog(_simpleProgram, infoLength, NULL, infoLog);
            NSLog(@"%s", infoLog);
            free(infoLog);
        }
    }
    glUseProgram(_simpleProgram);
    
    /**
     OpenGL ES 渲染管线分为哪几个步骤呢？
     阶段一:指定几何对象
     阶段二:顶点变换   可以自己编写着色器
     阶段三:图元组装
     阶段四:栅格化操作
     阶段五:片元处理   可以自己编写着色器
     阶段六:帧缓冲操作
     */
    
    // 7.根据三角形顶点信息申请顶点缓冲区对象 VBO(Vertex Buffer Object) 和拷贝顶点数据
    /******************************创建VBO 代码 start*******************************/
    
    // 设置三角形 3 个顶点数据，包括坐标信息和颜色信息
    const SceneVertex vertices[] = {
        {{-0.5,  0.5, 0.0}, { 1.0, 0.0, 0.0, 1.000}}, // 左下 // 红色
        {{-0.5, -0.5, 0.0}, { 0.0, 1.0, 0.0, 1.000}}, // 右下 // 绿色
        {{ 0.5, -0.5, 0.0}, { 0.0, 0.0, 1.0, 1.000}}, // 左上 // 蓝色
    };
    // 申请并绑定 VBO VBO 的作用是在显存中提前开辟好一块内存，用于缓存顶点数据，从而避免每次绘制时的 CPU 与 GPU 之间的内存拷贝，可以提升渲染性能
    GLuint vertexBufferID;
    glGenBuffers(1, &vertexBufferID); // 创建 VBO
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID); // 绑定 VBO 到 OpenGL 渲染管线
    // 将顶点数据 (CPU 内存) 拷贝到 VBO（GPU 显存）
    glBufferData(GL_ARRAY_BUFFER, // 缓存块类型
                 sizeof(vertices), // 创建的缓存块尺寸
                 vertices, // 要绑定的顶点数据
                 GL_STATIC_DRAW); // 缓存块用途
    
    /******************************创建VBO 代码 end*******************************/
    
    // 8.绘制三角形
    // 获取与 Shader 中对应的参数信息：
    GLuint vertexPositionLocation = glGetAttribLocation(_simpleProgram, "v_position");
    GLuint vertexColorLocation = glGetAttribLocation(_simpleProgram, "v_color");
    // 顶点位置属性
    glEnableVertexAttribArray(vertexPositionLocation); // 启用顶点位置属性通道
    // 关联顶点位置数据
    glVertexAttribPointer(vertexPositionLocation, // attribute 变量的下标，范围是 [0, GL_MAX_VERTEX_ATTRIBS - 1]
                          PositionDimension, // 指顶点数组中，一个 attribute 元素变量的坐标分量是多少（如：position, 程序提供的就是 {x, y, z} 点就是 3 个坐标分量）
                          GL_FLOAT, // 数据的类型
                          GL_FALSE, // 是否进行数据类型转换
                          sizeof(SceneVertex), // 每一个数据在内存中的偏移量，如果填 0 就是每一个数据紧紧相挨着
                          (const GLvoid*) offsetof(SceneVertex, position)); // 数据的内存首地址
    // 顶点颜色属性
    glEnableVertexAttribArray(vertexColorLocation);
    // 关联顶点颜色数据
    glVertexAttribPointer(vertexColorLocation,
                          ColorDimension,
                          GL_FLOAT,
                          GL_FALSE,
                          sizeof(SceneVertex),
                          (const GLvoid*) offsetof(SceneVertex, color));
    // 绘制所有图元
    glDrawArrays(GL_TRIANGLES, // 绘制的图元方式
                 0, // 从第几个顶点下标开始绘制
                 sizeof(vertices) / sizeof(vertices[0])); // 有多少个顶点下标需要绘制
    // 把 Renderbuffer 的内容显示到窗口系统 (CAEAGLLayer) 中
    [_eaglContext presentRenderbuffer:GL_RENDERBUFFER];
    
    // 9.关闭 | 解绑
    glDisableVertexAttribArray(vertexColorLocation); // 关闭顶点颜色属性通道
    glDisableVertexAttribArray(vertexPositionLocation); // 关闭顶点位置属性通道
    glBindBuffer(GL_ARRAY_BUFFER, 0); // 解绑 VBO
    glBindFramebuffer(GL_FRAMEBUFFER, 0); // 解绑 FBO
    glBindRenderbuffer(GL_RENDERBUFFER, 0); // 解绑 RBO
}

#pragma mark - Utility

- (GLuint)loadShaderWithVertexShader:(NSString *)vert fragmentShader:(NSString *)frag {
    GLuint verShader, fragShader;
    
    /**
     1.创建 Shader（着色器）
     */
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    /**
     2.创建 Program
     */
    // 首先创建一个程序的实例作为程序的容器，这个函数返回程序的句柄
    GLuint program = glCreateProgram(); // 创建 Shader Program 对象
    // 紧接着将把上面部分编译的 shader 附加（Attach）到刚刚创建的程序中
    // 第一个参数 GLuint program 就是传入在上面一步返回的程序容器的句柄，
    // 第二个参数 GLuint shader 就是编译的 Shader 的句柄，
    // 当然要为每一个 shader 都调用一次这个方法才能把两个 Shader 都关联到 Program 中去。
    // 装载 Vertex Shader 和 Fragment Shader
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}

/**
 创建 Shader（着色器）
 */
- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar *source = (GLchar *) [content UTF8String];
    /**
     第一步:创建一个着色器对象，作为 Shader 的容器，这个函数返回一个容器的句柄
     函数原型中的参数 type 有两种类型：
     一是 GL_VERTEX_SHADER，创建顶点着色器时开发者应传入的类型；
     二是 GL_FRAGMENT_SHADER，创建片元着色器时开发者应传入的类型。
     */
    *shader = glCreateShader(type);
    /**
     第二步:给创建的这个 Shader 添加源代码
     */
    glShaderSource(*shader, 1, &source, NULL); // 关联顶点、片元着色器的代码
    /**
     最后一步:编译这个 Shader
     */
    glCompileShader(*shader); // 编译着色器代码
    
    /**
     验证 shader 是否被编译成功 使用 glGetShaderiv 函数来验证
     第一个参数 GLuint shader 就是我们要验证的 Shader 句柄；
     第二个参数 GLenum pname 是我们要验证的这个 Shader 的状态值，一般在这里验证是否编译成功，这个状态值选择 GL_COMPILE_STATUS
     第三个参数 GLint* params 就是返回值，当返回值是 1 的时候，说明这个 Shader 编译成功了；如果是 0，就说明这个 shader 没有被编译成功。
     */
    // 打印编译日志
    GLint compileStatus;
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &compileStatus);
    if (compileStatus == GL_FALSE) {
        GLint infoLength;
        glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &infoLength);
        if (infoLength > 0) {
            GLchar *infoLog = malloc(sizeof(GLchar) * infoLength);
            glGetShaderInfoLog(*shader, infoLength, NULL, infoLog);
            NSLog(@"%s -> %s", (type == GL_VERTEX_SHADER) ? "vertex shader" : "fragment shader", infoLog);
            free(infoLog);
        }
    }
}

#pragma mark - Override

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

@end
