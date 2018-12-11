# Compute RTT using dlsr, lsr and reception timestamp accordingly to RFC3550 section "6.4.1 SR: Sender Report RTCP Packet" in DLSR definition
def register(params)
    @dlsr_field = params["dlsr"]
    @lsr_hex_field = params["lsr_hex"]
    @reception_unix_ts_s_field = params["reception_unix_ts_s"]
    @reception_unix_ts_us_field = params["reception_unix_ts_us"]
    @target_field = params["target"]
end

def filter(event)
    begin
        # validate dlsr
        dlsr = event.get(@dlsr_field)
        if dlsr.nil?
            return [event]
        end
        if !(dlsr.is_a? Integer)
            raise "invalid field type #{@dlsr_field} => #{dlsr}, type => #{dlsr.class}"
        end
        # validate lsr_hex
        lsr_hex = event.get(@lsr_hex_field)
        if lsr_hex.nil?
            return [event]
        end
        if !(lsr_hex.is_a? String)
            raise "invalid field type #{@lsr_hex_field} => #{lsr_hex}, type => #{lsr_hex.class}"
        end
        if !lsr_hex[/^0x\h{8}$/]
            raise "Invalid hexadecimal value #{@lsr_hex_field} => #{lsr_hex}"
        end
        if lsr_hex == "0x00000000"
            return [event]
        end
        # validate reception_unix_ts_s
        reception_unix_ts_s = event.get(@reception_unix_ts_s_field)
        if reception_unix_ts_s.nil?
            return [event]
        end
        if !(reception_unix_ts_s.is_a? Integer)
            raise "invalid field type #{@reception_unix_ts_s_field} => #{reception_unix_ts_s}, type => #{reception_unix_ts_s.class}"
        end
        # validate reception_unix_ts_us
        reception_unix_ts_us = event.get(@reception_unix_ts_us_field)
        if reception_unix_ts_us.nil?
            return [event]
        end
        if !(reception_unix_ts_us.is_a? Integer)
            raise "invalid field type #{@reception_unix_ts_us_field} => #{reception_unix_ts_us}, type => #{reception_unix_ts_us.class}"
        end
        # compute difference in microseconds between SR emission and RR reception
        ## compute second part
        reception_ntp_ts_sec = reception_unix_ts_s + ((70*365 + 17)*86400)
        reception_ntp_ts_sec_hex = reception_ntp_ts_sec.to_s(16).rjust(8, '0')
        difference_sec = reception_ntp_ts_sec_hex[4..8].to_i(16) - lsr_hex[2..5].to_i(16)
        logger.debug("difference_sec: #{difference_sec} / reception_unix_ts_s: #{reception_unix_ts_s} / lsr_hex: #{lsr_hex}")
        ## compute microsecond part
        reception_ntp_ts_usec = (reception_unix_ts_us << 32) / 1000000
        difference_ntp_usec = reception_ntp_ts_usec - lsr_hex[6..10].ljust(8, '0').to_i(16)
        difference_usec = (difference_ntp_usec * 1000000) >> 32
        logger.debug("difference_usec: #{difference_usec} / reception_unix_ts_us: #{reception_unix_ts_us} / lsr_hex: #{lsr_hex}")

        difference_in_usec = difference_sec * 1000000 + difference_usec

        # substract dlsr
        delay_lsr_in_usec = (dlsr * 1000000) / 65536
        logger.debug("delay_lsr_in_usec: #{delay_lsr_in_usec}")
        rtt_us = difference_in_usec - delay_lsr_in_usec
        logger.debug("rtt_us: #{rtt_us}")
        rtt_ms = rtt_us.to_f / 1000

        event.set(@target_field, rtt_ms)
    rescue => e
        event.tag("_rtcprttfailure")
        logger.error("#{e.backtrace.first}: #{e.message} / #{e.class}")
    end
	return [event]
end
