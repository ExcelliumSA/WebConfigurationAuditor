from jinja2 import Template
from common.report_data import ReportData
from pathlib import Path


def generate_report(report_data, template_file):
    """Use the JINJA template specified alongside the data specified to generate the report as a string and return it.

    :param report_data: ReportData class instance containing the data to be used.
    :param template_file: Path to a JINJA template file.

    :return: The report content as a string.
     """
    # Apply integrity validation against parameter received
    if report_data is None or not isinstance(report_data, ReportData):
        raise Exception("The 'report_data' parameter must be an instance of the 'ReportData' class!")
    if template_file is None or not Path(template_file).is_file():
        raise Exception("The 'template_file' must be a valid file path!")

    # Load the template, generate the report and return it
    template_content = ""
    with open(template_file, "r") as t:
        template_content = t.read()
    report_content = Template(template_content).render(data=report_data)
    return report_content
