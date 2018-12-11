def register(params)
    @fields = params["fields"]
    @field_length_in_bytes = params["field_length_in_bytes"]
end

def filter(event)
    begin
        @fields.each do |field|
            value = event.get(field)
            if value.nil?
                next
            end
            if !(value.is_a? Integer)
                event.tag("_endiannessswitcherfailure")
                logger.warn("invalid field type", field => value, "type" => value.class)
                next
            end
            hex = value.to_s(16).rjust(@field_length_in_bytes * 2, '0')
            switched_value = hex.scan(/(..)(..)(..)(..)/).map(&:reverse).join.to_i(16)
            event.set(field, switched_value)
        end
    rescue => e
        event.tag("_endiannessswitcherfailure")
        logger.error("#{e.backtrace.first}: #{e.message} / #{e.class}")
    end
	return [event]
end
