class Expression:
    """Represents a regular expression and specify if its content must be found or not."""

    def __init__(self, expression, presence_needed):
        """Constructor.

        :param expression: The regular expression.
        :param presence_needed: A bool telling if the regular expression must be found.
        """
        self.expression = expression
        self.presence_needed = presence_needed
