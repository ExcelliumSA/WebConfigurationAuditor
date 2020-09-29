from parsing.parser import parse_audit_rules, parse_config_data_apache
from analysis.analyzer import analyze
from reporting.reporter import generate_report
from common.report_data import ReportData

# Constants
APACHE_RULE_FILE = "references/apache.json"
APACHE_TEST_CONFIG_FILE_FOR_REPORT_GENERATION = "tests/data/apache_test_config_for_report_generation.conf"
TEST_TEMPLATE_FILE = "tests/data/test_report_template.txt"
TEST_TEMPLATE_FILE_SSTI = "tests/data/test_report_template_ssti.txt"


def generate_test_data():
    """Utility function to generate test data for this test suite.

    :return: Return a ReportData object instance.
    """
    audit_rules = parse_audit_rules(APACHE_RULE_FILE)
    config_data = parse_config_data_apache(APACHE_TEST_CONFIG_FILE_FOR_REPORT_GENERATION, audit_rules)
    analysis_data = analyze([config_data])
    report_data = ReportData(config_data, analysis_data[0])
    return report_data


def test_report_generation():
    """Test case in charge of ensuring that the reporting generation via JINJA is functional."""
    # Generate input data for the report
    report_data = generate_test_data()
    # Generate the report
    content = generate_report(report_data, TEST_TEMPLATE_FILE)
    # Verify result
    assert "'config_data': <common.config_data.ConfigData object at" in content, "ConfigData instance not present in the data object provided to the report!"
    assert "'analysis_data': <common.analysis_data.AnalysisData object at" in content, "AnalysisData instance not present in the data object provided to the report!"


def test_exposure_to_ssti():
    """Test case in charge of ensuring that the reporting generation via JINJA is not exposed to SSTI."""
    # Generate input data for the report
    report_data = generate_test_data()
    payloadExpression = "{{42*42}}"
    payloadResolved = str(42 * 42)
    report_data.config_data.config_file_name = payloadExpression
    # Generate the report
    content = generate_report(report_data, TEST_TEMPLATE_FILE_SSTI)
    # Verify result
    assert payloadResolved not in content, f"Payload {payloadResolved} found in template so the feature is exposed to SSTI!"
    assert payloadExpression in content, f"Payload {payloadExpression} not found in template so the feature is potentially exposed to SSTI!"
