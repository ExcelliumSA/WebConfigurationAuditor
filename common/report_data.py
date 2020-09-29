from common.config_data import ConfigData
from common.analysis_data import AnalysisData


class ReportData:
    """Represents the information resulting of the analysis and the parsing that will be used as data source for the report generator."""

    def __init__(self, config_data, analysis_data):
        """Constructor.

        :param config_data: Instance of the ConfigData class returned by the parser.
        :param analysis_data: Instance of the AnalysisData class returned by the analyzer.
        """
        error_msg = "The '%s' parameter must be an instance of the '%s' class!"
        if not isinstance(config_data, ConfigData):
            raise Exception(error_msg % ("config_data", "ConfigData"))
        if not isinstance(analysis_data, AnalysisData):
            raise Exception(error_msg % ("analysis_data", "AnalysisData"))
        self.config_data = config_data
        self.analysis_data = analysis_data
