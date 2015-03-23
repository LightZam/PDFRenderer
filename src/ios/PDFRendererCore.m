//
//  MuPDFCore.m
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
#import "MuAnnotation.h"
#import "MuWord.h"
//#include "MuDocRef.h"

#define STRIKE_HEIGHT (0.375f)
#define UNDERLINE_HEIGHT (0.075f)
#define LINE_THICKNESS (0.07f)
#define INK_THICKNESS (4.0f)

static NSString *const AlertTitle = @"Save Document?";
// Correct functioning of the app relies on CloseAlertMessage and ShareAlertMessage differing
static NSString *const CloseAlertMessage = @"Changes have been made to the document that will be lost if not saved";
static NSString *const ShareAlertMessage = @"Your changes will not be shared unless the document is first saved";

static int hit_count = 0;
static fz_rect hit_bbox[500];

//CGSize fitPageToScreen(CGSize page, CGSize screen)
//{
//    float hscale = screen.width / page.width;
//    float vscale = screen.height / page.height;
//    float scale = fz_min(hscale, vscale);
//    hscale = floorf(page.width * scale) / page.width;
//    vscale = floorf(page.height * scale) / page.height;
//    return CGSizeMake(hscale, vscale);
//}
//
//int search_page(fz_document *doc, int number, char *needle, fz_cookie *cookie)
//{
//    fz_page *page = fz_load_page(doc, number);
//
//    fz_text_sheet *sheet = fz_new_text_sheet(ctx);
//    fz_text_page *text = fz_new_text_page(ctx);
//    fz_device *dev = fz_new_text_device(ctx, sheet, text);
//    fz_run_page(doc, page, dev, &fz_identity, cookie);
//    fz_free_device(dev);
//
//    hit_count = fz_search_text_page(ctx, text, needle, hit_bbox, nelem(hit_bbox));
//
//    fz_free_text_page(ctx, text);
//    fz_free_text_sheet(ctx, sheet);
//    fz_free_page(doc, page);
//
//    return hit_count;
//}
//
//fz_rect search_result_bbox(fz_document *doc, int i)
//{
//    return hit_bbox[i];
//}
//
//static void releasePixmap(void *info, const void *data, size_t size)
//{
//    if (queue)
//        dispatch_async(queue, ^{
//            fz_drop_pixmap(ctx, info);
//        });
//    else
//    {
//        fz_drop_pixmap(ctx, info);
//    }
//}
//
//CGDataProviderRef CreateWrappedPixmap(fz_pixmap *pix)
//{
//    unsigned char *samples = fz_pixmap_samples(ctx, pix);
//    int w = fz_pixmap_width(ctx, pix);
//    int h = fz_pixmap_height(ctx, pix);
//    return CGDataProviderCreateWithData(pix, samples, w * 4 * h, releasePixmap);
//}
//
//CGImageRef CreateCGImageWithPixmap(fz_pixmap *pix, CGDataProviderRef cgdata)
//{
//    int w = fz_pixmap_width(ctx, pix);
//    int h = fz_pixmap_height(ctx, pix);
//    CGColorSpaceRef cgcolor = CGColorSpaceCreateDeviceRGB();
//    CGImageRef cgimage = CGImageCreate(w, h, 8, 32, 4 * w, cgcolor, kCGBitmapByteOrderDefault, cgdata, NULL, NO, kCGRenderingIntentDefault);
//    CGColorSpaceRelease(cgcolor);
//    return cgimage;
//}
//
//static void flattenOutline(NSMutableArray *titles, NSMutableArray *pages, fz_outline *outline, int level)
//{
//    char indent[8*4+1];
//    if (level > 8)
//        level = 8;
//    memset(indent, ' ', level * 4);
//    indent[level * 4] = 0;
//    while (outline)
//    {
//        if (outline->dest.kind == FZ_LINK_GOTO)
//        {
//            int page = outline->dest.ld.gotor.page;
//            if (page >= 0 && outline->title)
//            {
//                NSString *title = [NSString stringWithUTF8String: outline->title];
//                [titles addObject: [NSString stringWithFormat: @"%s%@", indent, title]];
//                [pages addObject: [NSNumber numberWithInt: page]];
//            }
//        }
//        flattenOutline(titles, pages, outline->down, level + 1);
//        outline = outline->next;
//    }
//}
//
//static char *tmp_path(char *path)
//{
//    int f;
//    char *buf = malloc(strlen(path) + 6 + 1);
//    if (!buf)
//        return NULL;
//
//    strcpy(buf, path);
//    strcat(buf, "XXXXXX");
//
//    f = mkstemp(buf);
//
//    if (f >= 0)
//    {
//        close(f);
//        return buf;
//    }
//    else
//    {
//        free(buf);
//        return NULL;
//    }
//}
//
//static void saveDoc(char *current_path, fz_document *doc)
//{
//    char *tmp;
//    fz_write_options opts;
//    opts.do_incremental = 1;
//    opts.do_ascii = 0;
//    opts.do_expand = 0;
//    opts.do_garbage = 0;
//    opts.do_linear = 0;
//
//    tmp = tmp_path(current_path);
//    if (tmp)
//    {
//        int written = 0;
//
//        fz_var(written);
//        fz_try(ctx)
//        {
//            FILE *fin = fopen(current_path, "rb");
//            FILE *fout = fopen(tmp, "wb");
//            char buf[256];
//            size_t n;
//            int err = 1;
//
//            if (fin && fout)
//            {
//                while ((n = fread(buf, 1, sizeof(buf), fin)) > 0)
//                    fwrite(buf, 1, n, fout);
//                err = (ferror(fin) || ferror(fout));
//            }
//
//            if (fin)
//                fclose(fin);
//            if (fout)
//                fclose(fout);
//
//            if (!err)
//            {
//                fz_write_document(doc, tmp, &opts);
//                written = 1;
//            }
//        }
//        fz_catch(ctx)
//        {
//            written = 0;
//        }
//
//        if (written)
//        {
//            rename(tmp, current_path);
//        }
//
//        free(tmp);
//    }
//}
//
//NSString *textAsHtml(fz_document *doc, int pageNum)
//{
//    NSString *str = nil;
//    fz_page *page = NULL;
//    fz_text_sheet *sheet = NULL;
//    fz_text_page *text = NULL;
//    fz_device *dev = NULL;
//    fz_matrix ctm;
//    fz_buffer *buf = NULL;
//    fz_output *out = NULL;
//
//    fz_var(page);
//    fz_var(sheet);
//    fz_var(text);
//    fz_var(dev);
//    fz_var(buf);
//    fz_var(out);
//
//    fz_try(ctx)
//    {
//        ctm = fz_identity;
//        sheet = fz_new_text_sheet(ctx);
//        text = fz_new_text_page(ctx);
//        dev = fz_new_text_device(ctx, sheet, text);
//        page = fz_load_page(doc, pageNum);
//        fz_run_page(doc, page, dev, &ctm, NULL);
//        fz_free_device(dev);
//        dev = NULL;
//
//        fz_analyze_text(ctx, sheet, text);
//
//        buf = fz_new_buffer(ctx, 256);
//        out = fz_new_output_with_buffer(ctx, buf);
//        fz_printf(out, "<html>\n");
//        fz_printf(out, "<style>\n");
//        fz_printf(out, "body{margin:0;}\n");
//        fz_printf(out, "div.page{background-color:white;}\n");
//        fz_printf(out, "div.block{margin:0pt;padding:0pt;}\n");
//        fz_printf(out, "div.metaline{display:table;width:100%%}\n");
//        fz_printf(out, "div.line{display:table-row;}\n");
//        fz_printf(out, "div.cell{display:table-cell;padding-left:0.25em;padding-right:0.25em}\n");
//        //fz_printf(out, "p{margin:0;padding:0;}\n");
//        fz_printf(out, "</style>\n");
//        fz_printf(out, "<body style=\"margin:0\"><div style=\"padding:10px\" id=\"content\">");
//        fz_print_text_page_html(ctx, out, text);
//        fz_printf(out, "</div></body>\n");
//        fz_printf(out, "<style>\n");
//        fz_print_text_sheet(ctx, out, sheet);
//        fz_printf(out, "</style>\n</html>\n");
//        fz_close_output(out);
//        out = NULL;
//
//        str = [[NSString alloc] initWithBytes:buf->data length:buf->len encoding:NSUTF8StringEncoding];
//    }
//    fz_always(ctx)
//    {
//        fz_free_text_page(ctx, text);
//        fz_free_text_sheet(ctx, sheet);
//        fz_free_device(dev);
//        fz_close_output(out);
//        fz_drop_buffer(ctx, buf);
//        fz_free_page(doc, page);
//    }
//    fz_catch(ctx)
//    {
//        str = nil;
//    }
//
//    return str;
//}
//
//static UIImage *newImageWithPixmap(fz_pixmap *pix, CGDataProviderRef cgdata)
//{
//    CGImageRef cgimage = CreateCGImageWithPixmap(pix, cgdata);
//    UIImage *image = [[UIImage alloc] initWithCGImage: cgimage scale: screenScale orientation: UIImageOrientationUp];
//    CGImageRelease(cgimage);
//    return image;
//}
//
//static NSArray *enumerateWidgetRects(fz_document *doc, fz_page *page)
//{
//    pdf_document *idoc = pdf_specifics(doc);
//    pdf_widget *widget;
//    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:10];
//
//    if (!idoc)
//        return nil;
//
//    for (widget = pdf_first_widget(idoc, (pdf_page *)page); widget; widget = pdf_next_widget(widget))
//    {
//        fz_rect rect;
//
//        pdf_bound_widget(widget, &rect);
//        [arr addObject:[NSValue valueWithCGRect:CGRectMake(
//                                                           rect.x0,
//                                                           rect.y0,
//                                                           rect.x1-rect.x0,
//                                                           rect.y1-rect.y0)]];
//    }
//
//    return arr;
//}
//
//static NSArray *enumerateAnnotations(fz_document *doc, fz_page *page)
//{
//    fz_annot *annot;
//    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:10];
//
//    for (annot = fz_first_annot(doc, page); annot; annot = fz_next_annot(doc, annot))
//        [arr addObject:[MuAnnotation annotFromAnnot:annot forDoc:doc]];
//
//    return arr;
//}
//
//static NSArray *enumerateWords(fz_document *doc, fz_page *page)
//{
//    fz_text_sheet *sheet = NULL;
//    fz_text_page *text = NULL;
//    fz_device *dev = NULL;
//    NSMutableArray *lns = [NSMutableArray array];
//    NSMutableArray *wds;
//    MuWord *word;
//
//    if (!lns)
//        return NULL;
//
//    fz_var(sheet);
//    fz_var(text);
//    fz_var(dev);
//
//    fz_try(ctx);
//    {
//        int b, l, c;
//
//        sheet = fz_new_text_sheet(ctx);
//        text = fz_new_text_page(ctx);
//        dev = fz_new_text_device(ctx, sheet, text);
//        fz_run_page(doc, page, dev, &fz_identity, NULL);
//        fz_free_device(dev);
//        dev = NULL;
//
//        for (b = 0; b < text->len; b++)
//        {
//            fz_text_block *block;
//
//            if (text->blocks[b].type != FZ_PAGE_BLOCK_TEXT)
//                continue;
//
//            block = text->blocks[b].u.text;
//
//            for (l = 0; l < block->len; l++)
//            {
//                fz_text_line *line = &block->lines[l];
//                fz_text_span *span;
//
//                wds = [NSMutableArray array];
//                if (!wds)
//                    fz_throw(ctx, FZ_ERROR_GENERIC, "Failed to create word array");
//
//                word = [MuWord word];
//                if (!word)
//                    fz_throw(ctx, FZ_ERROR_GENERIC, "Failed to create word");
//
//                for (span = line->first_span; span; span = span->next)
//                {
//                    for (c = 0; c < span->len; c++)
//                    {
//                        fz_text_char *ch = &span->text[c];
//                        fz_rect bbox;
//                        CGRect rect;
//
//                        fz_text_char_bbox(&bbox, span, c);
//                        rect = CGRectMake(bbox.x0, bbox.y0, bbox.x1 - bbox.x0, bbox.y1 - bbox.y0);
//
//                        if (ch->c != ' ')
//                        {
//                            [word appendChar:ch->c withRect:rect];
//                        }
//                        else if (word.string.length > 0)
//                        {
//                            [wds addObject:word];
//                            word = [MuWord word];
//                            if (!word)
//                                fz_throw(ctx, FZ_ERROR_GENERIC, "Failed to create word");
//                        }
//                    }
//                }
//
//                if (word.string.length > 0)
//                    [wds addObject:word];
//
//                if ([wds count] > 0)
//                    [lns addObject:wds];
//            }
//        }
//    }
//    fz_always(ctx);
//    {
//        fz_free_text_page(ctx, text);
//        fz_free_text_sheet(ctx, sheet);
//        fz_free_device(dev);
//    }
//    fz_catch(ctx)
//    {
//        lns = NULL;
//    }
//
//    return lns;
//}
//
//static void addMarkupAnnot(fz_document *doc, fz_page *page, int type, NSArray *rects)
//{
//    pdf_document *idoc;
//    fz_point *quadpts = NULL;
//    float color[3];
//    float alpha;
//    float line_height;
//    float line_thickness;
//
//    idoc = pdf_specifics(doc);
//    if (!idoc)
//        return;
//
//    switch (type)
//    {
//        case FZ_ANNOT_HIGHLIGHT:
//            color[0] = 1.0;
//            color[1] = 1.0;
//            color[2] = 0.0;
//            alpha = 0.5;
//            line_thickness = 1.0;
//            line_height = 0.5;
//            break;
//        case FZ_ANNOT_UNDERLINE:
//            color[0] = 0.0;
//            color[1] = 0.0;
//            color[2] = 1.0;
//            alpha = 1.0;
//            line_thickness = LINE_THICKNESS;
//            line_height = UNDERLINE_HEIGHT;
//            break;
//        case FZ_ANNOT_STRIKEOUT:
//            color[0] = 1.0;
//            color[1] = 0.0;
//            color[2] = 0.0;
//            alpha = 1.0;
//            line_thickness = LINE_THICKNESS;
//            line_height = STRIKE_HEIGHT;
//            break;
//
//        default:
//            return;
//    }
//
//    fz_var(quadpts);
//    fz_try(ctx)
//    {
//        int i;
//        pdf_annot *annot;
//
//        quadpts = fz_malloc_array(ctx, rects.count * 4, sizeof(fz_point));
//        for (i = 0; i < rects.count; i++)
//        {
//            CGRect rect = [[rects objectAtIndex:i] CGRectValue];
//            float top = rect.origin.y;
//            float bot = top + rect.size.height;
//            float left = rect.origin.x;
//            float right = left + rect.size.width;
//            quadpts[i*4].x = left;
//            quadpts[i*4].y = bot;
//            quadpts[i*4+1].x = right;
//            quadpts[i*4+1].y = bot;
//            quadpts[i*4+2].x = right;
//            quadpts[i*4+2].y = top;
//            quadpts[i*4+3].x = left;
//            quadpts[i*4+3].y = top;
//        }
//
//        annot = pdf_create_annot(idoc, (pdf_page *)page, type);
//        pdf_set_markup_annot_quadpoints(idoc, annot, quadpts, rects.count*4);
//        pdf_set_markup_appearance(idoc, annot, color, alpha, line_thickness, line_height);
//    }
//    fz_always(ctx)
//    {
//        fz_free(ctx, quadpts);
//    }
//    fz_catch(ctx)
//    {
//        printf("Annotation creation failed\n");
//    }
//}
//
//static void addInkAnnot(fz_document *doc, fz_page *page, NSArray *curves)
//{
//    pdf_document *idoc;
//    fz_point *pts = NULL;
//    int *counts = NULL;
//    int total;
//    float color[3] = {1.0, 0.0, 0.0};
//
//    idoc = pdf_specifics(doc);
//    if (!idoc)
//        return;
//
//    fz_var(pts);
//    fz_var(counts);
//    fz_try(ctx)
//    {
//        int i, j, k, n;
//        pdf_annot *annot;
//
//        n = curves.count;
//
//        counts = fz_malloc_array(ctx, n, sizeof(int));
//        total = 0;
//
//        for (i = 0; i < n; i++)
//        {
//            NSArray *curve = [curves objectAtIndex:i];
//            counts[i] = curve.count;
//            total += curve.count;
//        }
//
//        pts = fz_malloc_array(ctx, total, sizeof(fz_point));
//
//        k = 0;
//        for (i = 0; i < n; i++)
//        {
//            NSArray *curve = [curves objectAtIndex:i];
//            int count = counts[i];
//
//            for (j = 0; j < count; j++)
//            {
//                CGPoint pt = [[curve objectAtIndex:j] CGPointValue];
//                pts[k].x = pt.x;
//                pts[k].y = pt.y;
//                k++;
//            }
//        }
//
//        annot = pdf_create_annot(idoc, (pdf_page *)page, FZ_ANNOT_INK);
//        pdf_set_ink_annot_list(idoc, annot, pts, counts, n, color, INK_THICKNESS);
//    }
//    fz_always(ctx)
//    {
//        fz_free(ctx, pts);
//        fz_free(ctx, counts);
//    }
//    fz_catch(ctx)
//    {
//        printf("Annotation creation failed\n");
//    }
//}
//
//static void deleteAnnotation(fz_document *doc, fz_page *page, int index)
//{
//    pdf_document *idoc = pdf_specifics(doc);
//    if (!idoc)
//        return;
//
//    fz_try(ctx)
//    {
//        int i;
//        fz_annot *annot = fz_first_annot(doc, page);
//        for (i = 0; i < index && annot; i++)
//            annot = fz_next_annot(doc, annot);
//
//        if (annot)
//            pdf_delete_annot(idoc, (pdf_page *)page, (pdf_annot *)annot);
//    }
//    fz_catch(ctx)
//    {
//        printf("Annotation deletion failed\n");
//    }
//}
//
//static int setFocussedWidgetText(fz_document *doc, fz_page *page, const char *text)
//{
//    int accepted = 0;
//
//    fz_var(accepted);
//
//    fz_try(ctx)
//    {
//        pdf_document *idoc = pdf_specifics(doc);
//        if (idoc)
//        {
//            pdf_widget *focus = pdf_focused_widget(idoc);
//            if (focus)
//            {
//                accepted = pdf_text_widget_set_text(idoc, focus, (char *)text);
//            }
//        }
//    }
//    fz_catch(ctx)
//    {
//        accepted = 0;
//    }
//
//    return accepted;
//}
//
//static int setFocussedWidgetChoice(fz_document *doc, fz_page *page, const char *text)
//{
//    int accepted = 0;
//
//    fz_var(accepted);
//
//    fz_try(ctx)
//    {
//        pdf_document *idoc = pdf_specifics(doc);
//        if (idoc)
//        {
//            pdf_widget *focus = pdf_focused_widget(idoc);
//            if (focus)
//            {
//                pdf_choice_widget_set_value(idoc, focus, 1, (char **)&text);
//                accepted = 1;
//            }
//        }
//    }
//    fz_catch(ctx)
//    {
//        accepted = 0;
//    }
//
//    return accepted;
//}
//
//static fz_display_list *create_page_list(fz_document *doc, fz_page *page)
//{
//    fz_display_list *list = NULL;
//    fz_device *dev = NULL;
//
//    fz_var(dev);
//    fz_try(ctx)
//    {
//        list = fz_new_display_list(ctx);
//        dev = fz_new_list_device(ctx, list);
//        fz_run_page_contents(doc, page, dev, &fz_identity, NULL);
//    }
//    fz_always(ctx)
//    {
//        fz_free_device(dev);
//    }
//    fz_catch(ctx)
//    {
//        return NULL;
//    }
//
//    return list;
//}
//
//static fz_display_list *create_annot_list(fz_document *doc, fz_page *page)
//{
//    fz_display_list *list = NULL;
//    fz_device *dev = NULL;
//
//    fz_var(dev);
//    fz_try(ctx)
//    {
//        fz_annot *annot;
//        pdf_document *idoc = pdf_specifics(doc);
//
//        if (idoc)
//            pdf_update_page(idoc, (pdf_page *)page);
//        list = fz_new_display_list(ctx);
//        dev = fz_new_list_device(ctx, list);
//        for (annot = fz_first_annot(doc, page); annot; annot = fz_next_annot(doc, annot))
//            fz_run_annot(doc, page, annot, dev, &fz_identity, NULL);
//    }
//    fz_always(ctx)
//    {
//        fz_free_device(dev);
//    }
//    fz_catch(ctx)
//    {
//        return NULL;
//    }
//
//    return list;
//}
//
//static fz_pixmap *renderPixmap(fz_document *doc, fz_display_list *page_list, fz_display_list *annot_list, CGSize pageSize, CGSize screenSize, CGRect tileRect, float zoom)
//{
//    fz_irect bbox;
//    fz_rect rect;
//    fz_matrix ctm;
//    fz_device *dev = NULL;
//    fz_pixmap *pix = NULL;
//    CGSize scale;
//
//    screenSize.width *= screenScale;
//    screenSize.height *= screenScale;
//    tileRect.origin.x *= screenScale;
//    tileRect.origin.y *= screenScale;
//    tileRect.size.width *= screenScale;
//    tileRect.size.height *= screenScale;
//
//    scale = fitPageToScreen(pageSize, screenSize);
//    fz_scale(&ctm, scale.width * zoom, scale.height * zoom);
//
//    bbox.x0 = tileRect.origin.x;
//    bbox.y0 = tileRect.origin.y;
//    bbox.x1 = tileRect.origin.x + tileRect.size.width;
//    bbox.y1 = tileRect.origin.y + tileRect.size.height;
//    fz_rect_from_irect(&rect, &bbox);
//
//    fz_var(dev);
//    fz_var(pix);
//    fz_try(ctx)
//    {
//        pix = fz_new_pixmap_with_bbox(ctx, fz_device_rgb(ctx), &bbox);
//        fz_clear_pixmap_with_value(ctx, pix, 255);
//
//        dev = fz_new_draw_device(ctx, pix);
//        fz_run_display_list(page_list, dev, &ctm, &rect, NULL);
//        fz_run_display_list(annot_list, dev, &ctm, &rect, NULL);
//    }
//    fz_always(ctx)
//    {
//        fz_free_device(dev);
//    }
//    fz_catch(ctx)
//    {
//        fz_drop_pixmap(ctx, pix);
//        return NULL;
//    }
//
//    return pix;
//}
//
//static void drop_list(rect_list *list)
//{
//    while (list)
//    {
//        rect_list *n = list->next;
//        fz_free(ctx, list);
//        list = n;
//    }
//}
//
//static rect_list *updatePage(fz_document *doc, fz_page *page)
//{
//    rect_list *list = NULL;
//
//    fz_var(list);
//    fz_try(ctx)
//    {
//        pdf_document *idoc = pdf_specifics(doc);
//
//        if (idoc)
//        {
//            fz_annot *annot;
//
//            pdf_update_page(idoc, (pdf_page *)page);
//            while ((annot = (fz_annot *)pdf_poll_changed_annot(idoc, (pdf_page *)page)) != NULL)
//            {
//                rect_list *node = fz_malloc_struct(ctx, rect_list);
//
//                fz_bound_annot(doc, annot, &node->rect);
//                node->next = list;
//                list = node;
//            }
//        }
//    }
//    fz_catch(ctx)
//    {
//        drop_list(list);
//        list = NULL;
//    }
//
//    return list;
//}
//
//static void updatePixmap(fz_document *doc, fz_display_list *page_list, fz_display_list *annot_list, fz_pixmap *pixmap, rect_list *rlist, CGSize pageSize, CGSize screenSize, CGRect tileRect, float zoom)
//{
//    fz_irect bbox;
//    fz_rect rect;
//    fz_matrix ctm;
//    fz_device *dev = NULL;
//    CGSize scale;
//
//    screenSize.width *= screenScale;
//    screenSize.height *= screenScale;
//    tileRect.origin.x *= screenScale;
//    tileRect.origin.y *= screenScale;
//    tileRect.size.width *= screenScale;
//    tileRect.size.height *= screenScale;
//
//    scale = fitPageToScreen(pageSize, screenSize);
//    fz_scale(&ctm, scale.width * zoom, scale.height * zoom);
//
//    bbox.x0 = tileRect.origin.x;
//    bbox.y0 = tileRect.origin.y;
//    bbox.x1 = tileRect.origin.x + tileRect.size.width;
//    bbox.y1 = tileRect.origin.y + tileRect.size.height;
//    fz_rect_from_irect(&rect, &bbox);
//
//    fz_var(dev);
//    fz_try(ctx)
//    {
//        while (rlist)
//        {
//            fz_irect abox;
//            fz_rect arect = rlist->rect;
//            fz_transform_rect(&arect, &ctm);
//            fz_intersect_rect(&arect, &rect);
//            fz_round_rect(&abox, &arect);
//            if (!fz_is_empty_irect(&abox))
//            {
//                fz_clear_pixmap_rect_with_value(ctx, pixmap, 255, &abox);
//                dev = fz_new_draw_device_with_bbox(ctx, pixmap, &abox);
//                fz_run_display_list(page_list, dev, &ctm, &arect, NULL);
//                fz_run_display_list(annot_list, dev, &ctm, &arect, NULL);
//                fz_free_device(dev);
//                dev = NULL;
//            }
//            rlist = rlist->next;
//        }
//    }
//    fz_always(ctx)
//    {
//        fz_free_device(dev);
//    }
//    fz_catch(ctx)
//    {
//    }
//}
//
//static fz_page *getPage(fz_document *doc, int pageIndex)
//{
//    __block fz_page *page = NULL;
//
//    dispatch_sync(queue, ^{
//        fz_try(ctx)
//        {
//            page = fz_load_page(doc, pageIndex);
//        }
//        fz_catch(ctx)
//        {
//            printf("Failed to load page\n");
//        }
//    });
//
//    return page;
//}
//
//static CGSize getPageSize(fz_document *doc, fz_page *page)
//{
//    __block CGSize size = {0.0,0.0};
//
//    dispatch_sync(queue, ^{
//        fz_try(ctx)
//        {
//            fz_rect bounds;
//            fz_bound_page(doc, page, &bounds);
//            size.width = bounds.x1 - bounds.x0;
//            size.height = bounds.y1 - bounds.y0;
//        }
//        fz_catch(ctx)
//        {
//            printf("Failed to find page bounds\n");
//        }
//    });
//
//    return size;
//}
//
//static fz_pixmap *createPixMap(CGSize size)
//{
//    __block fz_pixmap *pix = NULL;
//
//    dispatch_sync(queue, ^{
//        fz_try(ctx)
//        {
//            pix = fz_new_pixmap(ctx, fz_device_rgb(ctx), size.width, size.height);
//        }
//        fz_catch(ctx)
//        {
//            printf("Failed to create pixmap\n");
//        }
//    });
//
//    return pix;
//}
//
//static void freePage(fz_document *doc, fz_page *page)
//{
//    dispatch_sync(queue, ^{
//        fz_free_page(doc, page);
//    });
//}
//
//static void renderPage(fz_document *doc, fz_page *page, fz_pixmap *pix, fz_matrix *ctm)
//{
//    dispatch_sync(queue, ^{
//        fz_device *dev = NULL;
//        fz_var(dev);
//        fz_try(ctx)
//        {
//            dev = fz_new_draw_device(ctx, pix);
//            fz_clear_pixmap_with_value(ctx, pix, 0xFF);
//            fz_run_page(doc, page, dev, ctm, NULL);
//        }
//        fz_always(ctx)
//        {
//            fz_free_device(dev);
//        }
//        fz_catch(ctx)
//        {
//            printf("Failed to render page\n");
//        }
//    });
//}

@implementation MuPDFCore

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
    docRef = [[MuDocRef alloc] initWithFilename:path];
    return docRef != nil;
}

- (void) closeFile {
    dispatch_sync(queue, ^{});
    if (docRef != nil) {
        fz_close_document(docRef->doc);
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

- (void) drawPage: (int)index pageWidth: (int)width pageHeight: (int)height patchX: (int)patchX patchY: (int)patchY patchWidth: (int)patchWidth patchHeight: (int)patchHeight {
    if (index < 0 || index >= fz_count_pages(docRef->doc))
        return;
    dispatch_async(queue, ^{
       	fz_pixmap *pixmap;
        CGDataProviderRef imageData;
        
        printf("render page %d\n", index);
        //        [self ensureDisplaylists];
        //        CGSize scale = fitPageToScreen(pageSize, self.bounds.size);
        //        CGRect rect = (CGRect){ { 0.0, 0.0 }, { pageSize.width * scale.width, pageSize.height * scale.height } };
        //        pixmap = renderPixmap(doc, page_list, annot_list, pageSize, self.bounds.size, rect, 1.0);
        //        CGDataProviderRelease(imageData);
        //        imageData = [self createWrappedPixmap: pixmap];
        //        UIImage *image = [self newImageWithPixmap: pixmap imageData: imageData];
        
        //        UIImageJPEGRepresentation(<#UIImage *image#>, <#CGFloat compressionQuality#>)
        //        UIImagePNGRepresentation(<#UIImage *image#>)
        
        
        //        widgetRects = enumerateWidgetRects(doc, page);
        //        [self loadAnnotations];
        //        dispatch_async(dispatch_get_main_queue(), ^{
        //            [self displayImage: image];
        //            [image release];
        //        });
    });
}

/**
 * --------------------
 * private method
 * --------------------
 */
- (fz_page*) getPage: (int)index {
    __block fz_page* page = NULL;
    
    dispatch_sync(queue, ^{
        fz_try(ctx) {
            page = fz_load_page(docRef->doc, index);
        } fz_catch(ctx) {
            printf("Failed to load page\n");
        }
    });
    
    return page;
}
//
//- (void) ensurePageLoaded {
//    if (page)
//        return;
//
//    fz_try(ctx) {
//        fz_rect bounds;
//        page = fz_load_page(doc, number);
//        fz_bound_page(doc, page, &bounds);
//        pageSize.width = bounds.x1 - bounds.x0;
//        pageSize.height = bounds.y1 - bounds.y0;
//    } fz_catch(ctx) {
//        return;
//    }
//}
//
//- (void) ensureDisplaylists {
//    [self ensurePageLoaded];
//    if (!page)
//        return;
//
//    if (!page_list)
//        page_list = create_page_list(doc, page);
//
//    if (!annot_list)
//        annot_list = create_annot_list(doc, page);
//}

- (fz_pixmap*) createPixMap: (CGSize)size {
    __block fz_pixmap *pix = NULL;
    
    dispatch_sync(queue, ^{
        fz_try(ctx) {
            pix = fz_new_pixmap(ctx, fz_device_rgb(ctx), size.width, size.height);
        } fz_catch(ctx) {
            printf("Failed to create pixmap\n");
        }
    });
    
    return pix;
}

- (CGSize) fitPageToScreen: (CGSize)page screenSize: (CGSize)screen {
    float hscale = screen.width / page.width;
    float vscale = screen.height / page.height;
    float scale = fz_min(hscale, vscale);
    hscale = floorf(page.width * scale) / page.width;
    vscale = floorf(page.height * scale) / page.height;
    return CGSizeMake(hscale, vscale);
}

static void releasePixmap(void *info, const void *data, size_t size) {
    if (queue) {
        dispatch_async(queue, ^{
            fz_drop_pixmap(ctx, info);
        });
    } else {
        fz_drop_pixmap(ctx, info);
    }
}

- (CGDataProviderRef) createWrappedPixmap: (fz_pixmap*) pix {
    unsigned char *samples = fz_pixmap_samples(ctx, pix);
    int w = fz_pixmap_width(ctx, pix);
    int h = fz_pixmap_height(ctx, pix);
    return CGDataProviderCreateWithData(pix, samples, w * 4 * h, releasePixmap);
}

- (CGImageRef) createCGImageWithPixmap: (fz_pixmap*)pix data: (CGDataProviderRef)cgdata {
    int w = fz_pixmap_width(ctx, pix);
    int h = fz_pixmap_height(ctx, pix);
    CGColorSpaceRef cgcolor = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgimage = CGImageCreate(w, h, 8, 32, 4 * w, cgcolor, kCGBitmapByteOrderDefault, cgdata, NULL, NO, kCGRenderingIntentDefault);
    CGColorSpaceRelease(cgcolor);
    return cgimage;
}

- (UIImage*) newImageWithPixmap: (fz_pixmap*)pix imageData: (CGDataProviderRef)cgdata {
    CGImageRef cgimage = CreateCGImageWithPixmap(pix, cgdata);
    UIImage *image = [[UIImage alloc] initWithCGImage: cgimage scale: screenScale orientation: UIImageOrientationUp];
    CGImageRelease(cgimage);
    return image;
}

- (fz_pixmap*) renderPixmap: (fz_display_list*) page_list annotationList: (fz_display_list*)annotList pageSize: (CGSize)pageSize screenSize: (CGSize)screenSize tileRect: (CGRect)tileRect zoom: (float)zoom {
    fz_irect bbox;
    fz_rect rect;
    fz_matrix ctm;
    fz_device *dev = NULL;
    fz_pixmap *pix = NULL;
    CGSize scale;
    
    screenSize.width *= screenScale;
    screenSize.height *= screenScale;
    tileRect.origin.x *= screenScale;
    tileRect.origin.y *= screenScale;
    tileRect.size.width *= screenScale;
    tileRect.size.height *= screenScale;
    
    scale = [self fitPageToScreen: pageSize screenSize: screenSize];
    fz_scale(&ctm, scale.width * zoom, scale.height * zoom);
    
    bbox.x0 = tileRect.origin.x;
    bbox.y0 = tileRect.origin.y;
    bbox.x1 = tileRect.origin.x + tileRect.size.width;
    bbox.y1 = tileRect.origin.y + tileRect.size.height;
    fz_rect_from_irect(&rect, &bbox);
    
    fz_var(dev);
    fz_var(pix);
    fz_try(ctx) {
        pix = fz_new_pixmap_with_bbox(ctx, fz_device_rgb(ctx), &bbox);
        fz_clear_pixmap_with_value(ctx, pix, 255);
        dev = fz_new_draw_device(ctx, pix);
        fz_run_display_list(page_list, dev, &ctm, &rect, NULL);
        fz_run_display_list(annotList, dev, &ctm, &rect, NULL);
    } fz_always(ctx) {
        fz_free_device(dev);
    } fz_catch(ctx) {
        fz_drop_pixmap(ctx, pix);
        return NULL;
    }
    
    return pix;
}

@end