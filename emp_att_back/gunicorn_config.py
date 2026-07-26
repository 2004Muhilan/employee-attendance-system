import os

workers = 2  # Number of worker processes
threads = 4  # Number of threads per worker
bind = "0.0.0.0:" + os.environ.get("PORT", "10000")
timeout = 120 # Increase timeout for slow connections