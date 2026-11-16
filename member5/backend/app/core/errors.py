class BusinessError(Exception):
    def __init__(self, status, code, message):
        super().__init__(message)
        self.status, self.code, self.message = status, code, message


def require(condition, status, code, message):
    if not condition:
        raise BusinessError(status, code, message)
