#!/bin/bash
# ===== 我的工作台 · GitHub Pages 一键部署脚本 =====
# 用法：
#   1. 先运行 gh auth login 完成 GitHub 登录
#   2. 运行 bash deploy.sh [仓库名]  （默认仓库名：my-workbench）
#   3. 等待约 1 分钟后访问部署网址

set -e

REPO_NAME="${1:-my-workbench}"
DEPLOY_DIR="$(cd "$(dirname "$0")" && pwd)"

# 检查登录状态
if ! gh auth status >/dev/null 2>&1; then
  echo "❌ 还没有登录 GitHub，请先运行："
  echo "   gh auth login"
  echo ""
  echo "   选择 GitHub.com → HTTPS → Login with a web browser"
  echo "   按提示在浏览器中完成授权。"
  exit 1
fi

echo "✅ 已登录 GitHub"
gh api user --jq '.login' | xargs -I{} echo "   当前用户：{}"
echo ""

# 检查 index.html
if [ ! -f "$DEPLOY_DIR/index.html" ]; then
  echo "❌ 未找到 index.html，请确认文件在脚本同目录下"
  exit 1
fi

echo "📦 准备部署到仓库：$REPO_NAME"
echo ""

# 初始化 git 仓库
cd "$DEPLOY_DIR"
rm -rf .git
git init -q
git add index.html
git commit -q -m "部署我的工作台 - 律师每日工作台页面

功能包含：每日计划、设置、公司法学习、新闻早班车、天鹅臂锻炼
支持 JSONBin 云端同步跨设备访问"

# 创建远程仓库并推送
echo "🚀 正在创建 GitHub 仓库并推送..."
if gh repo create "$REPO_NAME" --public --source=. --push 2>/dev/null; then
  echo "✅ 仓库创建成功"
else
  echo "⚠️  仓库可能已存在，尝试直接推送..."
  git remote remove origin 2>/dev/null || true
  USERNAME=$(gh api user --jq '.login')
  git remote add origin "https://github.com/$USERNAME/$REPO_NAME.git"
  git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null || true
fi

# 开启 GitHub Pages
echo ""
echo "🌐 正在开启 GitHub Pages..."
USERNAME=$(gh api user --jq '.login')

# 尝试用 API 开启 Pages（发布到 main 分支根目录）
gh api "repos/$USERNAME/$REPO_NAME/pages" \
  -X POST \
  -f "source[branch]=main" \
  -f "source[path]=/" 2>/dev/null \
  || gh api "repos/$USERNAME/$REPO_NAME/pages" \
     -X PUT \
     -f "source[branch]=main" \
     -f "source[path]=/" 2>/dev/null \
     || true

echo ""
echo "========================================"
echo "✅ 部署完成！"
echo ""
echo "⏳ GitHub Pages 首次部署需要约 1-2 分钟生效。"
echo ""
echo "📍 你的工作台网址："
echo "   https://$USERNAME.github.io/$REPO_NAME/"
echo ""
echo "📋 仓库地址："
echo "   https://github.com/$USERNAME/$REPO_NAME"
echo ""
echo "💡 如果几分钟后仍无法访问，打开仓库 Settings → Pages，"
echo "   确认 Source 设置为 main 分支 / root 目录。"
echo "========================================"
