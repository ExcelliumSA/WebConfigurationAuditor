class AnalysisData:
    """Represent the information resulting of the analysis."""

    def __init__(self, server_type, issue_datas, config_file_name):
        """Constructor.

        :param server_type: The type of server from which the configuration is issued.
        :param issue_datas: The list of issue_data objects that reprents the found issues.
        :param config_file_name: The name of the file from which the configuration is issued.
        """
        self.server_type = server_type
        self.issue_datas = issue_datas
        self.config_file_name = config_file_name
