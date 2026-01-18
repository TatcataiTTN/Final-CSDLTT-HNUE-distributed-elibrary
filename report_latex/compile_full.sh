#!/bin/bash

echo "=========================================="
echo "🔨 COMPILING LATEX REPORT (4 PASSES)"
echo "=========================================="
echo ""

cd "$(dirname "$0")"

# Clean old files
echo "Step 1: Cleaning old auxiliary files..."
rm -f main.aux main.log main.out main.toc main.lof main.lot main.lol main.bbl main.blg compile_log.txt
echo "✅ Cleaned"
echo ""

# Pass 1
echo "Step 2: First compilation pass..."
pdflatex -interaction=nonstopmode main.tex > compile_log.txt 2>&1
if [ $? -ne 0 ]; then
    echo "❌ ERROR in pass 1!"
    tail -50 compile_log.txt
    exit 1
fi
echo "✅ Pass 1 complete"
echo ""

# Pass 2
echo "Step 3: Second compilation pass (for references)..."
pdflatex -interaction=nonstopmode main.tex >> compile_log.txt 2>&1
if [ $? -ne 0 ]; then
    echo "❌ ERROR in pass 2!"
    tail -50 compile_log.txt
    exit 1
fi
echo "✅ Pass 2 complete"
echo ""

# Pass 3
echo "Step 4: Third compilation pass (for TOC)..."
pdflatex -interaction=nonstopmode main.tex >> compile_log.txt 2>&1
if [ $? -ne 0 ]; then
    echo "❌ ERROR in pass 3!"
    tail -50 compile_log.txt
    exit 1
fi
echo "✅ Pass 3 complete"
echo ""

# Pass 4
echo "Step 5: Fourth compilation pass (final)..."
pdflatex -interaction=nonstopmode main.tex >> compile_log.txt 2>&1
if [ $? -ne 0 ]; then
    echo "❌ ERROR in pass 4!"
    tail -50 compile_log.txt
    exit 1
fi
echo "✅ Pass 4 complete"
echo ""

# Check result
if [ -f main.pdf ]; then
    FILE_SIZE=$(du -h main.pdf | cut -f1)
    PAGE_COUNT=$(pdfinfo main.pdf 2>/dev/null | grep Pages | awk '{print $2}')
    
    echo "=========================================="
    echo "✅ SUCCESS! PDF COMPILED SUCCESSFULLY"
    echo "=========================================="
    echo ""
    echo "📄 File: $(pwd)/main.pdf"
    echo "📊 Size: $FILE_SIZE"
    if [ ! -z "$PAGE_COUNT" ]; then
        echo "📖 Pages: $PAGE_COUNT"
    fi
    echo ""
    echo "Opening PDF..."
    open main.pdf 2>/dev/null || echo "Please open main.pdf manually"
    echo ""
    echo "✅ All done!"
else
    echo ""
    echo "=========================================="
    echo "❌ ERROR: PDF NOT CREATED!"
    echo "=========================================="
    echo ""
    echo "Check compile_log.txt for details:"
    echo "  tail -100 compile_log.txt"
    exit 1
fi

