class utilities:
    """Provides utilities methods used accross the project."""

    @staticmethod
    def print_message(severity, message):
        """Print a message to inform the user.

        :param severity: Importance of the message, must be one the following value ERROR, WARN, INFO or DEBUG.
        :param message: Message to display.
        """
        if severity.upper() not in ["ERROR", "INFO", "WARN", "DEBUG"]:
            raise Exception("Invalid severity!")
        print(f"{severity.upper()}: {message}")
