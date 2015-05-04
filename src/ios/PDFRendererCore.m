//
//  PDFRendererCore.m
//  mupdf
//
//  Created by Zam-mbpr on 2015/3/3.
//
//

#import <Foundation/Foundation.h>
#include "mupdf/fitz.h"
#include "mupdf/pdf.h"
#include "dispatch/dispatch.h"
#import "PDFRendererCore.h"

@implementation PDFRendererCore

- (id) init {
    [super self];
    queue = dispatch_queue_create("com.gss.mupdf.queue", nil);
    return self;
}

- (void) dealloc {
    [self closeFile];
}

/**
 * --------------------
 * public method
 * --------------------
 */
- (BOOL) openFile: (char*)path {
    ctx = fz_new_context(nil, nil, ResourceCacheMaxSize);
    fz_register_document_handlers(ctx);
    dispatch_sync(queue, ^{});
    docRef = [[MuDocRef alloc] initWithFilename: path];
    return docRef != nil;
}

- (BOOL) openFile: (NSData*)buffer magic: (char*)magic {
    ctx = fz_new_context(nil, nil, ResourceCacheMaxSize);
    fz_register_document_handlers(ctx);
    dispatch_sync(queue, ^{});
    docRef = [[MuDocRef alloc] initWithBuffer: buffer magic: magic];
    return docRef != nil;
}

- (void) closeFile {
    dispatch_sync(queue, ^{});
    if (pageList != nil) {
        fz_drop_display_list(ctx, pageList);
        pageList = nil;
    }
    if (page != nil) {
        fz_free_page(docRef->doc, page);
        page = nil;
    }
    if (docRef != nil) {
        fz_close_document(docRef->doc);
        docRef->doc = nil;
        docRef = nil;
    }
    if (ctx != nil) {
        fz_free_context(ctx);
        ctx = nil;
    }
}

- (NSInteger) countPages {
    __block NSInteger pages = 0;
    
    dispatch_sync(queue, ^{
        fz_try(ctx) {
            pages = fz_count_pages(docRef->doc);
        } fz_catch(ctx) {
            printf("Failed to find page number");
        }
    });
    return pages;
}

- (CGSize) getPageSize: (int)index {
    __block CGSize size = { 0.0, 0.0 };
    fz_page* page = [self getPage: index];
    
    dispatch_sync(queue, ^{
        fz_try(ctx) {
            fz_rect bounds;
            fz_bound_page(docRef->doc, page, &bounds);
            size.width = bounds.x1 - bounds.x0;
            size.height = bounds.y1 - bounds.y0;
        } fz_catch(ctx) {
            printf("Failed to find page bounds\n");
        }
    });
    
    return size;
}

- (BOOL) needsPassword {
    return fz_needs_password(docRef->doc);
}

- (BOOL) authenticatePassword: (char*)password {
    return fz_authenticate_password(docRef->doc, password);
}

- (BOOL) isFileOpen {
    return ctx != nil && [self countPages] > 0;
}

- (UIImage*) drawPage: (int)index pageSize: (CGSize)pageSize patchRect: (CGRect)patchRect {
    if (index < 0 || index >= fz_count_pages(docRef->doc))
        return nil;
    UIImage* image = nil;
    CGDataProviderRef imageData = nil;
    fz_pixmap* pixmap = nil;
    
    dispatch_async(queue, ^{});
    [self ensureDisplaylists: index];
    pixmap = [self renderPixmap: pageList pageSize: pageSize patchRect: patchRect];
    CGDataProviderRelease(imageData);
    imageData = [self createWrappedPixmap: pixmap];
    image = [self newImageWithPixmap: pixmap imageData: imageData];

    return image;
}

/**
 * --------------------
 * private method
 * --------------------
 */
- (fz_page*) getPage: (int)index {
    __block fz_page* blockPage = nil;
    
    dispatch_sync(queue, ^{
        fz_try(ctx) {
            blockPage = fz_load_page(docRef->doc, index);
        } fz_catch(ctx) {
            printf("Failed to load page\n");
        }
    });

    return blockPage;
}

- (fz_page*) ensurePageLoaded: (int)index {
    fz_try(ctx) {
        fz_rect bounds;
        if (page) {
            fz_free_page(docRef->doc, page);
            page = nil;
        }
        page = [self getPage: index];
        fz_bound_page(docRef->doc, page, &bounds);
    } fz_catch(ctx) {
        return nil;
    }
    return page;
}

- (void) ensureDisplaylists: (int)index {
    page = [self ensurePageLoaded: index];
    if (!page)
        return;

    if (!pageList) {
        pageList = [self createPageList: page];
    }
//    if (!annot_list)
//        annot_list = create_annot_list(doc, page);
}

- (fz_display_list*) createPageList: (fz_page*)page {
    fz_display_list *list = nil;
    fz_device *dev = nil;
    
    fz_var(dev);
    fz_try(ctx) {
        list = fz_new_display_list(ctx);
        dev = fz_new_list_device(ctx, list);
        fz_run_page_contents(docRef->doc, page, dev, &fz_identity, nil);
    } fz_always(ctx) {
        fz_free_device(dev);
    } fz_catch(ctx) {
        return nil;
    }
    
    return list;
}

- (fz_pixmap*) createPixMap: (CGSize)size {
    __block fz_pixmap *pix = nil;
    
    dispatch_sync(queue, ^{
        fz_try(ctx) {
            pix = fz_new_pixmap(ctx, fz_device_rgb(ctx), size.width, size.height);
        } fz_catch(ctx) {
            printf("Failed to create pixmap\n");
        }
    });
    
    return pix;
}

//- (CGSize) fitPageToScreen: (CGSize)page screenSize: (CGSize)screen {
//    float hscale = screen.width / page.width;
//    float vscale = screen.height / page.height;
//    float scale = fz_min(hscale, vscale);
//    hscale = floorf(page.width * scale) / page.width;
//    vscale = floorf(page.height * scale) / page.height;
//    return CGSizeMake(hscale, vscale);
//}

static void releasePixmap(void *info, const void *data, size_t size) {
    if (queue) {
        dispatch_async(queue, ^{
            fz_drop_pixmap(ctx, info);
        });
    } else {
        fz_drop_pixmap(ctx, info);
    }
}

- (CGDataProviderRef) createWrappedPixmap: (fz_pixmap*)pix {
    unsigned char *samples = fz_pixmap_samples(ctx, pix);
    int w = fz_pixmap_width(ctx, pix);
    int h = fz_pixmap_height(ctx, pix);
    return CGDataProviderCreateWithData(pix, samples, w * 4 * h, releasePixmap);
}

- (CGImageRef) createCGImageWithPixmap: (fz_pixmap*)pix data: (CGDataProviderRef)cgdata {
    int w = fz_pixmap_width(ctx, pix);
    int h = fz_pixmap_height(ctx, pix);
    CGColorSpaceRef cgcolor = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgimage = CGImageCreate(w, h, 8, 32, 4 * w, cgcolor, kCGBitmapByteOrderDefault, cgdata, nil, NO, kCGRenderingIntentDefault);
    CGColorSpaceRelease(cgcolor);
    return cgimage;
}

- (UIImage*) newImageWithPixmap: (fz_pixmap*)pix imageData: (CGDataProviderRef)cgdata {
    CGImageRef cgimage = [self createCGImageWithPixmap: pix data: cgdata];
    UIImage *image = [[UIImage alloc] initWithCGImage: cgimage scale: screenScale orientation: UIImageOrientationUp];
    CGImageRelease(cgimage);
    return image;
}

- (fz_pixmap*) renderPixmap: (fz_display_list*)pageList pageSize: (CGSize)pageSize patchRect: (CGRect)patchRect {
    fz_irect bbox;
    fz_rect rect;
    fz_matrix ctm;
    fz_device *dev = nil;
    fz_pixmap *pix = nil;
    
    bbox.x0 = patchRect.origin.x;
    bbox.y0 = patchRect.origin.y;
    bbox.x1 = patchRect.origin.x + patchRect.size.width;
    bbox.y1 = patchRect.origin.y + patchRect.size.height;
    float sx = pageSize.width / patchRect.size.width;
    float sy = pageSize.height / patchRect.size.height;
    fz_scale(&ctm, sx, sy);
    fz_rect_from_irect(&rect, &bbox);
    
    fz_var(dev);
    fz_var(pix);
    fz_try(ctx) {
        pix = fz_new_pixmap_with_bbox(ctx, fz_device_rgb(ctx), &bbox);
        fz_clear_pixmap_with_value(ctx, pix, 255);
        dev = fz_new_draw_device(ctx, pix);
        fz_run_display_list(pageList, dev, &ctm, &rect, nil);
    } fz_always(ctx) {
        fz_free_device(dev);
    } fz_catch(ctx) {
        fz_drop_pixmap(ctx, pix);
        return nil;
    }
    
    return pix;
}

@end