class issueData:
    """Represent the information of a found issue."""

    def __init__(self, details, rule_id, CIS_version):
        """Constructor.

        :param details: A short description of the issue.
        :param rule_id: The ID of the rule from the CIS.
        :param CIS_version: The version of CIS the rule ID refers to.
        """
        self.details = details
        self.rule_id = rule_id
        self.CIS_version = CIS_version
