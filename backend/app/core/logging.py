import logging
import sys

def setup_logging():
    # Basic logging configuration for production grade systems
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] [%(name)s] [request_id=%(request_id)s] %(message)s",
        handlers=[
            logging.StreamHandler(sys.stdout)
        ]
    )

    # Add request_id filter to inject empty default if not present
    old_factory = logging.getLogRecordFactory()

    def record_factory(*args, **kwargs):
        record = old_factory(*args, **kwargs)
        if not hasattr(record, "request_id"):
            record.request_id = "none"
        return record

    logging.setLogRecordFactory(record_factory)
