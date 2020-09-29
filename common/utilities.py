from common.severity import Severity


def print_message(severity, message):
    """Print a message to inform the user.

    :param severity: Importance of the message, it must be a item of the Severity enumeration.
    :param message: Message to display.
    """
    if not isinstance(severity, Severity):
        raise Exception("Invalid severity, it must be a item of the Severity enumeration!")
    print(f"{severity.name}: {message}")
