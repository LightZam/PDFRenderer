
/********* Cordova Plugin Implementation *******/

#import "MuPDF.h"
#import "MuDocRef.h"
#import "MuPDFCore.h"

@implementation MuPDF

//fz_document *doc;
MuDocRef* docRef;

static NSString *alteredfilename(NSString *name, int i)
{
    if (i == 0)
        return name;
    
    NSString *nam = [name stringByDeletingPathExtension];
    NSString *e = [name pathExtension];
    return [[NSString alloc] initWithFormat:@"%@(%d).%@", nam, i, e];
}

static NSString *moveOutOfInbox(NSString *docpath)
{
    if ([docpath hasPrefix:@"Inbox/"])
    {
        NSFileManager *fileMan = [NSFileManager defaultManager];
        NSString *base = [docpath stringByReplacingOccurrencesOfString:@"Inbox/" withString:@""];
        
        for (int i = 0; YES; i++)
        {
            NSString *newname = alteredfilename(base, i);
            NSString *newfullpath = [NSString pathWithComponents:[NSArray arrayWithObjects:NSHomeDirectory(), @"Documents", newname, nil]];
            
            if (![fileMan fileExistsAtPath:newfullpath])
            {
                NSString *fullpath = [NSString pathWithComponents:[NSArray arrayWithObjects:NSHomeDirectory(), @"Documents", docpath, nil]];
                [fileMan copyItemAtPath:fullpath toPath:newfullpath error:nil];
                [fileMan removeItemAtPath:fullpath error:nil];
                return newname;
            }
        }
    }
    
    return docpath;
}

- (void) open : (CDVInvokedUrlCommand*)command {
    // file name
    queue = dispatch_queue_create("com.gss.mupdf.queue", NULL);
    
    ctx = fz_new_context(NULL, NULL, ResourceCacheMaxSize);
    fz_register_document_handlers(ctx);

    CDVPluginResult* pluginResult = nil;
    NSString* nsfilename = [command.arguments objectAtIndex:0];
    // nsfilename = moveOutOfInbox(nsfilename);
    NSString* nspath = [[NSArray arrayWithObjects:NSHomeDirectory(), @"Documents", nsfilename, nil]
                        componentsJoinedByString:@"/"];
    char* _filePath = malloc(strlen([nspath UTF8String])+1);
    if (_filePath == NULL) {
//        printf(@"Out of memory in openDocument %s", nsfilename);
        return;
    }
    
    strcpy(_filePath, [nspath UTF8String]);
    
    dispatch_sync(queue, ^{});
    
    printf("open document '%s'\n", _filePath);
    
    NSString *_filename = nsfilename;
    docRef = [[MuDocRef alloc] initWithFilename:_filePath];
    if (!docRef) {
//        printf(@"Cannot open document %s", nsfilename);
        return;
    }
    
    // if (echo != nil && [echo length] > 0) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    // } else {
    //     pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    // }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

    // file path
}


- (void) getPDF : (CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    NSString* echo = @"get pdf";
    __block NSInteger npages = 0;
        dispatch_sync(queue, ^{
            fz_try(ctx)
            {
                npages = fz_count_pages(docRef->doc);
            }
            fz_catch(ctx);
        });
    
    if (echo != nil && [echo length] > 0) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:npages];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
