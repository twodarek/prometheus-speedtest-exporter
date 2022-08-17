# mtr-exporter

[![Go Report Card](https://goreportcard.com/badge/github.com/twodarek/mtr-exporter)](https://goreportcard.com/report/github.com/twodarek/mtr-exporter)

*mtr-exporter* periodically executes [mtr] to a given host and provides the
measured results as [prometheus] metrics.

Usually, [mtr] is producing the following output:

     HOST: src.example.com       Loss%   Snt   Last   Avg  Best  Wrst StDev
     1.|-- 127.0.0.1             0.0%     2    0.6   0.6   0.6   0.7   0.1
     2.|-- 127.0.0.2             0.0%     2    6.1  10.2   6.1  14.3   5.8
     3.|-- 127.0.0.3             0.0%     2   13.0  12.3  11.6  13.0   1.0
     4.|-- 127.0.0.4             0.0%     2    7.0   9.1   7.0  11.1   2.9
     5.|-- 127.0.0.5             0.0%     2   12.5  16.5  12.5  20.6   5.7
     6.|-- 127.0.0.6             0.0%     2   19.1  18.5  17.9  19.1   0.9
     7.|-- 127.0.0.7             0.0%     2   18.3  18.2  18.0  18.3   0.2
     8.|-- 127.0.0.8             0.0%     2   89.9  61.6  33.3  89.9  40.0
     9.|-- 127.0.0.9             0.0%     2   18.5  18.3  18.1  18.5   0.2
    10.|-- 127.0.0.10            0.0%     2   20.4  19.8  19.2  20.4   0.8

`mtr-exporter` exposes the measured values like this:

    # mtr run: 2020-03-08T16:37:05.000377Z
    # cmdline: /usr/local/sbin/mtr -j -c 2 -n example.com
    mtr_report_duration_ms_gauge{bitpattern="0x00",dst="example.com",psize="64",src="src.example.com",tests="2",tos="0x0"} 7179 1583685425000
    mtr_report_count_hubs_gauge{bitpattern="0x00",dst="example.com",psize="64",src="src.example.com",tests="2",tos="0x0"} 10 1583685425000
    mtr_report_loss_gauge{bitpattern="0x00",hop="first",count="1",dst="example.com",host="127.0.0.1",psize="64",src="src.example.com",tests="2",tos="0x0"} 0.000000 1583685425000
    mtr_report_snt_gauge{bitpattern="0x00",hop="first",count="1",dst="example.com",host="127.0.0.1",psize="64",src="src.example.com",tests="2",tos="0x0"} 2 1583685425000
    mtr_report_last_gauge{bitpattern="0x00",hop="first",count="1",dst="example.com",host="127.0.0.1",psize="64",src="src.example.com",tests="2",tos="0x0"} 0.380000 1583685425000
    mtr_report_avg_gauge{bitpattern="0x00",hop="first",count="1",dst="example.com",host="127.0.0.1",psize="64",src="src.example.com",tests="2",tos="0x0"} 0.480000 1583685425000
    mtr_report_best_gauge{bitpattern="0x00",hop="first",count="1",dst="example.com",host="127.0.0.1",psize="64",src="src.example.com",tests="2",tos="0x0"} 0.380000 1583685425000
    mtr_report_wrst_gauge{bitpattern="0x00",hop="first",count="1",dst="example.com",host="127.0.0.1",psize="64",src="src.example.com",tests="2",tos="0x0"} 0.570000 1583685425000
    mtr_report_stdev_gauge{bitpattern="0x00",hop="first",count="1",dst="example.com",host="127.0.0.1",psize="64",src="src.example.com",tests="2",tos="0x0"} 0.130000 1583685425000

Each hop gets a label `"hop"="first"`, `"hop"="last"`, `"hop"="first_last"` or
`"hop"="intermediate"`, depending where on the path to the destination the hop
is. 

Legacy: the last hop in the list of tested hosts contains the label `"last"="true"`.
Use `hop=~".*last"` in your Prometheus queries to achieve the same.

When [prometheus] scrapes the data, you can visualise the observed values:

![MTR results in prometheus](./media/screenshot-2020-03-08+181019.9188279670.png "MTR 1")

![MTR results in prometheus](./media/screenshot-2020-03-08+181030.4810786850.png "MTR 1")

## Usage

    $> mtr-exporter [FLAGS] -- [MTR-FLAGS]

    FLAGS:
    -bind       <bind-address>
                bind address (default ":8080")
    -flag.deprecatedMetrics
                render deprecated metrics (default: false)
                helps with transition time until deprecated metrics are gone
    -h
                show help
    -jobs       <path-to-jobsfile>
                file describing multiple mtr-jobs. syntax is given below.
    -label      <job-label>
                use <job-label> in prometheus-metrics (default: "mtr-exporter-cli")
    -mtr        <path-to-binary>
                path to mtr binary (default: "mtr")
    -schedule   <schedule>
                schedule at which often mtr is launched (default: "@every 60s")
                examples:
                   @every <dur>  - example "@every 60s"
                   @hourly       - run once per hour
                   10 * * * *    - execute 10 minutes after the full hour
                see https://en.wikipedia.org/wiki/Cron
    -tslogs
                use timestamps in logs
    -watch-jobs <schedule>
                periodically watch the file defined via -jobs (default: "")
                if it has changed stop previously running mtr-jobs and apply
                all jobs defined in -jobs.
    -version
                show version
    MTR-FLAGS:
            see "man mtr" for valid flags to mtr.

At `/metrics` the measured values of the last run are exposed.

### Examples

    $> mtr-exporter -- example.com
    # probe every minute "example.com"

    $> mtr-exporter -- -n example.com
    # probe every minute "example.com", do not resolve DNS

    $> mtr-exporter -schedule "@every 30s" -- -G 1 -m 3 -I ven3 -n example.com
    # probe every 30s "example.com", wait 1s for response, try a max of 3 hops,
    # use interface "ven3", do not resolve DNS.

### Jobs-File Syntax

    # comment lines start with '#' are ignored
    # empty lines are ignored as well
    label -- <schedule> -- mtr-flags

Example:

    quad9       -- @every 120s -- -I ven1 -n 9.9.9.9
    example.com -- @every 45s  -- -I ven2 -n example.com


## Requirements

Runtime:

* mtr-0.89 and newer (added --json support)

Build:

* golang-1.21 and newer

## Building

    $> git clone https://github.com/mgumz/mtr-exporter
    $> cd mtr-exporter
    $> make

One-off building and "installation":

    $> go install github.com/mgumz/mtr-exporter/cmd/mtr-exporter@latest

## Testing the Exporter

For a simple initial test, run the container as follows:

```bash
sudo docker run --rm -p 9469:9469 billimek/prometheus-speedtest-exporter:latest
```

Then invoke the `/probe` endpoint:

```bash
curl "http://localhost:9469/probe?script=speedtest"
```

After about 15 to 30 seconds or so you should see a result like this:

```bash
# HELP script_success Script exit status (0 = error, 1 = success).
# TYPE script_success gauge
script_success{} 1
# HELP script_duration_seconds Script execution time, in seconds.
# TYPE script_duration_seconds gauge
script_duration_seconds{} 99.714076
# HELP speedtest_latency_seconds Latency
# TYPE speedtest_latency_seconds gauge
speedtest_latency_seconds 17.363
# HELP speedtest_jittter_seconds Jitter
# TYPE speedtest_jittter_seconds gauge
speedtest_jittter_seconds 1.023
# HELP speedtest_download_bytes Download Speed
# TYPE speedtest_download_bytes gauge
speedtest_download_bytes 5852661
# HELP speedtest_upload_bytes Upload Speed
# TYPE speedtest_upload_bytes gauge
speedtest_upload_bytes 2433723
# HELP speedtest_downloadedbytes_bytes Downloaded Bytes
# TYPE speedtest_downloadedbytes_bytes gauge
speedtest_downloadedbytes_bytes 43619764
# HELP speedtest_uploadedbytes_bytes Uploaded Bytes
# TYPE speedtest_uploadedbytes_bytes gauge
speedtest_uploadedbytes_bytes 23199680
```

## Prometheus configuration

The script_exporter needs to be passed the script name as a parameter (script). It is advised to use a long `scrape_interval` to avoid excessive bandwidth use.

Example config:

```yaml
scrape_configs:
  - job_name: 'speedtest'
    metrics_path: /probe
    params:
      script: [speedtest]
    static_configs:
      - targets:
        - 127.0.0.1:9469
    scrape_interval: 60m
    scrape_timeout: 90s
  - job_name: 'script_exporter'
    metrics_path: /metrics
    static_configs:
      - targets:
        - 127.0.0.1:9469
```

## helm chart

If running in kubernetes, there is a helm chart leveraging this with a built-in `ServiceMonitor` for an autoconfigured solution: https://github.com/billimek/billimek-charts/tree/master/charts/speedtest-prometheus

## Grafana Dashboard

Included is an [example grafana dashboard](speedtest-exporter.json) as shown in the screenshot above.

## Speed Testing Against Multiple Target Servers

By default speedtest will automatically choose a server close to you.  You may override this choice and specify one or more Speedtest servers to test against by setting the `server_ids` environment variable.  For example in Docker Compose:

```yaml
  speedtest:
    image: "billimek/prometheus-speedtest-exporter:latest"
    restart: "on-failure"
    ports:
      - 9469:9469
    environment:
      - server_ids=3855,1782,2225 # 3855 => DTAC Bangkok; 1782 => Comcast Seattle; 2225 => Telstra Melbourne
```

The exporter will now run speedtest for each server that you specify one-by-one.  Generated metrics will also be labeled with the server ID - for example:

```
speedtest_latency_seconds{server_id="3855"} 17.363
...
speedtest_latency_seconds{server_id="1782"} 251.393
...
speedtest_latency_seconds{server_id="2225"} 292.73
```

As you add more servers you may need to extend the scrape_timeout for the Prometheus job so it doesn't get killed before it completes:

```yml
  - job_name: "speedtest"
    metrics_path: /probe
    params:
      script: [speedtest]
    static_configs:
      - targets:
        - 127.0.0.1:9469
    scrape_interval: 60m
    scrape_timeout: 10m
```

Use this [searchable list](https://williamyaps.github.io/wlmjavascript/servercli.html) to find server ID's.

## License

see LICENSE file

## Author(s)

* Mathias Gumz <mg@2hoch5.com>

[mtr]: https://www.bitwizard.nl/mtr/index.html
[prometheus]: https://prometheus.io
