from common.server_type import ServerType


class ConfigData:
    """Represents the information of a configuration to analyze."""

    def __init__(self, server_type, config_content, config_file_name, audit_rules):
        """Constructor.

        :param server_type: The type of server from which the configuration is issued.
        :param config_content: The configuration itself to analyze.
        :param config_file_name: The name of the file from which the configuration is issued.
        :param audit_rules: The list of audit rules that must be applied against the configuration.
        """
        if not isinstance(server_type, ServerType):
            raise Exception("The server type must be a item of the ServerType enumeration!")
        if config_content is None or len(config_content.strip(" ")) == 0:
            raise Exception("Configuration cannot be none or empty!")
        if config_file_name is None or len(config_file_name.strip(" ")) == 0:
            raise Exception("Configuration file name cannot be none or empty!")
        if audit_rules is None or len(audit_rules) == 0:
            raise Exception("Audit rules cannot be none or empty!")
        self.server_type = server_type
        self.config_content = config_content
        self.config_file_name = config_file_name
        self.audit_rules = audit_rules
