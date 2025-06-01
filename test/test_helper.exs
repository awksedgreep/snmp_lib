ExUnit.start()

# Configure faster timeouts for testing
ExUnit.configure(
  timeout: 1_000,           # 1 second default timeout
  max_cases: System.schedulers_online() * 2,  # Increase parallelism
  exclude: [:slow, :integration, :performance]  # Skip slow tests by default
)
