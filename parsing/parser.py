from common.audit_rule import AuditRule
from common.expression import Expression
# from common.config_data import ConfigData
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
        rule = AuditRule.unserializer(json_rule)
        rules_list.append(rule)
    return rules_list


def parse_config_data_apache(config_file_name):
    """Parse an Apache config file and return its content without the comments.

    :param config_file_name: The name of the config file to parse.
    :return: A string only containing the active configuration of the Apache.
    """
    with open(config_file_name) as config_file:
        lines = config_file.readlines()
    content = ""
    for line in lines:
        if line[:2] == "# ":
            continue
        content += line + '\n'
    return content
