# IR Forge

*An MLIR/LLVM Compiler From Scratch*

Every program in this author's other books -- a CUDA kernel, a tensor compiler, a bare-metal kernel -- was itself *compiled* by something, and none of those books ever opened that box. This book opens it. It builds one real compiler, start to finish, for one small toy language: a real custom MLIR dialect to represent that language's own programs, real MLIR passes to transform and progressively lower that representation, and a real path through the actual LLVM backend to genuine native machine code that actually runs and produces the real, correct answer.

This book is independent: it does not assume or reference any other book in this author's series, and it builds everything from Chapter 1 rather than pointing elsewhere for it. What it keeps is the same discipline its sibling books follow: every piece of IR, every pass, and every generated binary in this book is genuinely built and genuinely run against a real, installed MLIR/LLVM toolchain -- not simulated, not hand-traced on paper. Where this book cites a real design decision behind MLIR or LLVM, it cites the project's own real, official documentation, read directly out of the `llvm/llvm-project` repository itself (the strongest real citation tier available, since that repository *is* the primary source), not a paraphrase from memory. Getting Started explains exactly which toolchain this book's own authoring environment has confirmed, and how.

## How to read this book

Every chapter follows the same shape: a concrete question about what a compiler actually has to do, answered first with real, working MLIR and/or LLVM IR rather than an abstract diagram, then a background section citing the real, official rationale behind the relevant dialect or pass, one or more worked examples with genuinely produced output (parsed, lowered, translated, compiled, and run, with the real tool output locked into the page), a chapter summary, self-check questions, and worked answers. This book's own table of contents grows one chapter at a time rather than being fixed in advance -- see `TABLE_OF_CONTENTS.md` in this book's own repository for its current, honest state.
