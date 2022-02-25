.PHONY: list
list:
	@LC_ALL=C $(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

prepare:
	R CMD BATCH install.R

clean:
	rm -rf data
	rm -rf 02_analyze_data/_targets 02_analyze_data/doc
	rm -rf 03_generate_artifacts/_targets

filter_data:
	Rscript --no-save --no-restore --verbose 01_filter_data.R

analyze_data:
	Rscript --no-save --no-restore --verbose 02_analyze_data.R

analyze_data_par:
	Rscript --no-save --no-restore --verbose 02_analyze_data_par.R

generate_artifacts:
	Rscript --no-save --no-restore --verbose 03_generate_artifacts.R

