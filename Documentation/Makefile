TEX_FILES = $(wildcard *.tex)
BIB_FILES = $(wildcard *.bib)
IMG_SRCS = $(wildcard Abbildungen/*.pdf)

all: Ausarbeitung.pdf

Ausarbeitung.pdf: $(TEX_FILES) $(BIB_FILES) $(IMG_SRCS) Makefile
	pdflatex Ausarbeitung.tex
	pdflatex Ausarbeitung.tex
	bibtex Ausarbeitung
	pdflatex Ausarbeitung.tex
	pdflatex Ausarbeitung.tex
clean:
	rm -f *.aux *.bbl *.blg *.log *.pdf *~ Ausarbeitung.out
