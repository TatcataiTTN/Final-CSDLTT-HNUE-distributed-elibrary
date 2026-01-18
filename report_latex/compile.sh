#!/bin/bash

echo "=========================================="
echo "🔨 COMPILING LATEX REPORT"
echo "=========================================="
echo ""

cd "$(dirname "$0")"

# Clean old files
echo "Cleaning old files..."
rm -f main.aux main.log main.out main.toc main.lof main.lot main.lol main.bbl main.blg

# First pass
echo ""
echo "First pass: pdflatex..."
pdflatex -interaction=nonstopmode main.tex > compile_log.txt 2>&1

if [ $? -ne 0 ]; then
    echo "❌ ERROR in first pass!"
    echo ""
    echo "Last 30 lines of log:"
    tail -30 compile_log.txt
    exit 1
fi

# Second pass (for references)
echo "Second pass: pdflatex..."
pdflatex -interaction=nonstopmode main.tex >> compile_log.txt 2>&1

if [ $? -ne 0 ]; then
    echo "❌ ERROR in second pass!"
    echo ""
    echo "Last 30 lines of log:"
    tail -30 compile_log.txt
    exit 1
fi

# Check if PDF was created
if [ -f main.pdf ]; then
    echo ""
    echo "=========================================="
    echo "✅ SUCCESS! PDF created successfully"
    echo "=========================================="
    echo ""
    echo "File: $(pwd)/main.pdf"
    echo "Size: $(du -h main.pdf | cut -f1)"
    echo ""
    echo "Opening PDF..."
    open main.pdf
else
    echo ""
    echo "❌ ERROR: PDF not created!"
    echo ""
    echo "Check compile_log.txt for details"
    exit 1
fi

