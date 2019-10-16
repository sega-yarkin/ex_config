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
$ MIX_ENV=prod SERVER_ID=serv1 PG_PASSWORD=passwd mix run lib/bench_caching.exs
CPU Information: Intel(R) Core(TM) i7-8750H CPU @ 2.20GHz
Elixir 1.9.1
Erlang 22.1

Benchmark suite executing with the following configuration:
warmup: 5 s
time: 15 s
memory time: 5 s
parallel: 1

Name                          ips        average  deviation     median    99th %
InModule                4094.79 K      244.21 ns  ±9021.19%       0 ns   1000 ns
PersistentTerm (macro)  1581.28 K      632.40 ns  ±3635.75%    1000 ns   1000 ns
PersistentTerm           991.76 K     1008.31 ns  ±2948.08%    1000 ns   2000 ns
Uncached (no crypto)      33.08 K    30230.34 ns    ±40.40%   29000 ns  63000 ns
Uncached                  18.99 K    52659.73 ns    ±25.02%   50000 ns  96000 ns

Comparison: 
InModule                   4094.79 K
PersistentTerm (macro)     1581.28 K - 2.59x slower +388.18 ns
PersistentTerm              991.76 K - 4.13x slower +764.10 ns
Uncached (no crypto)         33.08 K - 123.79x slower +29986.13 ns
Uncached                     18.99 K - 215.63x slower +52415.52 ns

Extended statistics: 

Name                           minimum        maximum    sample size        mode
InModule                          0 ns    71774000 ns        17.65 M        0 ns
PersistentTerm (macro)            0 ns    68832000 ns        12.30 M     1000 ns
PersistentTerm                    0 ns    57954000 ns         9.47 M     1000 ns
Uncached (no crypto)          27000 ns     4454000 ns       479.06 K    28000 ns
Uncached                      47000 ns     1083000 ns       278.02 K    49000 ns

Memory usage statistics:

Name                      Memory usage
InModule                           0 B
PersistentTerm (macro)             0 B - 1.00x memory usage +0 B
PersistentTerm                   192 B - ∞ x memory usage +192 B
Uncached (no crypto)           27512 B - ∞ x memory usage +27512 B
Uncached                       39984 B - ∞ x memory usage +39984 B
```
