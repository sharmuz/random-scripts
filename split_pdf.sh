#!/bin/bash
for pdf_file in ./split/**/*.pdf
do
    str="$pdf_file"
    gs -sDEVICE=pdfwrite -dPDFSETTINGS=/ebook -q -o "$str.tmp" $str
    rm $str
    qpdf --object-streams=generate --split-pages=10 "$str.tmp" ${str%.pdf}_%d.pdf
    rm "$str.tmp"
done
