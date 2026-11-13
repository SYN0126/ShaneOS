# ShaneOS

从最小 x86-64 C++ 内核开始，自己逐步实现系统功能。
当前只做到：UEFI → Limine → `kmain()` → 关闭中断并停住 CPU。
黑屏或残留引导画面是预期现象。

## 只需认识这些文件

```text
kernel/main.cpp    你写内核的地方，目前只有协议声明和停机循环
kernel/linker.ld   决定入口和内核各段的内存布局
limine.conf        告诉 Limine 内核在哪里
dev.sh             编译 → 链接 → 制作 ISO → 启动 QEMU
启动 ShaneOS.command 双击启动，无需输入命令
上传 GitHub.command  双击提交改动并上传 GitHub
tools/color-picker.html 离线调色盘：颜色、RGB、32 位色值与 C++ 代码
tools/font-editor.html  离线字模编辑器：n×n 黑白网格，点击或拖动绘制
vendor/            借用的引导程序、协议头文件和一份 x86-64 固件
build/             自动生成的文件，可以通过 clean 清除
```

不再使用 Makefile、依赖下载脚本、其他 CPU 架构、BIOS 启动或硬盘镜像构建。
`vendor/` 中保留现有第三方文件，构建不联网下载，也不隐藏在自动安装流程里。
隐藏的 `.git/` 和 `.workbuddy-ai/` 是开发工具的记录，不参与内核构建。

## 操作

在 Finder 中双击 `启动 ShaneOS.command`，会自动打开终端、编译并启动 QEMU，无需输入命令。
修改代码并保存后，退出旧 QEMU，再双击一次即可运行新代码。
关闭系统：切换到 QEMU 后按 Command+Q，或在启动它的终端按 Control+C。

版本管理：双击 `上传 GitHub.command`，在弹窗中填写本次修改说明并点击“上传”。
留空会自动用时间命名；点击“取消”不会提交。脚本会提交项目内的全部改动并推送当前分支。
上传失败时，已经提交的版本仍保存在本地，可以再次双击重试。
仓库：[SYN0126/ShaneOS](https://github.com/SYN0126/ShaneOS)，初始设为私有。
上传入口需要本机 GitHub CLI 已登录；编译产物和助手的本地记录不上传。

需要手动编译或清理时，也可以在 macOS 终端中执行：

```sh
cd /Users/syn/Desktop/ShaneOs
./dev.sh run       # 编译并启动
./dev.sh build     # 只编译，生成 build/shaneos.iso
./dev.sh clean     # 删除 build/，保留源代码和第三方文件
```

回到启动它的终端按 Control+C，或切换到 QEMU 按 Command+Q 退出。
修改代码后保存，退出旧 QEMU，再运行 `./dev.sh run`。
默认内存为 512 MiB，没有挂载可写硬盘。改为 1 GiB：

```sh
MEMORY=1G ./dev.sh run
```

环境需要 Homebrew 的 `llvm`、`lld`、`qemu`、`xorriso`。
脚本只编译 `kernel/main.cpp`，以后增加源文件时，自己在编译和链接步骤中加入。
内存复制函数、分配器、C++ 动态初始化等运行时支持均未预先实现；
需要时再添加，例如链接器提示 `memcpy` 未定义时，再亲手实现该函数。
读取 Limine 返回的信息前，需要检查协议版本和请求结果。

## 调色盘

双击 `tools/color-picker.html` 即可在浏览器中使用，无需联网或启动 ShaneOS。
拖动 RGB、选择颜色或输入网页十六进制颜色后，会显示对应的 32 位整数和可复制的 C++ 代码。
默认排列是 R shift = 16、G shift = 8、B shift = 0；可切换或自定义位移，
也可输入 8 位十六进制整数反查颜色。请以实际 framebuffer 的格式为准，
优先复制使用 `framebuffer->*_mask_shift` 的代码，以适应设备的颜色排列。

## 字库测试

字库测试：双击 `tools/font-editor.html`，选择 1～64 的边长并生成 n×n 网格。
默认黑色，按住左键或用手指拖动涂白；右键或“擦黑”工具可擦除。
支持清空、撤销、无网格预览和复制 C++ 0/1 矩阵。生成新尺寸也可撤销。
结果自动保存在当前浏览器中，重新打开可继续编辑。

## 来源

初始模板：[Limine C++ Template](https://github.com/Limine-Bootloader/limine-cxx-template)，
导入提交 `a3ec9ee454fda77096f14968cf520c9d46111115`。模板许可证保留在根目录 `LICENSE`。
引导程序来自 [Limine](https://github.com/Limine-Bootloader/Limine)，
许可证和第三方声明保留在 `vendor/limine/`。
`limine.h` 来自 [Limine Protocol](https://github.com/Limine-Bootloader/limine-protocol)，
提交 `6e85ddd6f928b5b512015c4d47d1cfce2fd28079`，文件内含许可证。
UEFI 固件保留自原项目下载的 [OVMF 构建包](https://github.com/osdev0/edk2-ovmf-stable-bins)。
