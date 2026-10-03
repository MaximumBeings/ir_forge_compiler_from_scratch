#!/usr/bin/env python3
"""Builds appendixD/d-self-check-answers.md from the "Self-check questions" section of every chapter page (parts 1-46), so the appendix cannot drift from the chapters.
Older chapters write each question in bold followed by a "Worked answer:" paragraph; newer ones write a numbered list whose answers are collapsed (`??? note "Answer"`). Both are copied; the collapsed
answers are opened up (shown as "**Answer.**") because a reader of this appendix is looking for the answers. Run from anywhere; rewrites the one output file."""
import glob, os, re
here = os.path.dirname(os.path.abspath(__file__)); docs = os.path.join(here, "..")
def key(p): return int(re.search(r"part(\d+)", p).group(1))
pages = sorted(glob.glob(os.path.join(docs, "part*", "[0-9]*.md")), key=key)
out = ["# Appendix D. Self-Check Answers", "",
       "Every chapter ends with a short *Self-check questions* section. On the chapter pages the newer ones keep each answer collapsed so you can try the question first; this appendix opens every answer in one place, "
       "in chapter order, for review or for looking one up. It is generated from the chapter pages by `appendixD/make_appendix_d.py` and is therefore always the same text as the chapters (nothing here is separately written). "
       "Questions that refer to a listing, a table or an output refer to the one on the chapter page.", ""]
n_q = 0
for p in pages:
    text = open(p).read(); title = re.search(r"^# (.+)$", text, re.M).group(1); num = key(p)
    m = re.search(r"^## Self-check questions\s*\n(.*?)(?=^## |\Z)", text, re.S | re.M)
    if not m: continue
    body = m.group(1).strip("\n").split("\n"); res = []; i = 0
    while i < len(body):
        line = body[i]
        if line.strip() == '??? note "Answer"':
            i += 1; first = True
            while i < len(body) and (body[i].startswith("        ") or body[i].strip() == ""):
                seg = body[i][8:] if body[i].startswith("        ") else ""
                if first and seg.strip(): res.append("    **Answer.** " + seg); first = False
                else: res.append("    " + seg if seg.strip() else "")
                i += 1
            continue
        res.append(line); i += 1
    text_out = "\n".join(l for l in res if l.strip() != "Each answer is collapsed; try the question first.").strip("\n"); n_q += len(re.findall(r"^(?:\*\*)?\d+[.)]", text_out, re.M))
    rel = os.path.relpath(p, here).replace(os.sep, "/")
    out += [f"## Chapter {num}", "", f"*(from [{title}]({rel}))*", "", text_out, "", "---", ""]
import sys
target = os.path.join(here, "d-self-check-answers.md"); new = "\n".join(out) + "\n"
if "--check" in sys.argv:        # exit 1 if the committed appendix differs from what the chapter pages produce now
    same = os.path.exists(target) and open(target).read() == new
    print("appendix D is up to date with the chapter pages" if same else "appendix D is STALE: run make_appendix_d.py"); sys.exit(0 if same else 1)
open(target, "w").write(new)
print(f"wrote d-self-check-answers.md: {len(pages)} chapters, {n_q} questions")
