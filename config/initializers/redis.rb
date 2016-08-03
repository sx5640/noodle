require "redis"

$redis = Redis.new
$redis.flushall
