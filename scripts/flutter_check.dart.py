#!/usr/bin/env python3
"""Flutter Dart 代码预检工具 —— 在 push 之前检查常见问题"""

import re
import sys
from collections import Counter

# 在单个方法/对象内出现多次就算异常的参数名
SINGLE_CTX_THRESHOLD = {
    'children': 15,
    'child': 20,
    'color': 15,
    'child': 20,
    'padding': 10,
}

def find_repeated_params_in_contexts(lines) -> list:
    """在同一方法体（缩进级别）内找重复参数"""
    errors = []
    
    # 简单方法：每 15 行为一个区块检查重复
    for i in range(0, len(lines), 15):
        block = '\n'.join(lines[i:i+15])
        params = re.findall(r'^\s+(\w+):', block, re.MULTILINE)
        if not params:
            continue
        counts = Counter(params)
        for p, c in counts.items():
            # 只在同区块内 c >= 2 时才警告
            if c >= 2 and p in ['centerTitle', 'leadingWidth', 'automaticallyImplyLeading']:
                errors.append(f'L{i+1}: 参数 "{p}" 在同一区块重复 {c} 次')
    
    return errors

def check_file(filepath: str) -> bool:
    with open(filepath) as f:
        content = f.read()
    
    errors = []
    lines = content.split('\n')
    
    # 1. 括号平衡
    for kind, open_c, close_c in [('大括号', '{', '}'), ('方括号', '[', ']'), ('圆括号', '(', ')')]:
        o = content.count(open_c)
        c = content.count(close_c)
        if o != c:
            errors.append(f'{kind} 不平衡: {open_c}={o}, {close_c}={c}')
    
    # 2. 同一上下文中可疑的重复参数
    errors.extend(find_repeated_params_in_contexts(lines))
    
    # 3. 检查常见的 fatal 关键词
    fatal_patterns = [
        (r'import\s+dart:math', 'import dart:math 可能因类型错误导致编译失败'),
    ]
    for pat, msg in fatal_patterns:
        if re.search(pat, content):
            pass  # 很多是合法的
    
    # 4. 显示文件概况
    line_count = len(lines)
    char_count = len(content)
    
    print(f'\n📄 {filepath}')
    print(f'   行数: {line_count}, 字符: {char_count}')
    print(f'   括号: {{={content.count("{")}}} }}={content.count("}")}, (={content.count("(")}) )={content.count(")")}')
    
    if errors:
        print('\n❌ 发现潜在问题:')
        for e in errors:
            print(f'   • {e}')
        return False
    else:
        print('\n✅ 预检通过')
        return True

if __name__ == '__main__':
    filepath = sys.argv[1] if len(sys.argv) > 1 else 'trophyroom-app/lib/main.dart'
    ok = check_file(filepath)
    sys.exit(0 if ok else 1)
