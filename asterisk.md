# Asterisk

The only requirement is for Asterisk (or another IPBX) to log its CDR in a csv file with one record per line and the following columns:

* `sip_call_id`
* `linked_id`
* `unique_id`
* `sequence`
* `caller_id_number`
* `caller_id`
* `destination_extension`
* `destination_context`
* `disposition`
* `hangup_cause`
* `start_time`
* `answer_time`
* `end_time`
* `duration`
* `billsec`
* `last_application`
* `last_application_data`
* `channel`
* `destination_channel`
* `packet_sent`
* `packet_received`
* `local_rx_packet_loss`
* `local_tx_packet_loss`
* `local_rx_jitter`
* `local_tx_jitter`
* `local_jitter_max`
* `local_jitter_min`
* `local_jitter_normal_deviation`
* `local_jitter_standard_deviation`
* `rtt`
* `minrtt`
* `maxrtt`
* `account_code`

You will find the cdr config file and the helper macro in the asterisk directory.

To trigger the macro at the end of a call, just add the following operation at the beginning of a call handling:

```
    same => n,Set(CHANNEL(hangup_handler_push)=qos-cdr,s,1)
```

You can notice that RTT, jitter and packet loss are logged into each CDR. However, these values are not used to compute the MOS of each call for 2 main reasons:

* RTCP gives a better precision showing the evolution of these values during the call,
* Asterisk returned values seems not always trustworthy to me.

Nevertheless, I chose to log them anyway and keep them in elasticsearch just in case.
