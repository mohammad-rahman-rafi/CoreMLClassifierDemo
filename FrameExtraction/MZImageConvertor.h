//
//  MZImageconvertor.h
//  FrameExtraction
//
//  Modified on 2018/02/20.
//


#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>

@interface MZImageConvertor: NSObject

@property (strong, nonatomic) id someProperty;


+ (CGImageRef)resizeCGImage:(CGImageRef)image toWidth:(int)width andHeight:(int)height;
+ (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image;
+ (void)hello;
@end


