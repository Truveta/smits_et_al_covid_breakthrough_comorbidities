# make a bibtex file of package citations
make_bibtex <- function(packages, output_dir, filename) {

  filepath <- file.path(output_dir, filename)
  
  pack <- sort(c(packages, 'targets'))
  
  bibtex::write.bib(entry = pack, file = filepath)
  bibtex::write.bib(entry = citation(), file = filepath, append = TRUE)

  return(filepath)
}

