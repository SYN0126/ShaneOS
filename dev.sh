#!/bin/sh
# 在 Mac 上编译内核、制作启动光盘，并用 QEMU 运行。
set -eu
cd "$(dirname "$0")"

action=${1:-run}
case "$action" in
    build|run|clean) ;;
    *) echo '用法：./dev.sh [run|build|clean]' >&2; exit 2 ;;
esac
if [ "$#" -gt 1 ]; then
    echo '只接受一个操作参数。内存可通过 MEMORY=1G ./dev.sh run 设置。' >&2
    exit 2
fi

# 避免覆盖正在使用的镜像。
if [ -f build/shaneos.iso ] && /usr/sbin/lsof -t "$PWD/build/shaneos.iso" >/dev/null 2>&1; then
    echo '请先退出正在运行的 QEMU。' >&2
    exit 1
fi
if [ "$action" = clean ]; then
    rm -rf build
    exit 0
fi

# 只为本脚本选择 Homebrew 工具，不修改终端配置。
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
brew_prefix=$(brew --prefix)
export PATH="$brew_prefix/opt/llvm/bin:$brew_prefix/opt/lld/bin:$PATH"
for tool in clang++ ld.lld xorriso; do
    command -v "$tool" >/dev/null 2>&1 || { echo "缺少工具：$tool" >&2; exit 1; }
done

# 1. 把唯一的 C++ 源文件编译为目标文件。
mkdir -p build
clang++ --target=x86_64-unknown-none-elf -std=c++20 \
    -ffreestanding -nostdinc++ -fno-exceptions -fno-rtti \
    -fno-stack-protector -fno-pic -mno-red-zone -mgeneral-regs-only \
    -mcmodel=kernel -O0 -g -Wall -Wextra -I vendor/limine \
    -c kernel/main.cpp -o build/main.o

# 2. 按链接脚本生成 ELF 内核。
ld.lld -m elf_x86_64 -static -z max-page-size=0x1000 \
    -T kernel/linker.ld build/main.o -o build/kernel

# 3. 把内核和 Limine 装进 UEFI 启动光盘。
mkdir -p build/iso/boot/limine build/iso/EFI/BOOT
cp build/kernel build/iso/boot/kernel
cp limine.conf vendor/limine/limine-uefi-cd.bin build/iso/boot/limine/
cp vendor/limine/BOOTX64.EFI build/iso/EFI/BOOT/
xorriso -as mkisofs -R -r -J \
    --efi-boot boot/limine/limine-uefi-cd.bin \
    -efi-boot-part --efi-boot-image --protective-msdos-label \
    build/iso -o build/shaneos.iso

# 4. 运行：512 MiB 内存，不挂载可写硬盘，不连接网络。
if [ "$action" = run ]; then
    exec qemu-system-x86_64 -M q35 -accel tcg -m "${MEMORY:-512M}" \
        -nic none -cdrom build/shaneos.iso \
        -drive if=pflash,format=raw,file=vendor/ovmf/ovmf-code-x86_64.fd,readonly=on
fi
