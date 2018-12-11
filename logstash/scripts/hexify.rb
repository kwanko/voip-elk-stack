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
                event.tag("_hexifyfailure")
                logger.warn("invalid field type", field => value, "type" => value.class)
                next
            end
            hex = value.to_s(16).rjust(@field_length_in_bytes * 2, '0')
            hex_str = "0x%s" % hex
            if field[-1..-1] == "]"
                new_field = field[0..-2] + "_hex]"
            else
                new_field = field + "_hex"
            end
            event.set(new_field, hex_str)
        end
    rescue => e
        event.tag("_hexifyfailure")
        logger.error("#{e.backtrace.first}: #{e.message} / #{e.class}")
    end
	return [event]
end
