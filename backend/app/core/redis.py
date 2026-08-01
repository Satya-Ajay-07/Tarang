import redis
from app.core.config import settings

# Create a connection pool for Redis
pool = redis.ConnectionPool.from_url(
    settings.REDIS_URL,
    decode_responses=True,
    max_connections=50
)

def get_redis_client() -> redis.Redis:
    return redis.Redis(connection_pool=pool)

def get_redis():
    client = get_redis_client()
    try:
        yield client
    finally:
        client.close()
