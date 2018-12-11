def register(params)
    @fraction_lost_field = params["fraction_lost"]
    @target_field = params["target"]
end

def filter(event)
    begin
        fraction_lost = event.get(@fraction_lost_field)
        if (fraction_lost.nil?)
            return [event]
        end
        if !(fraction_lost.is_a? Integer)
            raise "invalid field type #{@fraction_lost_field} => #{fraction_lost}, type => #{fraction_lost.class}"
        end
        if fraction_lost < 0
            return [event]
        end
        if (@target_field.nil?) || !(@target_field.is_a? String)
            raise "invalid target field #{@target_field}"
        end
        percent_lost = fraction_lost / 256.0
        event.set(@target_field, percent_lost)
    rescue => e
        event.tag("_rtcppercentlostfailure")
        logger.error("#{e.backtrace.first}: #{e.message} / #{e.class}")
    end
	return [event]
end
