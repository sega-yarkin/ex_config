# Simple Test Application

To start the test application, `SERVER_ID` and  `PG_PASSWORD` environment
variables are required.

```
SERVER_ID=serv1 PG_PASSWORD=passwd iex -S mix
```

# Caching

When config is static, caching will give good improvements.
Simple benchmark gives next numbers:

```
$ SERVER_ID=serv1 PG_PASSWORD=passwd mix run lib/bench_caching.exs
CPU Information: Intel(R) Core(TM) i7-8750H CPU @ 2.20GHz
Elixir 1.9.0
Erlang 22.0.5

Benchmark suite executing with the following configuration:
warmup: 5 s
time: 15 s
memory time: 5 s
parallel: 1

Name                          ips        average  deviation     median    99th %
InModule                4206.50 K      237.73 ns  ±8375.43%       0 ns   1000 ns
PersistentTerm (macro)  1623.89 K      615.80 ns  ±4266.74%    1000 ns   1000 ns
PersistentTerm          1085.01 K      921.65 ns  ±3007.15%    1000 ns   1000 ns
Uncached (no crypto)      32.43 K    30837.30 ns    ±36.71%   29000 ns  60000 ns
Uncached                  18.99 K    52649.62 ns    ±27.55%   50000 ns  92000 ns

Comparison: 
InModule                   4206.50 K
PersistentTerm (macro)     1623.89 K - 2.59x slower +378.08 ns
PersistentTerm             1085.01 K - 3.88x slower +683.92 ns
Uncached (no crypto)         32.43 K - 129.72x slower +30599.58 ns
Uncached                     18.99 K - 221.47x slower +52411.89 ns

Extended statistics: 

Name                           minimum        maximum    sample size        mode
InModule                          0 ns    61610000 ns        18.30 M        0 ns
PersistentTerm (macro)            0 ns    84166000 ns        12.38 M     1000 ns
PersistentTerm                    0 ns    55612000 ns        10.10 M     1000 ns
Uncached (no crypto)          27000 ns     3781001 ns       470.83 K    29000 ns
Uncached                      46000 ns     2660000 ns       278.26 K    49000 ns

Memory usage statistics:

Name                      Memory usage
InModule                           0 B
PersistentTerm (macro)             0 B - 1.00x memory usage +0 B
PersistentTerm                   192 B - ∞ x memory usage +192 B
Uncached (no crypto)           30048 B - ∞ x memory usage +30048 B
Uncached                       43840 B - ∞ x memory usage +43840 B
```
