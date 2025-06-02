ExUnit.start()

# Configure faster timeouts for testing
ExUnit.configure(
  timeout: 1_000,           # 1 second default timeout
  max_cases: System.schedulers_online() * 2,  # Increase parallelism
  exclude: [:slow, :integration, :performance, :docsis, :memory, :format_compatibility, :parsing_edge_cases]  # Skip optional tests by default
)
