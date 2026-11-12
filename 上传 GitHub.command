#!/bin/sh
# 双击：填写版本说明，提交项目改动，再推送到 GitHub。
set -eu
cd "$(dirname "$0")"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# 失败时保留终端中的详细错误，并弹窗提示。
trap 'code=$?; if [ "$code" -ne 0 ]; then
    /usr/bin/osascript -e '\''display alert "上传未完成" message "请查看终端中的错误信息。已经提交的版本仍保存在本地，可以修复问题后再次双击重试。" as critical'\'' >/dev/null 2>&1 || :
fi' EXIT

command -v gh >/dev/null 2>&1
gh auth status >/dev/null 2>&1
git remote get-url origin
branch=$(git symbolic-ref --quiet --short HEAD)

if [ -n "$(git status --porcelain)" ]; then
    git -c core.quotePath=false status --short
    message=$(/usr/bin/osascript <<'APPLESCRIPT'
text returned of (display dialog "这次修改了什么？留空会自动填写时间。" default answer "" buttons {"取消", "上传"} default button "上传" cancel button "取消" with title "上传 ShaneOS")
APPLESCRIPT
    ) || exit 0
    if [ -z "$message" ]; then
        message="更新 ShaneOS $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    git add --all
    if ! git diff --cached --quiet; then
        git commit -m "$message"
    fi
fi

# 即使没有新改动，也会重试推送之前保存在本地的提交。
git -c credential.helper= -c 'credential.helper=!gh auth git-credential' \
    push --set-upstream origin "$branch"
/usr/bin/osascript -e 'display dialog "当前版本已同步到 GitHub。" buttons {"好"} default button "好" with title "ShaneOS 上传完成"' >/dev/null
