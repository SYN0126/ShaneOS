#include <limine.h>

// Limine 引导协议声明：让引导程序识别内核使用的协议版本。
__attribute__((used, section(".limine_requests_start")))
volatile uint64_t limine_requests_start_marker[] = LIMINE_REQUESTS_START_MARKER;

__attribute__((used, section(".limine_requests")))
volatile uint64_t limine_base_revision[] = LIMINE_BASE_REVISION(6);

__attribute__((used, section(".limine_requests_end")))
volatile uint64_t limine_requests_end_marker[] = LIMINE_REQUESTS_END_MARKER;

__attribute__((used, section(".limine_requests")))
volatile limine_framebuffer_request framebuffer_request{
    .id = LIMINE_FRAMEBUFFER_REQUEST_ID,
    .revision = 0,
    .response = nullptr
};

void xdraw_rect(limine_framebuffer *framebuffer, uint32_t color, uint64_t x, uint64_t y, uint64_t width, uint64_t height) {
    if(x+width>framebuffer->width|| y+height>framebuffer->height){
        return;
    }
    volatile uint32_t *pixels = static_cast<volatile uint32_t *>(framebuffer->address);
    uint64_t pixels_per_row = framebuffer->pitch / 4;

    for (uint64_t row = y; row < y + height; row++) {
        for (uint64_t col = x; col < x + width; col++) {
            pixels[row * pixels_per_row + col] = color;
        }
    }

}

// 内核入口：引导程序加载内核后，从这里开始执行。
extern "C" [[noreturn]] void kmain() {
    // 从这里开始，逐步写你自己的内核代码。
    limine_framebuffer_response *response = framebuffer_request.response;
    if (response == nullptr) {
        for (;;) {
            asm volatile ("cli; hlt");
        }
    }
    if (response->framebuffer_count == 0) {
        for (;;) {
            asm volatile ("cli; hlt");
        }
    }
    limine_framebuffer *framebuffer = response->framebuffers[0];
// 只处理：每像素 32 位，红、绿、蓝各占 8 位的格式。
if (framebuffer->bpp != 32 ||
    framebuffer->memory_model != LIMINE_FRAMEBUFFER_RGB ||
    framebuffer->red_mask_size != 8 ||
    framebuffer->green_mask_size != 8 ||
    framebuffer->blue_mask_size != 8) {
    for (;;) {
        asm volatile ("cli; hlt");
    }
}

// 取得像素内存的起始地址。
volatile uint32_t *pixels =
    static_cast<volatile uint32_t *>(framebuffer->address);

// 每一行实际占用的内存，能容纳多少个 32 位整数。
uint64_t pixels_per_row = framebuffer->pitch / 4;

// 按屏幕规定的位置，组合红、绿、蓝三个颜色分量。
uint32_t color =0x00000000;
for (uint64_t y = 0; y < framebuffer->height; y++) {
    for (uint64_t x = 0; x < framebuffer->width; x++) {
        pixels[y * pixels_per_row + x] = color;
    }
}
xdraw_rect(framebuffer, 0x00FFFFFF, 0, 0, 32, 32);
    // 目前只关闭中断并停住 CPU；内核入口不能像普通函数一样返回。
    for (;;) {
        asm volatile ("cli; hlt");
    }
}
