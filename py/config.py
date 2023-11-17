import logging


def configure_logger(loglevel):
    logger = logging.getLogger(__name__)
    logger.setLevel(loglevel)

    handler = logging.StreamHandler()
    handler.setLevel(loglevel)

    formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
    handler.setFormatter(formatter)

    logger.addHandler(handler)
    return logger


def get_logger():
    return logging.getLogger(__name__)
