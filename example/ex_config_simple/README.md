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
Elixir 1.12.1
Erlang 24.0.2

Benchmark suite executing with the following configuration:
warmup: 5 s
time: 15 s
memory time: 5 s
parallel: 1

Name                          ips        average  deviation     median    99th %
InModule                4633.00 K      215.84 ns ±28414.47%       0 ns   1000 ns
PersistentTerm (macro)  1862.61 K      536.88 ns  ±8671.00%    1000 ns   1000 ns
PersistentTerm          1366.16 K      731.98 ns  ±5292.93%    1000 ns   1000 ns
Uncached (no crypto)      37.53 K    26641.94 ns    ±66.84%   25000 ns 101000 ns
Uncached                  23.72 K    42165.47 ns    ±43.21%   39000 ns 100000 ns

Comparison: 
InModule                   4633.00 K
PersistentTerm (macro)     1862.61 K - 2.49x slower +321.04 ns
PersistentTerm             1366.16 K - 3.39x slower +516.13 ns
Uncached (no crypto)         37.53 K - 123.43x slower +26426.09 ns
Uncached                     23.72 K - 195.35x slower +41949.62 ns

Extended statistics: 

Name                           minimum        maximum    sample size        mode
InModule                          0 ns   198986000 ns        20.14 M        0 ns
PersistentTerm (macro)            0 ns   140197000 ns        14.07 M     1000 ns
PersistentTerm                    0 ns    92195000 ns        12.29 M     1000 ns
Uncached (no crypto)          23000 ns     5175000 ns       550.30 K    24000 ns
Uncached                      37000 ns     4263000 ns       349.70 K    39000 ns

Memory usage statistics:

Name                      Memory usage
InModule                           0 B
PersistentTerm (macro)             0 B - 1.00x memory usage +0 B
PersistentTerm                   192 B - ∞ x memory usage +192 B
Uncached (no crypto)           31688 B - ∞ x memory usage +31688 B
Uncached                       44848 B - ∞ x memory usage +44848 B
```
