cache = {}

values_names = [
  '/interface/statistics/out-octets',
  '/interface/statistics/in-octets'
]

N=2

def apply(*events):
  for e in events:
    for value_name in values_names:
      v = e.values.get(value_name)
      # check if v is not None and is a digit to proceed
      if not v:
        continue
      if not v.isdigit():
        continue
      # update cache with the latest value
      val_key = "_".join([e.tags["source"], e.tags["interface_name"], value_name])
      if not cache.get(val_key):
        # initialize the cache entry if empty
        cache.update({val_key: []})
      if len(cache[val_key]) > N:
        # remove the oldest entry if the number of entries reached N
        cache[val_key] = cache[val_key][1:]
      # update cache entry
      cache[val_key].append((int(v), e.timestamp))
      # get the list of values
      val_list = cache[val_key]
      # calculate rate
      e.values[value_name+"_rate"] = rate(val_list)
      e.values.pop(value_name)
    
  return events

def rate(vals):
  previous_value, previous_timestamp = None, None
  for value, timestamp in vals:
    if previous_value != None and previous_timestamp != None:
      time_diff = (timestamp - previous_timestamp) / 1000000000 # 1 000 000 000
      if time_diff > 0:
        value_diff = value - previous_value
        rate = value_diff / time_diff
        return rate

    previous_value = value
    previous_timestamp = timestamp

  return 0
  