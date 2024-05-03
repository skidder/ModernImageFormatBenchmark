//
//  DecodingTester.m
//  ModernImageFormatBenchmark
//
//  Created by lizhuoli on 2019/3/17.
//  Copyright © 2019 dreampiggy. All rights reserved.
//

#import "DecodingTester.h"
#import "PerformanceUtil.h"
#import "TesterUtil.h"
#import <SDWebImage/SDWebImage.h>
#import <SDWebImageWebPCoder/SDWebImageWebPCoder.h>

@implementation DecodingTester

+ (void)testWebPDecodingForName:(NSString *)name iterations:(int)iterations {
    SDImageFormat format = SDImageFormatWebP;
    NSArray<id<SDImageCoder>> *coders = @[
        SDImageWebPCoder.sharedCoder,  // libwebp decoder
        SDImageAWebPCoder.sharedCoder  // Apple's native decoder (assuming it has WebP support)
    ];

    NSString *type = [TesterUtil typeForFormat:format].lowercaseString;
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:name ofType:type];
    NSData *bundleData = [NSData dataWithContentsOfFile:bundlePath];

    for (id<SDImageCoder> coder in coders) {
        NSString *coderName = [coder isKindOfClass:[SDImageWebPCoder class]] ? @"libwebp" : @"Apple";
        [self benchmarkDecoder:coder data:bundleData format:format coderName:coderName iterations:iterations];
    }
}

+ (void)benchmarkDecoder:(id<SDImageCoder>)decoder data:(NSData *)data format:(SDImageFormat)format coderName:(NSString *)coderName iterations:(int)iterations {
    NSMutableArray<NSNumber *> *times = [NSMutableArray array];
    NSMutableArray<NSNumber *> *memories = [NSMutableArray array];
    int successfulDecodes = 0;

    for (int i = 0; i < iterations; i++) {
        CFAbsoluteTime before = CFAbsoluteTimeGetCurrent();
        double memoryUsageStart = [PerformanceUtil memoryUsage];

        UIImage *decodedImage = [decoder decodedImageWithData:data options:nil];
        CFAbsoluteTime after = CFAbsoluteTimeGetCurrent();

        if (decodedImage) {
            double memoryUsageEnd = [PerformanceUtil memoryUsage];
            [times addObject:@((after - before) * 1000)]; // Convert to milliseconds
            [memories addObject:@(memoryUsageEnd - memoryUsageStart)];
            successfulDecodes++;
        }
    }

    if (successfulDecodes > 0) {
        [times sortUsingSelector:@selector(compare:)];
        double minTime = [[times firstObject] doubleValue];
        double maxTime = [[times lastObject] doubleValue];
        double medianTime = [[times objectAtIndex:times.count / 2] doubleValue];
        double p90Time = [[times objectAtIndex:(int)(times.count * 0.9)] doubleValue];
        double p95Time = [[times objectAtIndex:(int)(times.count * 0.95)] doubleValue];

        printf("<Decode %s>: Min: %.2f ms, Median: %.2f ms, P90: %.2f ms, P95: %.2f ms, Max: %.2f ms, Successful Decodes: %d\n",
               [coderName cStringUsingEncoding:NSASCIIStringEncoding],
               minTime, medianTime, p90Time, p95Time, maxTime, successfulDecodes);
    } else {
        printf("<Decode %s>: No successful decodes\n",
               [coderName cStringUsingEncoding:NSASCIIStringEncoding]);
    }
}

@end
