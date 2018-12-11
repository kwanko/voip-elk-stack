def register(params)
    @dlsr_field = params["dlsr"]
    @target_field = params["target"]
end

def filter(event)
    begin
        dlsr = event.get(@dlsr_field)
        if (dlsr.nil?)
            return [event]
        end
        if !(dlsr.is_a? Integer)
            raise "invalid field type #{@dlsr_field} => #{dlsr}, type => #{dlsr.class}"
        end
        delay_lsr_in_usec = (dlsr * 1000000) / 65536
        event.set(@target_field, delay_lsr_in_usec)
    rescue => e
        event.tag("_rtcpdlsrconverterfailure")
        logger.error("#{e.backtrace.first}: #{e.message} / #{e.class}")
    end
	return [event]
end
