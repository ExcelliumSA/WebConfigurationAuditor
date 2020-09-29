import argparse
import os
from pathlib import Path
from common.server_type import ServerType
from common.severity import Severity
from common.utilities import print_message
from common.report_data import ReportData
from parsing.parser import parse_audit_rules, parse_config_data_apache, multi_file_reader
from analysis.analyzer import analyze
from reporting.reporter import generate_report

# Global configuration
REPORT_TEMPLATE_FOLDER = "templates"
REFERENCE_AUDIT_RULES_FOLDER = "references"
DEBUG_MODE = False


def main(folder_to_process, server_type, report_template_file, report_output_file):
    """Function in charge of managing the processinf workflow.

    :param folder_to_process: Path to folder containing the configuration file to review.
    :param server_type: Type of server associated to the configuration provided.
    :param report_template_file: Template file to use for the report.
    :param report_output_file: Location and name of the file in which the report content will be written.
    """
    try:
        audit_rules_file = f"{REFERENCE_AUDIT_RULES_FOLDER}/{server_type.name}.json"
        print_message(Severity.INFO, f"Load the audit rules from the reference file '{audit_rules_file}'...")
        audit_rules = parse_audit_rules(audit_rules_file)
        print_message(Severity.INFO, f"{len(audit_rules)} rules loaded.")

        print_message(Severity.INFO, "Gather the list of configuration files to review...")
        configuration_files_to_review = multi_file_reader(folder_to_process)
        print_message(Severity.INFO, f"{len(configuration_files_to_review)} files identified.")

        print_message(Severity.INFO, "Load the configuration content for each configuration files to review...")
        config_data_collection = []
        for configuration_file_to_review in configuration_files_to_review:
            if server_type == ServerType.APACHE:
                config_data_collection.append(parse_config_data_apache(configuration_file_to_review, audit_rules))
        print_message(Severity.INFO, f"{len(config_data_collection)} configuration loaded.")

        print_message(Severity.INFO, "Process all configuration loaded...")
        analysis_data_collection = analyze(config_data_collection)
        print_message(Severity.INFO, "Processing finished.")

        print_message(Severity.INFO, f"Generate the report to the file '{report_output_file}'...")
        report_data = ReportData(audit_rules, analysis_data_collection)
        report_content = generate_report(report_data, report_template_file)
        with open(report_output_file, "w") as f:
            f.write(report_content)
        print_message(Severity.INFO, "Report created.")
    except Exception as e:
        print_message(Severity.ERROR, f"Error during the processing: {str(e)}")


if __name__ == "__main__":
    # Gather the available report template
    template_folder = Path(REPORT_TEMPLATE_FOLDER)
    templates = [os.path.splitext(f.name)[0] for f in template_folder.resolve().glob("*.txt") if f.is_file()]
    # Get the available servder type
    server_type_names = [e.name for e in ServerType]
    # Define the call options and command line syntax
    parser = argparse.ArgumentParser(description=".::Web Server Secure Configuration Review Automation Tool::.")
    parser.add_argument("-f", action="store", dest="folder_to_process", help="Path to folder containing the configuration to audit.", required=True)
    parser.add_argument("-s", action="store", dest="type_server", help="Type of server from which the provided configuration is issued.", choices=server_type_names, required=True)
    parser.add_argument("-t", action="store", dest="report_template", help="Report template to use.", choices=templates, required=True)
    parser.add_argument("-o", action="store", dest="report_output_file", help="Filename of the report (default to 'report.rpt').", default="report.rpt", required=False)
    parser.add_argument("-d", action="store_true", dest="debug", default=False, help="Enable debug mode.", required=False)
    args = parser.parse_args()
    DEBUG_MODE = args.debug
    # Call the application entry point with the provided context
    template_file = f"{REPORT_TEMPLATE_FOLDER}/{args.report_template}.txt"
    server_type = None
    for e in ServerType:
        if e.name == args.type_server:
            server_type = e
            break
    main(args.folder_to_process, server_type, template_file, args.report_output_file)
