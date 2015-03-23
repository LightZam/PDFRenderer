#undef ABS
#undef MIN
#undef MAX

#include "Common.h"
#include "mupdf/fitz.h"
#include "dispatch/dispatch.h"
#import "MuDocRef.h"

@interface MuPDFCore : NSObject {
    @public
    MuDocRef* docRef;
}
- (id) init;
- (BOOL) openFile: (char*)path;
- (void) closeFile;
- (NSInteger) countPages;
- (CGSize) getPageSize: (int)index;
- (BOOL) needsPassword;
- (BOOL) authenticatePassword: (char*)password;
- (BOOL) isFileOpen;
- (void) drawPage: (int)index pageWidth: (int)width pageHeight: (int)height patchX: (int)patchX patchY: (int)patchY patchWidth: (int)patchWidth patchHeight: (int)patchHeight;
@end

//CGSize fitPageToScreen(CGSize page, CGSize screen);
//int search_page(fz_document *doc, int number, char *needle, fz_cookie *cookie);
//fz_rect search_result_bbox(fz_document *doc, int i);
//CGDataProviderRef CreateWrappedPixmap(fz_pixmap *pix);
//CGImageRef CreateCGImageWithPixmap(fz_pixmap *pix, CGDataProviderRef cgdata);
//void flattenOutline(NSMutableArray *titles, NSMutableArray *pages, fz_outline *outline, int level);
//char *tmp_path(char *path);
//void saveDoc(char *current_path, fz_document *doc);
//NSString *textAsHtml(fz_document *doc, int pageNum);
//UIImage *newImageWithPixmap(fz_pixmap *pix, CGDataProviderRef cgdata);
//NSArray *enumerateWidgetRects(fz_document *doc, fz_page *page);
//NSArray *enumerateAnnotations(fz_document *doc, fz_page *page);
//NSArray *enumerateWords(fz_document *doc, fz_page *page);
//void addMarkupAnnot(fz_document *doc, fz_page *page, int type, NSArray *rects);
//void addInkAnnot(fz_document *doc, fz_page *page, NSArray *curves);
//void deleteAnnotation(fz_document *doc, fz_page *page, int index);
//int setFocussedWidgetText(fz_document *doc, fz_page *page, const char *text);
//int setFocussedWidgetChoice(fz_document *doc, fz_page *page, const char *text);
//fz_display_list *create_page_list(fz_document *doc, fz_page *page);
//fz_display_list *create_annot_list(fz_document *doc, fz_page *page);
//fz_pixmap *renderPixmap(fz_document *doc, fz_display_list *page_list, fz_display_list *annot_list, CGSize pageSize, CGSize screenSize, CGRect tileRect, float zoom);
//void drop_list(rect_list *list);
//rect_list *updatePage(fz_document *doc, fz_page *page);
//void updatePixmap(fz_document *doc, fz_display_list *page_list, fz_display_list *annot_list, fz_pixmap *pixmap, rect_list *rlist, CGSize pageSize, CGSize screenSize, CGRect tileRect, float zoom);
//fz_page *getPage(fz_document *doc, int pageIndex);
//CGSize getPageSize(fz_document *doc, fz_page *page);
//fz_pixmap *createPixMap(CGSize size);
//void freePage(fz_document *doc, fz_page *page);
//void renderPage(fz_document *doc, fz_page *page, fz_pixmap *pix, fz_matrix *ctm);

