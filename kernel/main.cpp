#include <limine.h>

// Limine 引导协议声明：让引导程序识别内核使用的协议版本。
__attribute__((used, section(".limine_requests_start")))
volatile uint64_t limine_requests_start_marker[] = LIMINE_REQUESTS_START_MARKER;

__attribute__((used, section(".limine_requests")))
volatile uint64_t limine_base_revision[] = LIMINE_BASE_REVISION(6);

__attribute__((used, section(".limine_requests_end")))
volatile uint64_t limine_requests_end_marker[] = LIMINE_REQUESTS_END_MARKER;

// 内核入口：引导程序加载内核后，从这里开始执行。
extern "C" [[noreturn]] void kmain() {
    // 从这里开始，逐步写你自己的内核代码。

    // 目前只关闭中断并停住 CPU；内核入口不能像普通函数一样返回。
    for (;;) {
        asm volatile ("cli; hlt");
    }
}
