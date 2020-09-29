from common.audit_rule import AuditRule
from common.analysis_data import AnalysisData


class ReportData:
    """Represents the information resulting of the analysis and the parsing that will be used as data source for the report generator."""

    def __init__(self, audit_rules_collection, analysis_data_collection):
        """Constructor.

        :param audit_rules_collection: List of Instance of the AuditRule class returned by the parser.
        :param analysis_data_collection: List of Instance of the AnalysisData class returned by the analyzer.
        """
        error_msg = "The '%s' parameter must be an instance of the '%s' class!"
        if not isinstance(audit_rules_collection, list):
            raise Exception(error_msg % ("audit_rules_collection", "List"))
        if not isinstance(analysis_data_collection, list):
            raise Exception(error_msg % ("analysis_data_collection", "List"))
        i = 0
        for audit_rule in audit_rules_collection:
            if not isinstance(audit_rule, AuditRule):
                raise Exception(error_msg % (f"audit_rules_collection[{i}]", "AuditRule"))
            i += 1
        i = 0
        for analysis_data in analysis_data_collection:
            if not isinstance(analysis_data, AnalysisData):
                raise Exception(error_msg % (f"analysis_data_collection[{i}]", "AnalysisData"))
            i += 1
        self.audit_rules_collection = audit_rules_collection
        self.analysis_data_collection = analysis_data_collection
