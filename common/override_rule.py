class OverrideRule:
    """Represents a rule to override in an AuditRule object."""

    def __init__(self, rule_id, CIS_version):
        """Constructor.

        :param rule_id: The ID of the rule from the CIS.
        :param CIS_version: The version of CIS the rule ID refers to.
        """
        self.rule_id = rule_id
        self.CIS_version = CIS_version

    @staticmethod
    def unserializer(object):
        """The static method used to unserialize data from JSON to a OverrideRule object.

        :param object: The object returned by the json.loads function.
        :return: A new OverrideRule object containing the values passed in the object parameter.
        """
        return OverrideRule(object["rule_id"], object["CIS_version"])
