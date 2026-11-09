#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

echo '===== 뮤지컬 학전(學田) GitHub Pages 배포 ====='
for command in git gh; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "ERROR: $command 가 설치되지 않았습니다. 우분투에서 sudo apt update && sudo apt install -y git gh 명령을 실행하세요."
    exit 1
  fi
done

if ! gh auth status >/dev/null 2>&1; then
  echo 'GitHub 로그인이 필요합니다. 브라우저에서 본인 계정으로 인증하세요.'
  gh auth login -h github.com -p https -w
fi
USER_LOGIN=$(gh api user --jq '.login')
if [[ "$USER_LOGIN" != 'zooloo064291' ]]; then
  echo "ERROR: 로그인된 GitHub 사용자는 $USER_LOGIN 입니다. 예상 계정 zooloo064291 와 달라 배포를 중단합니다."
  echo '다른 계정으로 게시하려면 파일 내 canonical, robots.txt, sitemap.xml 주소도 변경해야 합니다.'
  exit 1
fi
REPO="$USER_LOGIN.github.io"

if [[ ! -d .git ]]; then
  if gh repo view "$USER_LOGIN/$REPO" >/dev/null 2>&1; then
    echo "ERROR: 원격 저장소 $REPO 가 이미 있습니다. 기존 파일을 덮어쓰지 않도록 중단합니다."
    echo '이미 저장소가 있는 경우 기존 repo로 clone한 뒤 파일을 안전하게 합쳐 주세요.'
    exit 1
  fi
  git init -b main
fi
if [[ -z "$(git config user.name || true)" ]]; then git config user.name "$USER_LOGIN"; fi
if [[ -z "$(git config user.email || true)" ]]; then
  USER_ID=$(gh api user --jq '.id')
  git config user.email "${USER_ID}+${USER_LOGIN}@users.noreply.github.com"
fi

git add index.html robots.txt sitemap.xml README.md .nojekyll .gitignore publish.sh verify_search.py
if ! git diff --cached --quiet; then git commit -m 'Publish Hakjeon internet mission hall'; fi
if ! git remote get-url origin >/dev/null 2>&1; then
  gh repo create "$REPO" --public --source=. --remote=origin --push
else
  git push -u origin main
fi

if ! gh api "repos/$USER_LOGIN/$REPO/pages" >/dev/null 2>&1; then
  gh api --method POST "repos/$USER_LOGIN/$REPO/pages" \
    -F 'source[branch]=main' -F 'source[path]=/' >/dev/null \
    || echo '자동 Pages 활성화는 실패했습니다. GitHub 저장소 > Settings > Pages 에서 Deploy from a branch / main / (root)로 설정하세요.'
fi
printf '\n배포 요청이 끝났습니다. GitHub Pages 배포가 완료되면 아래 주소로 접속하세요:\nhttps://%s.github.io/\n' "$USER_LOGIN"
