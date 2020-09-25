class AuditRule:
    """Represents the rules to test on the configuration files."""

    def __init__(self, rule_id, CIS_version, audit_expressions, override_rules):
        """Constructor.

        :param rule_id: The ID of the rule from the CIS.
        :param CIS_version: The version of CIS the rule ID refers to.
        :param audit_expressions: The regular expressions defining the checks to perform.
        :param override_rules: The rules that the current rule override.
        """
        self.rule_id = rule_id
        self.CIS_version = CIS_version
        self.audit_expressions = audit_expressions
        self.override_rules = override_rules
