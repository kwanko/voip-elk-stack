# Filebeat

Filebeat is the log exporter agent of the ELK stack. It allows us to monitor the CDR file and send each new CDR to Logstash.

It also add the local timezone to the sent event metadata for later date computation by Logstash.
