from parsing.parser import parse_audit_rules, parse_config_data_apache, parse_config_data_tomcat
from analysis.analyzer import analyze
from common.server_type import ServerType


# Constants
APACHE_RULE_FILE = "references/apache.json"
TOMCAT_RULE_FILE = "references/tomcat.json"
APACHE_TEST_CONFIG_FILE_TRIGGER_ALL_RULES = "tests/data/apache_test_config_all_issues.conf"
APACHE_TEST_CONFIG_FILE_TRIGGER_NO_RULE = "tests/data/apache_test_config_no_issue.conf"
TOMCAT_TEST_CONFIG_FILE_TRIGGER_ALL_RULES = "tests/data/tomcat_test_config_all_issues.xml"
TOMCAT_TEST_CONFIG_FILE_TRIGGER_NO_RULE = "tests/data/tomcat_test_config_no_issue.xml"


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
    assert len(analysis_data) == 1, "The result was expected to contain a single instance of AnalysisData object !"
    assert len(analysis_data[0].issue_datas) == 0, f"{len(analysis_data[0].issue_datas)} audit rule were triggered, it was expected that no one rule found something!"

# Timeout feature of PyTest and its plugin "pytest-timeout" do not achieve to cancel the execution in a context of a ReDOS and the current runtime is vulnerable :(
# @pytest.mark.timeout(20, method="thread")
# def test_exposure_to_redos():
#    """Test in charge of ensuring that the Regex engine of the current Python runtime is not exposed to ReDOS because the analyzer rely on the RegEx engine. If the test fall in timeout then the engine is vulnerable."""
#    pattern = re.compile("^(a+)+$")
#    input = ""
#    for c in range(1, 10000):
#        input = ("a" * c) + "!"
#        pattern.match(input)
#        pattern.findall(input)


def test_tomcat_all_audit_rules_triggering():
    """Test case in charge of ensuring that all audit rules configured in reference file for Tomcat are correctly defined by applying them against a configuration that trigger all of them ."""
    # Load the reference file with all the audit rule for Apache
    audit_rules = parse_audit_rules(TOMCAT_RULE_FILE)
    # count the total number of expressions
    expression_count = 0
    for audit_rule in audit_rules:
        expression_count += len(audit_rule.audit_expressions)
    # Load the test configuration associated to this test case
    config_data = parse_config_data_tomcat(TOMCAT_TEST_CONFIG_FILE_TRIGGER_ALL_RULES, audit_rules)
    # Create the input object with config data
    config_data_collection = [config_data]
    # Run the test
    analysis_data = analyze(config_data_collection)
    # Verify result
    assert analysis_data is not None, "Result is None"
    assert len(analysis_data) > 0, "Result is empty"
    issues_found_count = 0
    for data in analysis_data:
        assert data.server_type == ServerType.TOMCAT, f"Wrong server type, expected: {ServerType.TOMCAT} - received: {data.server_type}"
        assert data.config_file_name == TOMCAT_TEST_CONFIG_FILE_TRIGGER_ALL_RULES, f"Wrong config file name, expected: {TOMCAT_TEST_CONFIG_FILE_TRIGGER_ALL_RULES} - received: {data.config_file_name}"
        issues_found_count += len(data.issue_datas)
    assert issues_found_count == expression_count, f"Not all audit rules were triggered: {issues_found_count} triggered on {expression_count} expected!"


def test_tomcat_no_audit_rules_triggering():
    """Test case in charge of ensuring that all audit rules configured in reference file for Tomcat are correctly defined by applying them against a configuration that trigger none of them."""
    # Load the reference file with all the audit rule for Apache
    audit_rules = parse_audit_rules(TOMCAT_RULE_FILE)
    # Load the test configuration associated to this test case
    config_data = parse_config_data_apache(TOMCAT_TEST_CONFIG_FILE_TRIGGER_NO_RULE, audit_rules)
    # Create the input object with config data
    config_data_collection = [config_data]
    # Run the test
    analysis_data = analyze(config_data_collection)
    # Verify result
    assert analysis_data is not None, "Result is None"
    assert len(analysis_data) == 1, "The result was expected to contain a single instance of AnalysisData object !"
    assert len(analysis_data[0].issue_datas) == 0, f"{len(analysis_data[0].issue_datas)} audit rule were triggered, it was expected that no one rule found something!"
