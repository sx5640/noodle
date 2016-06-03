module ArticleMixins::Zone
  # define a method that count the number of articles in each time unit. the unit is determined by the length of the selected time frame. if the selected articles spans a year, this method will return the number of articles per day; if the selected articles spans 2 years, this method will return the number of articles per 2 days
  def count_articles(articles)
    begin_date = articles.first.publication_time
    end_date = articles.last.publication_time

    step = ((end_date - begin_date) / 1.year).to_i.day

    data = []

    i = 0

    while begin_date + i*step <= end_date + step

      start_time = begin_date + i*step
      end_time = begin_date + (i+1)*step

      articles_in_unit = articles.select { |article|
      article.publication_time >= begin_date + i*step &&
      article.publication_time < begin_date + (i+1)*step}

      data[i] = {
        start_time: start_time,
        end_time: end_time,
        count: articles_in_unit.length,
      }

      i += 1
    end
    data_sum = articles.length
    data_size = data.length
    data_average = data_sum.to_f / data_size
    first_difference = []
    for i in (0..(data_size - 2))
      first_difference[i] = data[i+1][:count] - data[i][:count]
    end

    params = {
      data: data,
      data_not_zoned: data.clone,
      first_difference: first_difference,
      data_size: data_size,
      data_average: data_average
    }
    return params
  end

  # define a recursive method that find the peak in a given data, and define a zone surrounding the peak.
  def create_zone_from_peak(params)
    # Initialize the function
      # deep copying the params
    params_temp = Marshal.load(Marshal.dump(params))
    data_temp = params_temp[:data]
    data_not_zoned = params_temp[:data_not_zoned]
    first_difference = params_temp[:first_difference]
    data_size = params_temp[:data_size]
    data_average = params_temp[:data_average]
    zones = []

    top_time_unit = data_temp.max {|a, b| a[:count] <=> b[:count]}
    top_value = top_time_unit[:count]
    top_index = data_temp.index(top_time_unit)

    step = 4
    min_peak_multiplier = 4

    # this is the recursive condition: if the peak has value greater than n times of the average, it will generate a hot zone
    if top_value > min_peak_multiplier * data_average

      # call the move_boundary method to get the boundary of the top peak
      start_index = move_boundary(first_difference, data_not_zoned, data_size, top_index, -step, step)
      end_index = move_boundary(first_difference, data_not_zoned, data_size, top_index, step, step)
      # save the result
      zones << {
        start_time: data_temp[start_index][:start_time], end_time: data_temp[end_index][:end_time],
        top_value: top_value
      }

      # mark the zone so it won't be used again
      for i in (start_index..end_index)
        data_not_zoned[i] = 'stop'
        data_temp[i][:count] = 0
      end

      # method recurs
      zones += create_zone_from_peak(params_temp)

    # otherwise, it will break
    else
      # go through all points in data_not_zoned, and make cold zones

      i = 0
      while i < data_size
        # skip hot zones
        if data_not_zoned[i] == 'stop'
          i += 1
        else
          # start a cold zone
          start_index = i

          # end at a hot zone or end of the data
          if  data_not_zoned[i..(data_size - 1)].include?('stop')
            end_index = i + data_not_zoned[i.. (data_size - 1)].index('stop') - 1
          else
            end_index = data_size - 1
          end

          # calculate top_value
          top_time_unit_temp = data_temp[start_index..end_index].max {|a, b| a[:count] <=> b[:count]}
          top_value_temp = top_time_unit_temp[:count]

          # save the zone
          zones << {
            start_time: data_temp[start_index][:start_time], end_time: data_temp[end_index][:end_time],
            top_value: top_value_temp
          }

          i = end_index + 1
        end
      end
    end
    return zones.sort { |a, b| a[:start_time] <=> b[:start_time] }
  end

  def divide_into_zones_from_peak(articles, params)
    zones = self.create_zone_from_peak(params)
    for i in (0 .. (zones.length - 1))
      zones[i][:article_list] = articles.select { |article|
        article.publication_time >= zones[i][:start_time] && article.publication_time < zones[i][:end_time]
      }
      zones[i][:count] = zones[i][:article_list].size
      zones[i][:keywords] = generate_keywords(zones[i][:article_list])
    end
    zones = Keyword.remove_generic_keywords(zones)
    zones = calculate_hotness(zones)
    return zones
  end

  private
  # define a method that determines the boundary around a given peak
  def move_boundary(first_difference, data_not_zoned, data_size, top_index, move_by, step)
    # determine the direction the boundary is moving towards
    direction = move_by / move_by.abs

    if top_index + move_by >= data_size - 1
      return data_size - 1
    end

    # if move to an existing hot zone, stop at the boundary
    data_not_zoned_selected = []
    top_index.step(top_index + move_by, direction).to_a.each do |index|
      data_not_zoned_selected << data_not_zoned[index]
    end

    if data_not_zoned_selected.include?('stop')
      return top_index + direction*data_not_zoned_selected.index('stop') - direction


    # if move to the first or last data point, stop at there
    elsif top_index + move_by <=0
      return 0

    elsif top_index + move_by >= data_size - 1
      return data_size - 1

    # otherwise, move the boundary
    else
      # calculate the average of the first_difference for the data points in the latest move
      first_difference_sum = 0

      indices_selected = (top_index + move_by - direction * step).step(top_index + move_by, direction).to_a.sort

      indices_selected.pop

      indices_selected.each do |index|
        first_difference_sum += first_difference[index]
      end

      first_difference_average = first_difference_sum.to_f / indices_selected.length

      # result_direction tells you if the points included in the last move has upward slope or downward slope. it will retrun -1 if the slope is going down, and 1 if the slope is going up
      if first_difference_average == 0
        result_direction = 0
      else
        result_direction = (first_difference_average / first_difference_average.abs).to_i
      end

      # if the boundary is moving to the - side, and last move has a upward overall slop, it means the timezone is still heating up during the last selected points. we want to catch the turnning point when slope turn from flat or downward to upward, which represents the timepoint the heat started.
      # if we don't hit the turnning point, then keep moving the boundary; if we hit the turnning, redo the move but with smaller steps, until you hit the turnning point
      # in this example, if direction is - and slope is going up, direction * result_direction = -1 * 1 = -1.
      # same for moving to the + side. if you the boundary moves to the + side, we care about slope going down, and turns up.
      if direction * result_direction == -1
        return move_boundary(first_difference, data_not_zoned, data_size, top_index, move_by + direction * step, step)

      elsif direction * result_direction == 1 or result_direction == 0

        if step.abs == 1
          return top_index + move_by

        else
          return move_boundary(first_difference, data_not_zoned, data_size, top_index, move_by + direction * step / 2, step / 2)
        end
      end
    end

  end

  def calculate_hotness(zones)
    # find the max, min, average
    temp = zones.inject([0,100000,0]) do |temp, zone|
      zone_size = (zone[:end_time] - zone[:start_time]) / 1.day
      zone_average_count = zone[:count] / zone_size

      if temp[0] < zone_average_count
        temp[0] = zone_average_count
      end
      if temp[1] > zone_average_count
        temp[1] = zone_average_count
      end
      temp[2] += zone_average_count
      temp
    end
    hottest = temp[0]
    coldest = temp[1]
    total = temp[2]
    average = total/zones.length
    #calculate hotness based on the count of articles in the zone, comparing to average, max, min
    zones.each do |zone|
      zone_size = (zone[:end_time] - zone[:start_time]) / 1.day
      zone_average_count = zone[:count] / zone_size

      if zone_average_count > average
        zone[:hotness] = (5 + (zone_average_count - average) * 5 / (hottest - average)).round
      elsif zone_average_count < average
        zone[:hotness] = 5 - ((average - zone_average_count) * 5 / (average - coldest)).round
      elsif zone_average_count == average
        zone[:hotness] = 5
      end
    end
    return zones
  end

end
