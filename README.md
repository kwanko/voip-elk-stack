# voip-elk-stack

Here you will find an implementation of an Elasticsearch/Logstash/Kibana based VOIP analysis platform.

# Why ?

I didn't find many open source solution to analyze VOIP quality. In fact, the only one was [HOMER](https://github.com/sipcapture/homer) that I used for a time.

Why not HOMER ? At the time of writing (end of year 2018), Homer5 is based on php 5.6 which will be deprecated at the end of the year and the new version of HOMER is still under development. So I decided to build my own VOIP analysis platform based on the classic open source ELK stack.

# How ?

![Architecture](/images/architecture.png)

The pipeline is composed of:

* 2 capture agents on each IPBX:

  - filebeat to export asterisk cdr csv file.
  - captagent to capture SIP and RTCP packets and send them to the collector.

* logstash as a collector to extract and transform data:

  - asterisk cdr parsing,
  - sip message parsing,
  - rtcp parsing,
  - rtcp field conversions,
  - rtt computing from RTCP,
  - jitter and mos computing.

* elasticsearch to store transformed data into 3 different indices:

  - `asterisk-cdr-%{+YYYY.MM.dd}`
  - `sip-capture-%{+YYYY.MM.dd}`
  - `rtcp-capture-%{+YYYY.MM.dd}`

* kibana to explore and graph data.

# Dashboards examples

* Call quality dashboard

![Call quality dashboard with multiple calls](/images/call_quality_dashboard-multiple_calls.png)

![Call quality dashboard filtered on a single call](/images/call_quality_dashboard-single_call.png)

* SIP statistics

![SIP statistic dashboard](/images/sip_statistic_dashboard.png)

* CDR statistics

![CDR statistic dashboard](/images/cdr_statistic_dashboard.png)

# Contribution

This project is open to any contribution. Feel free to use it and contribute if you want.
