class config_data:
    """Represent the information of a configuration to analyze."""

    def __init__(self, server_type, config_content, config_file_name, audit_rules):
        """Constructor.

        :param server_type: The type of server from which the configuration is issued.
        :param config_content: The configuration itself to analyze.
        :param config_file_name: The name of the file from which the configuration is issued.
        :param audit_rules: The list of audit rules that must be applied against the configuration.
        """
        self.server_type = server_type
        self.config_content = config_content
        self.config_file_name = config_file_name
        self.audit_rules = audit_rules
