#import <Foundation/Foundation.h>

/********* Cordova Plugin Header *******/

#import <Cordova/CDV.h>

@interface MuPDF : CDVPlugin

- (void) open : (CDVInvokedUrlCommand*)command;
- (void) openWithFileName : (CDVInvokedUrlCommand*)command;
- (void) getPDF : (CDVInvokedUrlCommand*)command;

@end
