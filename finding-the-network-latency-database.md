

Run in rails console

```rb
times = 100.times.map do
  start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  ActiveRecord::Base.connection.execute("SELECT 1")

  end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  elapsed_seconds = end_time - start_time
  elapsed_milliseconds = elapsed_seconds * 1000

  elapsed_milliseconds.round(2)
end.sort

def percentile(sorted_values, target_pct)
  fraction = target_pct / 100.0
  last_index = sorted_values.size - 1
  target_index = (fraction * last_index).round
  sorted_values[target_index]
end

min = times.first
p50 = percentile(times, 50)
p95 = percentile(times, 95)
max = times.last
avg = (times.sum / times.size).round(2)

puts "min: #{min}ms  p50: #{p50}ms  p95: #{p95}ms  max: #{max}ms  avg: #{avg}ms"
```
