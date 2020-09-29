from parsing.parser import parse_audit_rules, parse_config_data_apache
from analysis.analyzer import analyze
from common.server_type import ServerType


# Constants
APACHE_RULE_FILE = "references/apache.json"
APACHE_TEST_CONFIG_FILE_TRIGGER_ALL_RULES = "tests/data/apache_test_config_all_issues.conf"
APACHE_TEST_CONFIG_FILE_TRIGGER_NO_RULE = "tests/data/apache_test_config_no_issue.conf"


def test_apache_all_audit_rules_triggering():
    """Test case in charge of ensuring that all audit rules configured in reference file for Apache are correctly defined by applying them against a configuration that trigger all of them ."""
    # Load the reference file with all the audit rule for Apache
    audit_rules = parse_audit_rules(APACHE_RULE_FILE)
    # count the total number of expressions
    expression_count = 0
    for audit_rule in audit_rules:
        expression_count += len(audit_rule.audit_expressions)
    # Load the test configuration associated to this test case
    config_data = parse_config_data_apache(APACHE_TEST_CONFIG_FILE_TRIGGER_ALL_RULES, audit_rules)
    # Create the input object with config data
    config_data_collection = [config_data]
    # Run the test
    analysis_data = analyze(config_data_collection)
    # Verify result
    assert analysis_data is not None, "Result is None"
    assert len(analysis_data) > 0, "Result is empty"
    issues_found_count = 0
    for data in analysis_data:
        assert data.server_type == ServerType.APACHE, f"Wrong server type, expected: {ServerType.APACHE} - received: {data.server_type}"
        assert data.config_file_name == APACHE_TEST_CONFIG_FILE_TRIGGER_ALL_RULES, f"Wrong config file name, expected: {APACHE_TEST_CONFIG_FILE_TRIGGER_ALL_RULES} - received: {data.config_file_name}"
        issues_found_count += len(data.issue_datas)
    assert issues_found_count == expression_count, f"Not all audit rules were triggered: {issues_found_count} triggered on {expression_count} expected!"


def test_apache_no_audit_rules_triggering():
    """Test case in charge of ensuring that all audit rules configured in reference file for Apache are correctly defined by applying them against a configuration that trigger none of them."""
    # Load the reference file with all the audit rule for Apache
    audit_rules = parse_audit_rules(APACHE_RULE_FILE)
    # Load the test configuration associated to this test case
    config_data = parse_config_data_apache(APACHE_TEST_CONFIG_FILE_TRIGGER_NO_RULE, audit_rules)
    # Create the input object with config data
    config_data_collection = [config_data]
    # Run the test
    analysis_data = analyze(config_data_collection)
    # Verify result
    assert analysis_data is not None, "Result is None"
    assert len(analysis_data) == 0, f"{len(analysis_data)} audit rule were triggered, it was expected that no one rule found something!"
