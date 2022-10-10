//
//  FSOpenGLTriangleRenderVC.m
//  FSAVDemo
//
//  Created by louis on 2022/10/8.
//

#import "FSOpenGLTriangleRenderVC.h"
#import "FSTriangleRenderView.h"

@interface FSOpenGLTriangleRenderVC ()

@property (nonatomic, strong) FSTriangleRenderView *triangleRenderView;

@end

@implementation FSOpenGLTriangleRenderVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.triangleRenderView];
}

- (FSTriangleRenderView *)triangleRenderView {
    if (!_triangleRenderView) {
        _triangleRenderView = [[FSTriangleRenderView alloc] initWithFrame:self.view.bounds];
    }
    return _triangleRenderView;
}

@end
