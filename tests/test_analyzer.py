from parsing.parser import parse_audit_rules
from analysis.analyzer import analyze
from common.config_data import ConfigData
from common.server_type import ServerType
from typing import Final


# Constants
APACHE_RULE_FILE: Final = "../references/apache.json"
APACHE_TEST_CONFIG_FILE_TRIGGER_ALL_RULES: Final = "data/apache_test_config_all_issues.conf"


def test_apache_all_audit_rules_triggering():
    """Test case in charge of ensuring that all audit rules configured in reference file for Apache are correctly defined."""
    # Load the reference file with all the audit rule for Apache
    audit_rules = parse_audit_rules(APACHE_RULE_FILE)
    # Load the test configuration associated to this test case
    with open(APACHE_TEST_CONFIG_FILE_TRIGGER_ALL_RULES, "r") as f:
        content = f.read().splitlines()
        config_content = ""
        for line in content:
            if not line.startswith("# "):
                config_content += f"{line}\n"
    # Create the input object with config data
    config_data_collection = [ConfigData(ServerType.APACHE, config_content, APACHE_TEST_CONFIG_FILE_TRIGGER_ALL_RULES, audit_rules)]
    # Run the test
    analysis_data = analyze(config_data_collection)
    # Verify result
    assert analysis_data is not None, "Result is None"
    assert len(analysis_data) == len(audit_rules), f"Not all audit rules were triggered: {len(analysis_data)} triggered on {len(audit_rules)} expected."
