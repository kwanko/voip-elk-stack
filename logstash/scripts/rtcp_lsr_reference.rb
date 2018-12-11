def register(params)
    @ntp_timestamp_sec_hex_field = params["ntp_timestamp_sec_hex"]
    @ntp_timestamp_usec_hex_field = params["ntp_timestamp_usec_hex"]
end

def filter(event)
    begin
        ntp_timestamp_sec = event.get(@ntp_timestamp_sec_hex_field)
        ntp_timestamp_usec = event.get(@ntp_timestamp_usec_hex_field)
        if (ntp_timestamp_sec.nil?) || (ntp_timestamp_usec.nil?)
            return [event]
        end
        if !(ntp_timestamp_sec.is_a? String)
            raise "invalid field type #{@ntp_timestamp_sec_hex_field} => #{ntp_timestamp_sec}, type => #{ntp_timestamp_sec.class}"
        end
        if !(ntp_timestamp_usec.is_a? String)
            raise "invalid field type #{@ntp_timestamp_usec_hex_field} => #{ntp_timestamp_usec}, type => #{ntp_timestamp_usec.class}"
        end
        lsr_reference = "0x%s%s" % [ntp_timestamp_sec[6..-1], ntp_timestamp_usec[2..5]]
        event.set("[rtcp][sender_information][lsr_reference]", lsr_reference)
    rescue => e
        event.tag("_rtcplsrreferencefailure")
        logger.error("#{e.backtrace.first}: #{e.message} / #{e.class}")
    end
	return [event]
end
