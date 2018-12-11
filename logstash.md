# Logstash

This is the heart of the system. Three different data types are processed:

* CDR records,
* SIP traces,
* RTCP messages.

## CDR records

The CDR extracted by a Filebeat agent are received by Logstash on port 5044 using the beat protocol.

The main transformations of CDR a event are:

1. saving the capture endpoint hostname in the `capture_endpoint` field,
2. parsing the csv content to extract each field,
3. setting the `@timestamp` field of the event accordingly to the `start_time` field,
4. removing invalid numeral field (mainly Infinite values wrongly set by asterisk),
5. casting fields to float, integer or date,
6. setting `local_jitter_standard_deviation` field to `nil` if its value is invalid (negative or arbitrarily more than 3 600 000).

It is then sent to Elasticsearch in the daily dedicated index `asterisk-cdr-%{+YYYY.MM.dd}`.

## SIP traces

SIP traces captured by CaptAgent are sent to Logstash as a JSON message encoded in `US-ASCII` over UDP on port 9071.

The main transformations of a SIP event are:

1. saving the capture endpoint hostname in the `capture_endpoint` field,
2. resolving PTR records of `src_ip4` and `dst_ip4` in `src_host` and `dst_host`,
3. parsing the sip message using a custom logstash filter plugin available here: [https://github.com/limhud/logstash-filter-sip](https://github.com/limhud/logstash-filter-sip).

It is then stored in Elasticsearch in the daily dedicated index `sip-capture-%{+YYYY.MM.dd}`.

## RTCP messages

RTCP messages captured by CaptAgent are sent to Logstash as a JSON message encoded in `US-ASCII` over UDP on port 9072.

The main transformations of a RTCP event are:

1. saving the capture endpoint hostname in the `capture_endpoint` field,
2. renaming the `corr_id` field to `sip_call_id` for easy correlation with the other indices,
3. parsing the RTCP message encoded as JSON in the `payload` field,
4. splitting the event in multiple event on array fields like `[rtcp][report_blocks]` and `[rtcp][sdes_information]`,
5. fixing wrong endianness decoding from CaptAgent with `endianness_switcher.rb` for fields `[rtcp][sender_information][ntp_timestamp_sec]`, `[rtcp][sender_information][ntp_timestamp_usec]` and `[rtcp][sender_information][rtp_timestamp]`,
6. converting `[rtcp][sender_information][ntp_timestamp_sec]`, `[rtcp][sender_information][ntp_timestamp_usec]` and `[rtcp][report_blocks][lsr]` to hexadecimal in order to be used later,
7. computing unix timestamp (`[rtcp][sender_information][unix_timestamp_ms]`) from `[rtcp][sender_information][ntp_timestamp_sec]` and `[rtcp][sender_information][ntp_timestamp_usec]`,
8. computing LSR (Last Sender Report) reference from hex values of `[rtcp][sender_information][ntp_timestamp_sec]` and `[rtcp][sender_information][ntp_timestamp_usec]` (cf. [RFC 3550 - 6.4.1 SR: Sender Report RTCP Packet / last SR timestamp (LSR): 32 bits](https://tools.ietf.org/html/rfc3550#section-6.4.1)),
9. converting DLSR (Delay Since Last Sender Report) to microseconds in `[rtcp][report_blocks][dlsr_us]`,
10. computing RTT in `[rtcp][rtt]` using DLSR, LSR and reception timestamp as specified in [RFC 3550 - 6.4.1 SR: Sender Report RTCP Packet / delay since last SR (DLSR): 32 bits](https://tools.ietf.org/html/rfc3550#section-6.4.1),
11. computing percent of packet lost in `[rtcp][report_blocks][percent_lost]` using `[rtcp][report_blocks][fraction_lost]`,
12. finally, computing jitter (`[rtcp][jitter]`) and mos (`[rtcp][mos]`) from RTT and percent of packet lost (additionnal timestamp and call id metadata are used by the jitter computation process),
13. resolving PTR records of `src_ip4` and `dst_ip4` in `src_host` and `dst_host`.

Most of these very specific computation are done thanks to dedicated ruby scripts.

It is then stored in Elasticsearch in the daily dedicated index `rtcp-capture-%{+YYYY.MM.dd}`.
