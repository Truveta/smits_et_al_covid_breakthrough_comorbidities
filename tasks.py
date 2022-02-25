from invoke import task
import pathlib
import shutil


@task
def clean(c):
    dirs = [
        "data",
        "02_analyze_data/_targets",
        "02_analyze_data/doc",
        "03_generate_artifacts/_targets",
    ]
    for dirname in dirs:
        if pathlib.Path(dirname).exists():
            shutil.rmtree(dirname)


@task
def filter_data(c):
    c.run("Rscript --no-save --no-restore --verbose 01_filter_data.R")


@task
def analyze_data(c):
    c.run("Rscript --no-save --no-restore --verbose 02_analyze_data.R")


@task
def analyze_data_par(c):
    c.run("Rscript --no-save --no-restore --verbose 02_analyze_data_par.R")


@task
def generate_artifacts(c):
    c.run("Rscript --no-save --no-restore --verbose 03_generate_artifacts.R")


@task(filter_data, analyze_data, generate_artifacts)
def build(c):
    print('done')
