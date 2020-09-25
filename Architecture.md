# Objective

The tools has for objective to perform a fully automated secure configuration review using the [CIS](https://www.cisecurity.org/cis-benchmarks/) referential for the following **type** of web/application server:
- Apache web server.
- Apache Tomcat.
- Microsoft IIS.

# Requirement

- Python 3.7+.
- Configuation files of the target to analyse.

# Policy

- Code will be public but no external contribution accepted.
    - Add a mention on this in the README (if you want to modify it, fork it).
- Configuration will be private to Excellium for IP reason.

# Global convention

- Usage of `requirements.txt` for dependencies.
- No oneliner.
- Snake case.
- Focus on code easy to read, understand and maintain.
- Keep the content of each file coherent with the purpose of the file (ex: no analysis in the report module).
- [Naming convention used](https://visualgit.readthedocs.io/en/latest/pages/naming_convention.html).
- In case of no result for a list then return a empty list instead of `None`.

# Rules configuration convention

Rules for each type of server are stored in JSON files which are named \*Name Of the Technology\*.json:

```json 
[
    {   
        "ID_RULE": "CIS-ID" ,
        "CIS_VERSION": "x.x",
        "AUDIT_EXPRESSION": ["", ...],
        "OVERRIDE": [{
                "ID_RULE": "CIS-ID",
                "CIS_VERSION": "x.x"
                },
                ...
            ]
    }
]
```

# IDE

- Visual Studio Code with Python extension provided by Microsoft.
- Project workspace file has been configured to trigger the installation of required code analysis modules and analysis profile is defined in the workspace settings area.

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

Use the collection of the `AnalysisData` object instances received to generate a report in the wanted format.

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

# Security note

- [PyTest](https://www.guru99.com/pytest-tutorial.html) will be used for the unit testing.
- Add a unit test to detect exposure to ReDOS.
- Every analysis rule must be covered by a positive and negative unit test, however, the tests will be factored in order to tests au rules of type of server (made the maintenance more easier).
- Keep the modules updated (usage of regexp can be dangerous if a vulnerability is present in the parser): 
    - Use [Dependabot](https://dependabot.com/).
    - Use [Snyk](https://snyk.io/).
    - Use [Bandit](https://pypi.org/project/bandit/).