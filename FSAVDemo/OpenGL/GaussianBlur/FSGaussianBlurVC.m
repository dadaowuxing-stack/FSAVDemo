//
//  FSGaussianBlurVC.m
//  FSAVDemo
//
//  Created by liufengshuo on 2023/4/20.
//

#import "FSGaussianBlurVC.h"

#import "FSUIImageConvertTexture.h"
#import "FSOpenGLView.h"
#import "FSGLFilter.h"
#import "FSGLGaussianBlur.h"

@interface FSGaussianBlurVC ()
@property (nonatomic, strong) FSOpenGLView *glView;
@property (nonatomic, strong) FSUIImageConvertTexture *imageConvertTexture;
@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) FSGLFilter *verticalGaussianBlurFilter;
@property (nonatomic, strong) FSGLFilter *horizonalGaussianBlurFilter;
@end

@implementation FSGaussianBlurVC


#pragma mark - Property
- (EAGLContext *)context {
    if (!_context) {
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    
    return _context;
}

- (FSUIImageConvertTexture *)imageConvertTexture {
    if (!_imageConvertTexture) {
        _imageConvertTexture = [[FSUIImageConvertTexture alloc] init];
    }
    return _imageConvertTexture;
}

- (FSGLFilter *)verticalGaussianBlurFilter {
    if (!_verticalGaussianBlurFilter) {
        _verticalGaussianBlurFilter = [[FSGLFilter alloc] initWithCustomFBO:NO vertexShader:FSGLGaussianBlurVertexShader fragmentShader:FSGLGaussianBlurFragmentShader];
        [_verticalGaussianBlurFilter setFloatUniformValue:@"hOffset" floatValue:0.00390625f];
    }
    return _verticalGaussianBlurFilter;
}

- (FSGLFilter *)horizonalGaussianBlurFilter {
    if (!_horizonalGaussianBlurFilter) {
        _horizonalGaussianBlurFilter = [[FSGLFilter alloc] initWithCustomFBO:NO vertexShader:FSGLGaussianBlurVertexShader fragmentShader:FSGLGaussianBlurFragmentShader];
        [_horizonalGaussianBlurFilter setFloatUniformValue:@"wOffset" floatValue:0.00390625f];
    }
    return _horizonalGaussianBlurFilter;
}

#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupUI];
    
    [self applyGaussianBlurEffect];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.glView.frame = self.view.bounds;
}

- (void)setupUI {
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.title = @"Gaussian Blur";
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 渲染 view。
    _glView = [[FSOpenGLView alloc] initWithFrame:self.view.bounds context:self.context];
    _glView.fillMode = FSGLViewContentModeFit;
    [self.view addSubview:self.glView];
}

- (void)applyGaussianBlurEffect {
    [EAGLContext setCurrentContext:self.context];
    UIImage *baseImage = [UIImage imageNamed:@"avatar"];
    FSTextureFrame *textureFrame = [FSUIImageConvertTexture renderImage:baseImage];
    
    // 垂直方向做一次高斯模糊。
    FSTextureFrame *verticalTexture = [self.verticalGaussianBlurFilter render:textureFrame];
    
    // 水平方向做一次高斯模糊。
    FSTextureFrame *horizonalTexture = [self.horizonalGaussianBlurFilter render:verticalTexture];
    
    [self.glView displayFrame:horizonalTexture];
    [EAGLContext setCurrentContext:nil];
}

@end
