# Simple Test Application

To start the test application, `SERVER_ID` and  `PG_PASSWORD` environment
variables are required.

```
SERVER_ID=serv1 PG_PASSWORD=passwd iex -S mix
```

# Caching

When config is static, caching will give good improvements.
Simple benchmark gives next numbers:

+----------------+------------------+-------------------+
| Cache name     |  1_000_000 calls |  10_000_000 calls |
+----------------+------------------+-------------------+
| Uncached       | 64_994_586 usec  |           -       |
| PersistentTerm |    202_047 usec  |   1_916_176 usec  |
| InModule       |    129_399 usec  |   1_141_641 usec  |
+----------------+------------------+-------------------+
