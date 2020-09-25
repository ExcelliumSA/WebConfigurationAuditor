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

    @staticmethod
    def unserializer(object):
        """The static method used to unserialize data from JSON to a AuditRule object.

        :param object: The object returned by the json.loads function.
        :return: A new AuditRule object containing the values passed in the object parameter.
        """
        return AuditRule(object["rule_id"], object["CIS_version"], object["audit_expressions"], object["override_rules"])
