from common.severity import Severity
from termcolor import colored
import os

# Color affected to the message level
PRINT_COLORS = {"DEBUG": "magenta", "INFO": "white", "WARN": "yellow", "ERROR": "red"}


def print_message(severity, message):
    """Print a message to inform the user.

    :param severity: Importance of the message, it must be a item of the Severity enumeration.
    :param message: Message to display.
    """
    if not isinstance(severity, Severity):
        raise Exception("Invalid severity, it must be a item of the Severity enumeration!")
    debug = os.getenv("DEBUG")
    if severity != Severity.DEBUG or (severity == Severity.DEBUG and debug is not None):
        prefix = colored(f"{severity.name.ljust(5)}", PRINT_COLORS[severity.name])
        print(f"[{prefix}] {message}")
