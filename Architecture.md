# Objective

The tools has for objective to perform a fully automated secure configuration review using the [CIS](https://www.cisecurity.org/cis-benchmarks/) referential for the following **type** of web/application server:
- Apache web server.
- Apache Tomcat.
- Microsoft IIS.

# Requirement

- Python 3.7+.
- Configuation files of the target to analyse.

# Folder layout

```text
WSCR
├───.vscode
├───analysis
├───common
├───parsing
├───references
├───reporting
├───templates
├───tests
```

- **.vscode**: Folder containing the internal stuff used by VSCode to handle the project.
- **analysis**: Package containing all Python code related to the analysis of the configuration file provided.
- **common**: Package containing all Python code shared by all the project.
- **parsing**: Package containing all Python code related to the parsing of the the references audit rules and the configuraiton file provided.
- **references**: Folder containing the audit rules files for every technology supported.
- **reporting**: Package containing all Python code related to the generation of the report.
- **templates**: Report template file using the JINJA syntax to define the available reports.
- **tests**: Package containing all Python code related to the unit testing of the project.

The tool entry point is the `main.py` file:

```bash
python main.py --help
```

# Debug mode

By default the tool do not print the debug level message. 

To enable the debug mode then set a environement variable named `DEBUG` to any value prior to call the tool:

```powershell
PS> $env:DEBUG=1
``` 

```bash
$ export DEBUG=1
``` 

# Policy

- Code will be public but no external contribution accepted.
    - Add a mention on this in the README (if you want to modify it, fork it).
- Configuration will be private to Excellium for IP reason.

# Global convention

- Usage of `requirements.txt` for dependencies.
- No oneliner except for a restricted use case.
- Snake case.
- Focus on code easy to read, understand and maintain.
- Keep the content of each file coherent with the purpose of the file (ex: no analysis in the report module).
- [Naming convention used](https://visualgit.readthedocs.io/en/latest/pages/naming_convention.html).
- In case of no result for a list then return a empty list instead of `None`.

# Rules configuration convention

Rules for each type of server are stored in JSON files which are named \*nameOfTheTechnology\*.json (all lowercase):

```json 
[
    {   
        "rule_id": "CIS-ID" ,
        "CIS_version": "x.x",
        "audit_expressions": [{
                        "expression":"*RULE_REGEX*",
                        "presence_needed": "True|False"
                        },
                        ...
                    ],
        "override_rules": [{
                "rule_id": "CIS-ID",
                "CIS_version": "x.x"
                },
                ...
            ]
    }
]
```

The member **rule_id** have the following value `CIS-PointIdentifierInReferential`.

*Example:* For the point 2.4 of the CIS then the member **rule_id** will be `CIS-2.4`.

The member **CIS_Version** have the following value `uppercase(TechnologyName)-TechnologyVersion-CISDocumentVersion`.

*Example:* The document of the CIS is named `CIS_Apache_HTTP_Server_2.4_Benchmark_v1.5.0.pdf` so the member **CIS_Version** will be `APACHE-2.4-1.5.0`.

The member **presence_needed** is used to specify if the audit expression (regex) is expected to find something or not:
- If *True* then the validation is considered failed if the audit expression find something.
- If *False* then the validation is considered failed if the audit expression find nothing.

The member **override_rules** is used to indicate that the current rule override, in terms of validation, the list of rules specified. This information is used during the reporting phase.


# IDE

- Visual Studio Code with Python extension provided by Microsoft.
- Project workspace file has been configured to trigger the installation of required code analysis modules and analysis profile is defined in the workspace settings area.
- Define the folliwng Pre-Commit hook in the file `[PROJECT_HOME]/.git/hooks/pre-commit`:

```bash
#!/bin/sh
echo "[+] Ensure that all Unit Tests pass before to accept a commit..."
pytest
rc=$?
if [ $rc == 0 ]
then
	echo "[+] All UT pass - Commit accepted."
else
	echo "[!] NOT All UT pass - Commit refused."
fi
exit $rc
```

# Global overview

```text
(TYPE, FOLDER, REPORT FORMAT) 
=> PARSING MODULE 
=[CONFIG_DATA_OBJECT]=> ANALYSIS MODULE 
=[ANALYSIS_DATA_OBJECT]=> REPORTING MODULE
```

## Modules

### Parsing

Read the configuration files provided via a folder and create `ConfigData` object instances.

### Analysis

Use the collection of the `ConfigData` object instances received to apply **analysis rules** (based on Regex) against them in order to identify issues and create `AnalysisData` object instances.

### Reporting

Use the collection of `ReportData` object instance (one`ReportData` object instance is associated to one configuration file analysed) to generate a report  in the wanted format.

# Transfer objects structure

> ID of the analysis rule is the CIS rule ID.

ConfigData:
- Type of web/application server.
- A string with the configuration elements to analyse (content of the config file).
- Source file name containing the configuration elements.
- List of validation rules to apply.

AnalysisData:
- Type of web/application server.
- List of `IssueData` object instances.
- Source file name containing the configuration elements affected by the issues.

IssueData:
- Details of issue (string).
- ID of the rule.
- Version of CIS.

AuditRule:
- ID of the rule.
- Version of the CIS.
- The list of the regular expressions to test.
- The list of rule that this rule override. 

OverrideRule:
- ID of the rule.
- Version of the CIS.

ReportData:
- Data generated by the parser for a configuration file.
- Data generated by the analyzer for a configuration file.

# Security note

- [PyTest](https://www.guru99.com/pytest-tutorial.html) will be used for the unit testing.
- Add a unit test to detect exposure to ReDOS.
- Every analysis rule must be covered by a positive and negative unit test, however, the tests will be factored in order to tests au rules of type of server (made the maintenance more easier).
- Keep the modules updated (usage of regexp can be dangerous if a vulnerability is present in the parser): 
    - Use [Dependabot](https://dependabot.com/).
    - Use [Snyk](https://snyk.io/).
    - Use [Bandit](https://pypi.org/project/bandit/).