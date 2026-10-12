# -*- coding: utf-8 -*-
"""PRD 同步脚本：docx -> md
用法：python tools/docx2md.py（在仓库根目录执行）
保证 docs/requirements.md 与 docs/requirements.docx 内容一致（源为 tools/gen_prd_v2.py 生成的 docx）。
"""
import io
import os
import re
from docx import Document
from docx.table import Table
from docx.text.paragraph import Paragraph
from docx.oxml.ns import qn

# 仓库根目录（本脚本位于 tools/ 下，故取上一级），避免硬编码本机绝对路径
BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(BASE, "docs", "requirements.docx")
OUT = os.path.join(BASE, "docs", "requirements.md")

doc = Document(SRC)


def iter_block_items(parent):
    for child in parent.element.body.iterchildren():
        if child.tag == qn('w:p'):
            yield Paragraph(child, parent)
        elif child.tag == qn('w:tbl'):
            yield Table(child, parent)


def inline_md(par):
    parts = []
    for r in par.runs:
        t = r.text
        if not t:
            continue
        parts.append('**' + t + '**' if r.bold else t)
    return ''.join(parts)


def esc_cell(s):
    return s.replace('|', '\\|').replace('\n', '<br>')


lines = []
for block in iter_block_items(doc):
    if isinstance(block, Paragraph):
        st = (block.style.name or '').lower()
        txt = inline_md(block).strip()
        if not txt:
            continue
        if st.startswith('heading 1'):
            lines.append('# ' + txt)
        elif st.startswith('heading 2'):
            lines.append('## ' + txt)
        elif st.startswith('heading 3'):
            lines.append('### ' + txt)
        elif st.startswith('list bullet 2'):
            lines.append('  - ' + txt)
        elif st.startswith('list bullet'):
            lines.append('- ' + txt)
        else:
            lines.append(txt)
        lines.append('')
    elif isinstance(block, Table):
        rows = [[esc_cell(c.text.strip()) for c in row.cells] for row in block.rows]
        if not rows:
            continue
        n = len(rows[0])
        md = ['| ' + ' | '.join(rows[0]) + ' |', '| ' + ' | '.join(['---'] * n) + ' |']
        for row in rows[1:]:
            while len(row) < n:
                row.append('')
            md.append('| ' + ' | '.join(row) + ' |')
        lines.extend(md)
        lines.append('')

md_text = re.sub(r'\n{3,}', '\n\n', '\n'.join(lines)).strip() + '\n'
io.open(OUT, 'w', encoding='utf-8', newline='\n').write(md_text)
print('md 已同步:', OUT, '|', len(md_text), 'chars')
