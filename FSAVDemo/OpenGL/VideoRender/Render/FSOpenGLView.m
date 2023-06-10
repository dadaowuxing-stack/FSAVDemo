//
//  FSOpenGLView.m
//  FSAVDemo
//
//  Created by liufengshuo on 2023/3/25.
//  格式化代码,选中control+i

#import "FSOpenGLView.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVUtilities.h>
#import <mach/mach_time.h>
#import <GLKit/GLKit.h>
#import "FSGLFilter.h"
#import "FSGLBase.h"
#import <GLKit/GLKit.h>

@interface FSOpenGLView() {
    // The pixel dimensions of the CAEAGLLayer.
    GLint _backingWidth;
    GLint _backingHeight;
    
    GLuint _frameBufferHandle;
    GLuint _colorBufferHandle;
    
    FSGLFilter *_filter;
    GLfloat _customVertices[8];
}

@property (nonatomic, assign) CGSize currentViewSize; // 当前 view 大小.
@property (nonatomic, assign) CGSize frameSize; // 当前被渲染的纹理大小.

@end

@implementation FSOpenGLView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame context:(nullable EAGLContext *)context{
    if (self = [super initWithFrame:frame]) {
        self.contentScaleFactor = [[UIScreen mainScreen] scale];
        // 设定 layer 相关属性.
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *) self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = @{ kEAGLDrawablePropertyRetainedBacking: @(NO),
                                          kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};
        _fillMode = FSGLViewContentModeFit;
        
        // 设置当前 OpenGL 上下文，并初始化相关 GL 环境.
        if (context) {
            EAGLContext *preContext = [EAGLContext currentContext];
            [EAGLContext setCurrentContext:context];
            [self _setupGL];
            [EAGLContext setCurrentContext:preContext];
        } else {
            NSLog(@"FSOpenGLView context nil");
        }
    }
    
    return self;
}

- (void)layoutSubviews {
    // 视图自动调整布局，同步至渲染视图.
    [super layoutSubviews];
    _currentViewSize = self.bounds.size;
}

- (void)dealloc {
    if(_frameBufferHandle != 0){
        glDeleteFramebuffers(1, &_frameBufferHandle);
    }
    if(_colorBufferHandle != 0){
        glDeleteRenderbuffers(1, &_colorBufferHandle);
    }
}

# pragma mark - OpenGL Setup
- (void)_setupGL {
    // 1、申请并绑定帧缓冲区对象 FBO.
    glGenFramebuffers(1, &_frameBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
    
    // 2、申请并绑定渲染缓冲区对象 RBO.
    glGenRenderbuffers(1, &_colorBufferHandle);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorBufferHandle);
    
    // 3、将渲染图层（_eaglLayer）的存储绑定到 RBO.
    [[EAGLContext currentContext] renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    // 当渲染缓冲区 RBO 绑定存储空间完成后，可以通过 glGetRenderbufferParameteriv 获取渲染缓冲区的宽高，实际跟上面设置的 layer 的宽高一致.
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);

    // 4、将 RBO 绑定为 FBO 的一个附件.绑定后，OpenGL 对 FBO 的绘制会同步到 RBO 后再上屏.
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorBufferHandle);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    
    // 5、FSGLFilter 封装了 shader 的加载、编译和着色器程序链接，以及 FBO 的管理.这里用一个 Filter 来实现具体的渲染细节.
    _filter = [[FSGLFilter alloc] initWithCustomFBO:YES vertexShader:FSDefaultVertexShader fragmentShader:FSDefaultFragmentShader]; // 这里 isCustomFBO 传 YES，表示直接用外部的 FBO（即上面创建的 FBO 对象 _frameBufferHandle）.vertexShader 和 fragmentShader 则都使用默认的.
    __weak typeof(self) wself = self;
    _filter.preDrawCallBack = ^(){
        // 在渲染前回调中，关联顶点位置数据.通过渲染回调接口，可以在外部更新顶点数据.
        __strong typeof(wself) sself = wself;
        if (sself) {
            glVertexAttribPointer([[sself->_filter getProgram] getAttribLocation:@"position"], 2, GL_FLOAT, 0, 0, sself->_customVertices);
        }
    };
}

- (void)_updaterVertices {
    // 根据视频画面填充模式计算顶点数据.
    float heightScaling = 1.0;
    float widthScaling = 1.0;
    
    if (!CGSizeEqualToSize(_currentViewSize, CGSizeZero) && !CGSizeEqualToSize(_frameSize, CGSizeZero)) {
        CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(_frameSize, CGRectMake(0, 0, _currentViewSize.width, _currentViewSize.height));
        
        switch (_fillMode) {
            case FSGLViewContentModeStretch: {
                widthScaling = 1.0;
                heightScaling = 1.0;
                break;
            }
            case FSGLViewContentModeFit: {
                widthScaling = insetRect.size.width / _currentViewSize.width;
                heightScaling = insetRect.size.height / _currentViewSize.height;
                break;
            }
            case FSGLViewContentModeFill: {
                widthScaling = _currentViewSize.height / insetRect.size.height;
                heightScaling = _currentViewSize.width / insetRect.size.width;
                break;
            }
        }
    }
    
    _customVertices[0] = -widthScaling;
    _customVertices[1] = -heightScaling;
    _customVertices[2] = widthScaling;
    _customVertices[3] = -heightScaling;
    _customVertices[4] = -widthScaling;
    _customVertices[5] = heightScaling;
    _customVertices[6] = widthScaling;
    _customVertices[7] = heightScaling;
}

#pragma mark - OpenGLES Render
// 渲染一帧纹理.
- (void)displayFrame:(FSTextureFrame *)frame {
    if (![EAGLContext currentContext] || !frame) {
        return;
    }
    
    // 1、绑定 FBO、RBO 到 OpenGL 渲染管线.
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorBufferHandle);
    
    // 2、设置视口大小为整个渲染缓冲区的区域.
    glViewport(0, 0, _backingWidth, _backingHeight);
    
    // 3、渲染传进来的一帧纹理.
    FSTextureFrame *renderFrame = frame.copy; // 获取纹理.
    _frameSize = renderFrame.textureSize; // 记录纹理大小.
    
    // 将 GL 的坐标系（↑→）适配屏幕坐标系（↓→），生成新的 mvp 矩阵.
    GLKVector4 scale = {1, -1, 1, 1};
    renderFrame.mvpMatrix = GLKMatrix4ScaleWithVector4(GLKMatrix4Identity, scale);
    
    [self _updaterVertices]; // 更新一下顶点位置数据.外部如何更改了画面填充模式会影响顶点位置.
    [_filter render:renderFrame]; // 渲染.
    
    // 4、把 RBO 的内容显示到窗口系统 (CAEAGLLayer) 中.
    [[EAGLContext currentContext] presentRenderbuffer:GL_RENDERBUFFER];
 
    // 5、将 FBO、RBO 从 OpenGL 渲染管线解绑.
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
}

@end
