import re
from common.analysis_data import AnalysisData
from common.issue_data import IssueData
from common.utilities import Utilities
from common.severity import Severity


def analyze(config_data_collection):
    """Apply the analysis using the configuration data provided.

    :param config_data_collection: list of configuration data to review alongside analysis rules.

    :return: A collection of object instances of class AnalysisData. If no issue is found then the collection will be empty.
    """
    # Apply integrity validation against parameter received
    if config_data_collection is None or len(config_data_collection) == 0:
        raise Exception("The list of configuration data cannot be none or empty!")

    # Apply processing
    analysis_results = []
    issue_msg_template = "Rule %s has matched the following data in the configuration provided: %s"
    current_rule_identifier = ""
    current_regex = ""
    for config_data in config_data_collection:
        # Analyse the current file
        try:
            error_count = 0
            issues_identified = []
            Utilities.print_message(Severity.INFO, f"Begin analysis of the file '{config_data.config_file_name}' using {len(config_data.audit_rules)} rules.")
            for audit_rule in config_data.audit_rules:
                current_rule_identifier = audit_rule.rule_id
                for regex in audit_rule.audit_expressions:
                    current_regex = regex
                    pattern = re.compile(current_regex, re.MULTILINE)
                    identified = pattern.match(config_data.config_content)
                    if identified is not None:
                        Utilities.print_message(Severity.DEBUG, f"Test rule '{current_rule_identifier}' with the regex '{current_regex}' has matched.")
                        issue = IssueData(issue_msg_template % (current_rule_identifier, identified.groups()), current_rule_identifier, audit_rule.CIS_version)
                        issues_identified.append(issue)
                    else:
                        Utilities.print_message(Severity.DEBUG, f"Test rule '{current_rule_identifier}' with the regex '{current_regex}' has not matched.")
            Utilities.print_message(Severity.INFO, f"Analysis of the file '{config_data.config_file_name}' ended with {error_count} error(s).")
        except Exception as e:
            error_count += 1
            Utilities.print_message(Severity.ERROR, f"Error during analysis of the file '{config_data.config_file_name}' on rule '{current_rule_identifier}' on regex '{current_regex}': {str(e)}")
        # Construct the result object
        analysis_data = AnalysisData(config_data.server_type, issues_identified, config_data.config_file_name)
        analysis_results.append(analysis_data)

    # Return the results
    return analysis_results
