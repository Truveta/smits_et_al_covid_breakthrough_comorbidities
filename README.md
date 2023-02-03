Template Research
=================

This is a study template using ServerlessSQL to query data.
Both R and Python are fully supported and you can pick at the beginning which language should be used.

This template is using
 * both the external and the internal Python/R SDK
 * The https://dev.azure.com/Truveta/Product/_git/truveta_research package for utility functions


Prepare environment
-------------------

```sh
pip install -r requirements.txt
# enforce that we don't commit jupyter notebook outputs
nbstripout --install --attributes .gitattributes
```

This will install the extra Python dependencies for managing this template.


Initialize a new Study
----------------------

```sh
inv init
```

This will initialize a new study by asking you to enter the study as well as population name.
In addition, you have to pick between Python or R as the main language.
Based on the decisions the template will be customized to this study


Executing a Study
-----------------

This template consists of multiple steps that should be followed in order for a smooth execution of a study.

### 0. ValueSets

Notebook: `./0_valuesets.ipynb`

Customization Required: *Medium - some customization needed*

This notebook helps you define the valuesets that you want to use in this study.
It contains numerous standard ones such as demographics sex, race, or ethnicity.
You have to customize that latter one depending on the study data elements, e.g. ICD-10 condition codes to include.
The output of this notebook are CSV files in `./valuesets` that are used in later notebooks.

### 0.d Data Mapping

Notebook: `./0d_data_mapping.ipynb`

Customization Required: *Medium - some customization needed*

This notebook helps you to evaluate the data mapping status of terms such as medication names or lab results.
It uses the same API as Hawkeye under the hood but optimized for research purposes.

### 1. Create Study

Notebook: `./1_create_study.ipynb`

Customization Required: *None - no customization needed*

This notebook helps you defining the study within Truveta.
It uses the information from the initialization (study and population name) to find or create a new study for you.

*Note*: Collaborators are not automatically added anymore, please make sure to invite your colleagues.

In addition, based on the valuesets you created in the previous step, it suggests and prefills the Prose code with a guess.
However, you have to edit and verify it within the application.
The notebook will prompt you to update the Prose code in the middle.
It will not override the existing Prose code with the guess, if you want to adapt the Prose code later, you have to do it in the app.

The output of this notebooks are a dumped version of the Prose code being used as well as internal information such as the study id.

### 2. Generate Snapshot

Notebook: `./2_generate_snapshot.ipynb`

Customization Required: *None - no customization needed*

This notebook helps you triggering the generation of a new snapshot for your population.
Based on the information from the previous step, it will trigger a new snapshot in the application.
You can customize what percentage you want to use where 1 means it will be only 1% of the real population size. None/NULL will mean 100%.

**Note**: It will take hours to generate the snapshots once triggered via this notebook.

### 3. Wrangle and Clean Data

Notebook: `./3_wrangle_and_clean_data.ipynb`

Customization Required: *Large - needs to be heavily customized*

This is the most complex notebook and requires the most customization. It consists of multiple parts:

1. load snapshot: no customization needed
1. load helper tables: no customization needed
1. load search results: some customization needed, depending on the event set name in Prose
1. load demographics person table: no customization needed, this is the standard demographics information
1. load rest: needs to be heavily customized based on the needs. That includes, loading existing valusets and using it to filter / convert columns. The current notebooks gives examples on how to use it
1. merge and derive data: needs to be heavily customized based on ones needs. The goal is to create one or multiple feature tables that are used in the following notebook.


### 4. Analyze Data

Notebook: `./4_analyze_data.ipynb`

Customization Required: *Large - needs to be heavily customized*

This notebook gives you a template for loading the create feature table(s) from the previous steps, analyze, and plot it in a Truveta themed way.
The resulting graphs and summary tables should be placed in the `./results` directory for sharing.


General Remarks
---------------

* Notebook outputs are not commited if configured properly. This will avoid merge conflicts and reduces the repository size.
* Commit often and in useful steps, see before for remarks regarding outputs.
* Don't commit large data files. Data shouldn't be commited and only stored in the `./data` directory which is ignored.
* Results should be stored in the `./results` directory and small of size. e.g. summary tables as CSV files, PNG/SVG version of charts, ...
* Consider creating a snapshot which a small percentage (1-10%) before creating a full population snapshot. This will speed up your wrangling development.
* When generating another snapshot consider using a different branch for it. Thus, you can still work on the old snapshot easily while waiting for the snapshot to finish.

License
-------

This code is licensed under the [BSD-3-Clause](https://opensource.org/licenses/BSD-3-Clause), see also LICENCE file.
