#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface View : MTKView <MTKViewDelegate>
@end

@implementation View {
  id<MTLDevice> _device;
  id<MTLCommandQueue> _commandQueue;
  id<MTLRenderPipelineState> _pipelineState;
  id<MTLBuffer> _vertexBuffer;
}

typedef struct {
  vector_float2 position;
  vector_float4 color;
} Vertex;

- (instancetype)initWithFrame:(NSRect)frameRect {
  self = [super initWithFrame:frameRect device:MTLCreateSystemDefaultDevice()];
  if (self) {
    self.delegate = self;
    self.enableSetNeedsDisplay = YES;

    [self setupMetal];
  }
  return self;
}

- (void)setupMetal {
  _device = self.device;
  _commandQueue = [_device newCommandQueue];

  NSError *error = nil;
  NSString *libPath = @"./shader.metallib";
  NSURL *libURL = [NSURL fileURLWithPath:libPath];
  id<MTLLibrary> library = [_device newLibraryWithURL:libURL error:&error];
  if (!library) {
    NSLog(@"Failed to load library: %@", error);
    return;
  }

  id<MTLFunction> vertexFunction =
      [library newFunctionWithName:@"vertexShader"];
  if (!vertexFunction) {
    NSLog(@"Failed to find vertex function");
    return;
  }

  id<MTLFunction> fragmentFunction =
      [library newFunctionWithName:@"fragmentShader"];
  if (!fragmentFunction) {
    NSLog(@"Failed to find fragment function");
    return;
  }

  MTLRenderPipelineDescriptor *pipelineDescriptor =
      [[MTLRenderPipelineDescriptor alloc] init];
  pipelineDescriptor.vertexFunction = vertexFunction;
  pipelineDescriptor.fragmentFunction = fragmentFunction;
  pipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat;

  _pipelineState =
      [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor
                                              error:&error];
  if (!_pipelineState) {
    NSLog(@"Failed to create pipeline state: %@", error);
    return;
  }

  static const Vertex vertices[] = {{{0.0, 0.5}, {1.0, 0.0, 0.0, 1.0}},
                                    {{-0.5, -0.5}, {0.0, 1.0, 0.0, 1.0}},
                                    {{0.5, -0.5}, {0.0, 0.0, 1.0, 1.0}}};

  _vertexBuffer = [_device newBufferWithBytes:vertices
                                       length:sizeof(vertices)
                                      options:MTLResourceStorageModeShared];
}

- (void)drawInMTKView:(MTKView *)view {
  id<CAMetalDrawable> drawable = view.currentDrawable;
  MTLRenderPassDescriptor *renderPassDescriptor =
      view.currentRenderPassDescriptor;

  if (!drawable || !renderPassDescriptor) {
    return;
  }

  id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

  id<MTLRenderCommandEncoder> renderEncoder =
      [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

  [renderEncoder setRenderPipelineState:_pipelineState];
  [renderEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];

  [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                    vertexStart:0
                    vertexCount:3];

  [renderEncoder endEncoding];
  [commandBuffer presentDrawable:drawable];
  [commandBuffer commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
}

@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

@implementation AppDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:
    (NSApplication *)sender {
  return YES;
}

@end

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    NSApplication *app = [NSApplication sharedApplication];
    AppDelegate *appDelegate = [[AppDelegate alloc] init];
    [app setDelegate:appDelegate];

    [app setActivationPolicy:NSApplicationActivationPolicyRegular];

    NSRect frame = NSMakeRect(0, 0, 800, 600);
    NSWindow *window =
        [[NSWindow alloc] initWithContentRect:frame
                                    styleMask:(NSWindowStyleMaskTitled |
                                               NSWindowStyleMaskClosable |
                                               NSWindowStyleMaskResizable)
                                      backing:NSBackingStoreBuffered
                                        defer:NO];
    [window setTitle:@"Metal Triangle"];

    NSScreen *screen = [NSScreen mainScreen];
    NSRect screenRect = [screen visibleFrame];
    NSPoint centerPoint = NSMakePoint(NSMidX(screenRect) - NSWidth(frame) / 2,
                                      NSMidY(screenRect) - NSHeight(frame) / 2);
    [window setFrameOrigin:centerPoint];

    View *metalView = [[View alloc] initWithFrame:frame];
    [window setContentView:metalView];
    [window makeKeyAndOrderFront:nil];

    [app activateIgnoringOtherApps:YES];

    [app run];
  }
  return 0;
}
