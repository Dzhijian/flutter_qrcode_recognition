#import "QrcodeRecognitionPlugin.h"

@implementation QrcodeRecognitionPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"qrcode_recognition"
            binaryMessenger:[registrar messenger]];
  QrcodeRecognitionPlugin* instance = [[QrcodeRecognitionPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    }
    else if ([@"recognitionQrcode" isEqualToString:call.method]) {
        [self arguments:call.arguments getImageResult:^(CIImage *reultImage, NSString *errorStr) {
            if (reultImage) {
                result([self resultOfRecognitionImage:reultImage]);
            }
            else if (errorStr) {
                result([FlutterError errorWithCode:@"-3" message:errorStr details:nil]);
            }
        }];
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

// 通过 arguments 获取 CIImage
- (void)arguments:(id)arguments getImageResult:(void(^)(CIImage *reultImage, NSString *errorStr))result {
    CIImage *image;
    if ([arguments isKindOfClass:[CIImage class]]) {
        image = arguments;
    }
    else if ([arguments isKindOfClass:[UIImage class]]) {
        UIImage *img = (UIImage *)arguments;
        image = img.CIImage;
    }
    else if ([arguments isKindOfClass: [NSString class]]) {
        // 带有 http 、 https 网络图片资源，需下载
        if ([arguments containsString: @"http://"] || [arguments containsString: @"https://"]) {
            NSString *urlStr = [arguments stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            NSURL *url = [NSURL URLWithString:urlStr];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            NSURLSessionConfiguration *sessionConfig= [NSURLSessionConfiguration defaultSessionConfiguration];
            sessionConfig.timeoutIntervalForRequest = 20;
            sessionConfig.allowsCellularAccess = YES;
            NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
            NSURLSessionDownloadTask *downTask = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (error) {
                    result(nil, error.localizedDescription);
                }
                else {
                    CIImage *image = [CIImage imageWithContentsOfURL:location];
                    result(image, nil);
                }
            }];
            [downTask resume];
            return;
        }
        // file:// 本地图片资源
        else if ([arguments containsString: @"file://"]) {
        NSString *filePathStr = [arguments substringFromIndex:7];
        image = [CIImage imageWithData:[NSData dataWithContentsOfFile:filePathStr]];
        }
        // 可读的本地图片资源
        else if ([[NSFileManager defaultManager] isReadableFileAtPath:arguments]) {
            image = [CIImage imageWithData:[NSData dataWithContentsOfFile:arguments]];
        }
        // base64 图片， data:image/png;base64,xxxxxxxxxx
        else if ([arguments containsString: @"base64,"]) {
            // 拿到后面 xxxxxxxx 部分，生成 data ，再转 image
            NSString *base64Value = [arguments componentsSeparatedByString:@"base64,"].lastObject;
            NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64Value options:NSDataBase64DecodingIgnoreUnknownCharacters];
            if (imageData) {
                image = [CIImage imageWithData:imageData];
            }
        }
        else {
            NSData *imageData = [[NSData alloc] initWithBase64EncodedString:arguments options:NSDataBase64DecodingIgnoreUnknownCharacters];
            if (!imageData) {
                imageData = [arguments dataUsingEncoding:NSUTF8StringEncoding];
            }
            if (imageData) {
                image = [CIImage imageWithData:imageData];
            }
        }
    }
    result(image, nil);
}

/// 获取 CIImage 图片二维码结果
/// @param image 二维码图片
- (id)resultOfRecognitionImage:(CIImage *)image {
    if (image) {
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
        // 识别结果
        NSArray *features = [detector featuresInImage:image];
        if (features.count == 0 ||
            ![features.firstObject isKindOfClass:[CIQRCodeFeature class]]) {
            return [FlutterError errorWithCode:@"-1" message:@"No results" details:nil];
        }
        else {
            return @{@"code": @"0", @"value": [(CIQRCodeFeature *)features.firstObject messageString]};
        }
    }
    else {
        return [FlutterError errorWithCode:@"-2" message:@"Image parsing failed" details:nil];
    }
}

@end
