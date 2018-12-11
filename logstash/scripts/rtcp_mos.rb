def register(params)
    if !(defined? @@semaphore)
        @@semaphore = Mutex.new
    end
    @timestamp_field = params["timestamp"]
    @call_id_field = params["call_id"]
    @percent_lost_field = params["percent_lost"]
    @rtt_field = params["rtt"]
    @target_mos_field = params["target_mos"]
    @target_jitter_field = params["target_jitter"]
end

def timeout_map(current_timestamp)
    if !(defined? @@global_rtt_stats)
        return
    end
    @@semaphore.synchronize do
        to_delete = []
        @@global_rtt_stats.each do |key, value|
            if value[:last_update] < (current_timestamp - 300)
                to_delete.push(key)
            end
        end
        to_delete.each do |key|
            @@global_rtt_stats.delete(key)
        end
    end
end

def get_jitter_and_update(call_id, current_rtt, timestamp)
    jitter = 0
    @@semaphore.synchronize do
        if !(defined? @@global_rtt_stats)
            @@global_rtt_stats = {}
        end
        if @@global_rtt_stats.has_key? call_id
            jitter = current_rtt -  @@global_rtt_stats[call_id][:average_rtt]
            @@global_rtt_stats[call_id][:average_rtt] = (@@global_rtt_stats[call_id][:average_rtt] * @@global_rtt_stats[call_id][:cardinality] + current_rtt) / (@@global_rtt_stats[call_id][:cardinality] + 1)
            @@global_rtt_stats[call_id][:cardinality] = @@global_rtt_stats[call_id][:cardinality] + 1
            @@global_rtt_stats[call_id][:last_update] = timestamp
        else
            @@global_rtt_stats[call_id] = {}
            @@global_rtt_stats[call_id][:average_rtt] = current_rtt
            @@global_rtt_stats[call_id][:cardinality] = 1
            @@global_rtt_stats[call_id][:last_update] = timestamp
        end
    end
    return jitter
end

def filter(event)
    begin
        timestamp = event.get(@timestamp_field)
        call_id = event.get(@call_id_field)
        percent_lost = event.get(@percent_lost_field)
        rtt = event.get(@rtt_field)
        if (percent_lost.nil?) || (rtt.nil?) || (rtt < 0)
            return [event]
        end
        if timestamp.nil? || !(timestamp.is_a? Integer)
            raise "invalid call id #{@timestamp_field} => #{timestamp}, type => #{timestamp.class}"
        end
        if call_id.nil? || !(call_id.is_a? String)
            raise "invalid call id #{@call_id_field} => #{call_id}, type => #{call_id.class}"
        end
        if !(percent_lost.is_a? Float)
            raise "invalid field type #{@percent_lost_field} => #{percent_lost}, type => #{percent_lost.class}"
        end
        if !(rtt.is_a? Float)
            raise "invalid field type #{@rtt_field} => #{rtt}, type => #{rtt.class}"
        end
        if rtt <= 0.0
            return [event]
        end
        if (@target_mos_field.nil?) || !(@target_mos_field.is_a? String)
            raise "invalid mos target field #{@target_mos_field}"
        end
        if (@target_jitter_field.nil?) || !(@target_jitter_field.is_a? String)
            raise "invalid jitter target field #{@target_mos_field}"
        end
        jitter = get_jitter_and_update(call_id, rtt, timestamp)
        effective_latency = rtt + (jitter * 2) + 10
        if effective_latency < 160
            r_value = 93.2 - (effective_latency / 40.0)
        else
            r_value = 93.2 - (effective_latency.to_f - 120.0) / 10.0
        end
        r_value = r_value - (percent_lost * 2.5)
        mos = 1 + 0.035 * r_value + 0.000007 * r_value * (r_value - 60) * (100 - r_value)
        event.set(@target_mos_field, mos)
        event.set(@target_jitter_field, jitter)
        if mos > 5 || mos < 0
            event.tag("_rtcpmosinvalid")
        end
        timeout_map(timestamp)
    rescue => e
        event.tag("_rtcpmosfailure")
        logger.error("#{e.backtrace.first}: #{e.message} / #{e.class}")
    end
	return [event]
end
