import argparse
import os
import time
import hashlib
from pathlib import Path
from common.server_type import ServerType
from common.severity import Severity
from common.utilities import print_message
from common.report_data import ReportData
from parsing.parser import parse_audit_rules, parse_config_data_apache, parse_config_data_iis, multi_file_reader
from analysis.analyzer import analyze
from reporting.reporter import generate_report

# Global configuration
REPORT_TEMPLATE_FOLDER = "templates"
REFERENCE_AUDIT_RULES_FOLDER = "references"


def compute_file_content_hash(file_path):
    """Function in charge of computing the SHA256 of the content of a file.

    :param file_path: Path to the file to use a source.

    :return: The hash HEX encoded.
    """
    with open(file_path, "r") as f:
        content_hash = hashlib.sha256(f.read().encode("utf-8")).hexdigest()
    return content_hash


def main(folder_to_process, server_type, report_template_file, report_output_file):
    """Function in charge of managing the processinf workflow.

    :param folder_to_process: Path to folder containing the configuration file to review.
    :param server_type: Type of server associated to the configuration provided.
    :param report_template_file: Template file to use for the report.
    :param report_output_file: Location and name of the file in which the report content will be written.
    """
    try:
        start_time = time.time()
        audit_rules_file = f"{REFERENCE_AUDIT_RULES_FOLDER}/{server_type.name}.json"
        print_message(Severity.INFO, f"Load the audit rules from the reference file '{audit_rules_file}'...")
        audit_rules = parse_audit_rules(audit_rules_file)
        print_message(Severity.INFO, f"{len(audit_rules)} rules loaded.")

        print_message(Severity.INFO, "Gather the list of configuration files to review...")
        configuration_files_to_review = multi_file_reader(folder_to_process)
        for configuration_file_to_review in configuration_files_to_review:
            content_hash = compute_file_content_hash(configuration_file_to_review)
            print_message(Severity.DEBUG, f"SHA256 hash of the content of the config file identified '{configuration_file_to_review}': {content_hash}")
        print_message(Severity.INFO, f"{len(configuration_files_to_review)} files identified.")

        print_message(Severity.INFO, "Load the configuration content for each configuration files to review...")
        config_data_collection = []
        for configuration_file_to_review in configuration_files_to_review:
            if server_type in [ServerType.APACHE, ServerType.IIS]:
                if server_type == ServerType.APACHE:
                    config_data = parse_config_data_apache(configuration_file_to_review, audit_rules)
                if server_type == ServerType.IIS:
                    config_data = parse_config_data_iis(configuration_file_to_review, audit_rules)
                content_hash = hashlib.sha256(config_data.config_content.encode("utf-8")).hexdigest()
                print_message(Severity.DEBUG, f"SHA256 hash of the content of the config loaded '{configuration_file_to_review}': {content_hash}")
                config_data_collection.append(config_data)
            else:
                raise Exception(f"Server type {server_type.name} not still supported !")
        print_message(Severity.INFO, f"{len(config_data_collection)} configuration loaded.")

        print_message(Severity.INFO, "Process all configuration loaded...")
        analysis_data_collection = analyze(config_data_collection)
        print_message(Severity.INFO, "Processing finished.")

        print_message(Severity.INFO, f"Generate the report to the file '{report_output_file}'...")
        report_data = ReportData(audit_rules, analysis_data_collection)
        report_content = generate_report(report_data, report_template_file)
        with open(report_output_file, "w", encoding="UTF-8") as f:
            f.write(report_content)
        print_message(Severity.INFO, "Report created.")
        delay = round(time.time() - start_time, 2)
        print_message(Severity.DEBUG, f"Review performed in {delay} seconds.")
    except Exception as e:
        print_message(Severity.ERROR, f"Error during the processing: {str(e)}")


if __name__ == "__main__":
    # Gather the available report templates
    template_folder = Path(REPORT_TEMPLATE_FOLDER)
    templates = [os.path.splitext(f.name)[0] for f in template_folder.resolve().glob("*.txt") if f.is_file()]
    # Get the available server type
    server_type_names = [e.name for e in ServerType]
    # Define the call options and command line syntax
    parser = argparse.ArgumentParser(description=".::Web Server Secure Configuration Review Automation Tool::.")
    required_params = parser.add_argument_group("required named arguments")
    required_params.add_argument("-f", action="store", dest="folder_to_process", help="Path to folder containing the configuration to audit.", required=True)
    required_params.add_argument("-s", action="store", dest="type_server", help="Type of server from which the provided configuration is issued.", choices=server_type_names, required=True)
    required_params.add_argument("-t", action="store", dest="report_template", help="Report template to use.", choices=templates, required=True)
    parser.add_argument("-o", action="store", dest="report_output_file", help="Filename of the report (default to 'report.rpt').", default="report.rpt", required=False)
    args = parser.parse_args()
    # Call the application entry point with the provided context
    template_file = f"{REPORT_TEMPLATE_FOLDER}/{args.report_template}.txt"
    server_type = None
    for e in ServerType:
        if e.name == args.type_server:
            server_type = e
            break
    main(args.folder_to_process, server_type, template_file, args.report_output_file)
