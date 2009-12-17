manual.pdf : manual.tex
	pdflatex manual
	bibtex pdflatex manual
	pdflatex manual
	pdflatex manual

clean:
	-rm *.aux *.dvi  *~ *.pdf *.log *.out *.bbl *.blg *.backup
