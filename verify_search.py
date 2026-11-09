#!/usr/bin/env python3
"""검색엔진에서 복사한 소유확인 메타태그의 content 값만 입력해 HTML에 반영."""
from pathlib import Path
import argparse
import html
import re
import sys

p = argparse.ArgumentParser(description='Google/Naver Search Console verification token setter')
p.add_argument('provider', choices=['google', 'naver'], help='google 또는 naver')
p.add_argument('token', help='소유확인 HTML 태그에서 content의 값만 입력')
a = p.parse_args()
if not re.fullmatch(r'[A-Za-z0-9_\-=:.]+', a.token):
    sys.exit('오류: 토큰 형식이 올바르지 않습니다. HTML 태그 전체가 아닌 content 값만 입력하세요.')
target = 'google-site-verification' if a.provider == 'google' else 'naver-site-verification'
file = Path(__file__).parent / 'index.html'
s = file.read_text(encoding='utf-8')
pattern = rf'(<meta name="{target}" content=")[^"]*(")'
s, n = re.subn(pattern, lambda m: m.group(1) + html.escape(a.token, quote=True) + m.group(2), s)
if n != 1:
    sys.exit(f'오류: {target} 태그를 정확히 하나 찾지 못했습니다.')
file.write_text(s, encoding='utf-8')
print(f'설정 완료: {target}. 이제 publish.sh로 변경 사항을 배포하세요.')
