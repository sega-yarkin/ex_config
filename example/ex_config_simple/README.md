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
Elixir 1.13.4
Erlang 25.0

Benchmark suite executing with the following configuration:
warmup: 5 s
time: 15 s
memory time: 5 s
parallel: 1

Name                          ips      average  deviation    median       99th %
InModule               30065.69 K     33.26 ns ±23236.49%     24 ns        65 ns
PersistentTerm (macro)  2845.98 K    351.37 ns  ±2409.06%    336 ns       428 ns
PersistentTerm          1794.97 K    557.11 ns ±11308.94%    463 ns       776 ns
Uncached (no crypto)      42.65 K  23446.72 ns    ±88.91%  21259 ns    101747 ns
Uncached                  24.23 K  41263.93 ns    ±38.82%  38555 ns  79596.21 ns

Comparison: 
InModule                  30065.69 K
PersistentTerm (macro)     2845.98 K - 10.56x slower +318.11 ns
PersistentTerm             1794.97 K - 16.75x slower +523.85 ns
Uncached (no crypto)         42.65 K - 704.94x slower +23413.46 ns
Uncached                     24.23 K - 1240.63x slower +41230.67 ns

Extended statistics: 

Name                           minimum        maximum    sample size        mode
InModule                         16 ns    30956280 ns        24.78 M       22 ns
PersistentTerm (macro)          307 ns    31258056 ns        16.07 M      331 ns
PersistentTerm                  425 ns   132674509 ns        13.76 M      463 ns
Uncached (no crypto)          20138 ns    10051464 ns       622.97 K    21242 ns
Uncached                      36709 ns     7247722 ns       356.39 K    37879 ns

Memory usage statistics:

Name                      Memory usage
InModule                           0 B
PersistentTerm (macro)             0 B - 1.00x memory usage +0 B
PersistentTerm                   192 B - ∞ x memory usage +192 B
Uncached (no crypto)           31528 B - ∞ x memory usage +31528 B
Uncached                       48672 B - ∞ x memory usage +48672 B
```
