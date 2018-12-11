def register(params)
    @source_sec_field = params["source_sec"]
    @source_usec_field = params["source_usec"]
    @target_field = params["target"]
end

def filter(event)
    begin
        source_sec = event.get(@source_sec_field)
        source_usec = event.get(@source_usec_field)
        if (source_sec.nil?) || (source_usec.nil?)
            return [event]
        end
        if !(source_sec.is_a? Integer)
            raise "invalid field type #{@source_sec_field} => #{source_sec}, type => #{source_sec.class}"
        end
        if !(source_usec.is_a? Integer)
            raise "invalid field type #{@source_usec_field} => #{source_usec}, type => #{source_usec.class}"
        end
        unix_sec = source_sec - ((70*365 + 17)*86400)
        unix_usec = (source_usec * 1000000) >> 32
        unix_timestamp_ms = (unix_sec * 1000000 + unix_usec) / 1000
        event.set(@target_field, unix_timestamp_ms)
    rescue => e
        event.tag("_ntptimestampconverterfailure")
        logger.error("#{e.backtrace.first}: #{e.message} / #{e.class}")
    end
	return [event]
end
