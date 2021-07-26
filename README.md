# WCA

**W**eb **C**onfiguration **A**uditor.

## Code base analysis via Continuous Integration

> via [GitHub Actions](https://github.com/ExcelliumSA/WebConfigurationAuditor/actions) and [GitHub Dependabot](https://dependabot.com/)

![code_static_analysis_and_os_compatibility_tests](https://github.com/ExcelliumSA/WebConfigurationAuditor/workflows/code_static_analysis_and_os_compatibility_tests/badge.svg?branch=master)

![test_iis_config_extraction](https://github.com/ExcelliumSA/WebConfigurationAuditor/workflows/test_iis_config_extraction/badge.svg?branch=master)

[![dependabot](https://badgen.net/badge/Dependabot/enabled/green?icon=dependabot)](https://dependabot.com/)

## Objective, architecture and decision

See [here](documentation/Architecture.md).

## HowTo procedures

See [here](documentation/Howto.md).

## Execution error knowledge-base

### Expecting value: line 1 column 1 (char 0)

The file read is encoded using **UTF8 BOM** encoding.

Convert it to **UTF8** (No BOM) encoding, for example, using the following Linux shell command  ([source](https://unix.stackexchange.com/a/381231)):

 ```shell
 $ tail -c +4 withBOM.txt > withoutBOM.txt
 ```
