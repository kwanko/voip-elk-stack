# Kibana

Kibana is the data exploration and graphing frontend for elasticsearch. It allows us to efficiently debug specific problems or plot global activity in dashboards.

RTCP, CDR logs and SIP traces are stored into 3 different indices. However, the common field `sip_call_id` can be used to correlate these 3 type of data.

I've created 3 dashboards adapated to my needs:

* a call quality dashboard: this dashboard shows MOS, jitter, RTT and packet loss evolution for one or more call id.
* a sip statistic dashboard: this dashboard shows SIP method repartition and successful call repartition amongst capture endpoints.
* a cdr oriented dashboard: this dashboard shows the top 20 callers and callees, the repartition of call disposition amongst IPBX and the list of more than 30 seconds lasting calls.
