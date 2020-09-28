from parsing.parser import parse_audit_rules


# Constants
APACHE_RULE_FILE = "references/apache.json"
MULTIPLE_RULES_FILE = "tests/data/test_parser_multiple_rules.json"
MULTIPLE_EXPRESSIONS_FILE = "tests/data/test_parser_multiple_expressions_in_rule.json"
OVERRIDE_RULES_FILE = "tests/data/test_parser_override_rules.json"


def test_parse_audit_rules_simple():
    """Test the parser of rules to ensure that it returns the expected values in the most simple case."""
    audit_rules = parse_audit_rules(APACHE_RULE_FILE)
    first_rule = audit_rules[0]
    assert first_rule.rule_id == "CIS-2.1", "The rule ID is wrong."
    assert first_rule.CIS_version == "APACHE-2.4-1.5.0", "The CIS version is wrong."
    assert first_rule.audit_expressions[0].expression == "(mod_auth_basic|mod_authn_file|mod_authz_dbd|mod_authz_owner|mod_authz_user)\\.[a-z]{2,3}", "The first expression of audit expression doesn't correspond."
    assert first_rule.audit_expressions[0].presence_needed is False, "The presence_needed boolean doesn't correspond."
    assert len(first_rule.override_rules) == 0, "The override_rules shouldn't contain any values in this test."


def test_parse_audit_rules_multiple_rules():
    """Test the parser of rules to ensure that it handles correctly multiple rule."""
    audit_rules = parse_audit_rules(MULTIPLE_RULES_FILE)
    first_rule = audit_rules[0]
    assert first_rule.rule_id == "CIS-2.1", "The rule ID is wrong."
    assert first_rule.CIS_version == "APACHE-2.4-1.5.0", "The CIS version is wrong."
    assert first_rule.audit_expressions[0].expression == "(mod_auth_basic|mod_authn_file|mod_authz_dbd|mod_authz_owner|mod_authz_user)\\.[a-z]{2,3}", "The first expression of audit expression doesn't correspond."
    assert first_rule.audit_expressions[0].presence_needed is False, "The presence_needed boolean doesn't correspond."
    assert len(first_rule.override_rules) == 0, "The override_rules shouldn't contain any values in this test."
    second_rule = audit_rules[1]
    assert second_rule.rule_id == "CIS-1.1", "The rule ID is wrong."
    assert second_rule.CIS_version == "APACHE-2.4-1.5.0", "The CIS version is wrong."
    assert second_rule.audit_expressions[0].expression == "test", "The first expression of audit expression doesn't correspond."
    assert second_rule.audit_expressions[0].presence_needed is True, "The presence_needed boolean doesn't correspond."
    assert len(second_rule.override_rules) == 0, "The override_rules shouldn't contain any values in this test."


def test_parse_audit_rules_multiple_expressions():
    """Test the parser of rules to ensure that it handles correctly multiple expressions in a rule."""
    audit_rules = parse_audit_rules(MULTIPLE_EXPRESSIONS_FILE)
    first_rule = audit_rules[0]
    assert first_rule.rule_id == "CIS-2.1", "The rule ID is wrong."
    assert first_rule.CIS_version == "APACHE-2.4-1.5.0", "The CIS version is wrong."
    assert first_rule.audit_expressions[0].expression == "(mod_auth_basic|mod_authn_file|mod_authz_dbd|mod_authz_owner|mod_authz_user)\\.[a-z]{2,3}", "The first expression of audit expression doesn't correspond."
    assert first_rule.audit_expressions[0].presence_needed is False, "The presence_needed boolean doesn't correspond."
    assert first_rule.audit_expressions[1].expression == "test", "The first expression of audit expression doesn't correspond."
    assert first_rule.audit_expressions[1].presence_needed is True, "The presence_needed boolean doesn't correspond."
    assert len(first_rule.override_rules) == 0, "The override_rules shouldn't contain any values in this test."


def test_parse_audit_rules_override_rules():
    """Test the parser of rules to ensure that it handles override rules correctly."""
    audit_rules = parse_audit_rules(OVERRIDE_RULES_FILE)
    first_rule = audit_rules[0]
    assert first_rule.rule_id == "CIS-2.1", "The rule ID is wrong."
    assert first_rule.CIS_version == "APACHE-2.4-1.5.0", "The CIS version is wrong."
    assert first_rule.audit_expressions[0].expression == "(mod_auth_basic|mod_authn_file|mod_authz_dbd|mod_authz_owner|mod_authz_user)\\.[a-z]{2,3}", "The first expression of audit expression doesn't correspond."
    assert first_rule.audit_expressions[0].presence_needed is False, "The presence_needed boolean doesn't correspond."
    assert first_rule.override_rules[0].rule_id == "CIS-1.1", "The first override_rules rule_id doesn't match."
    assert first_rule.override_rules[0].CIS_version == "APACHE-2.4-1.5.0", "The first override_rules CIS_version doesn't match."
    assert first_rule.override_rules[1].rule_id == "CIS-1.2", "The first override_rules rule_id doesn't match."
    assert first_rule.override_rules[1].CIS_version == "APACHE-2.4-1.5.0", "The first override_rules CIS_version doesn't match."
