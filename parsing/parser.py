from common.audit_rule import AuditRule
from common.config_data import ConfigData
from common.expression import Expression
from common.override_rule import OverrideRule
from common.server_type import ServerType
from pathlib import Path
import json


def parse_audit_rules(rule_file_name):
    """Parse the JSON rules into a list of AuditRule objects.

    :param rule_file_name: The name of the file to open to get the JSON.
    :return: A list of AuditRule objects created from the given file.
    """
    with open(rule_file_name, "r") as rule_file:
        content = rule_file.read()
    json_rules_list = json.loads(content)
    rules_list = []
    for json_rule in json_rules_list:
        tmp_expressions = []
        for json_expression in json_rule["audit_expressions"]:
            expression = Expression.unserializer(json_expression)
            tmp_expressions.append(expression)
        json_rule["audit_expressions"] = tmp_expressions
        tmp_override = []
        for json_override in json_rule["override_rules"]:
            override = OverrideRule.unserializer(json_override)
            tmp_override.append(override)
        json_rule["override_rules"] = tmp_override
        rule = AuditRule.unserializer(json_rule)
        rules_list.append(rule)
    return rules_list


def parse_config_data_apache(config_file_name, audit_rules):
    """Parse an Apache config file and return its content without the comments.

    :param config_file_name: The name of the config file to parse.
    :param audit_rules: A list of AuditRule objects that can be obtained by calling the parse_audit_rules function.
    :return: A ConfigData object containing the active configuration of the Apache.
    """
    with open(config_file_name) as config_file:
        lines = config_file.readlines()
    content = ""
    for line in lines:
        if line[0] == "#":
            continue
        content += line
    config_data = ConfigData(ServerType.APACHE, content, config_file_name, audit_rules)
    return config_data


def multi_file_reader(folder_path):
    """List all the files in a given folder and its subdirectories.

    :param folder_path: the path to the folder to explore.
    :return: A list of string representing the path to each file in the folder_path folder.
    """
    root = Path(folder_path)
    files = [str(f) for f in root.resolve().glob("**/*") if f.is_file()]
    return files
