require 'benchmark'

module ArticleMixins::Zone
  # given a list of articles, this method will tell you how the article density changes as time goes by. it divides the list into time units equal in size, count the articles in each time unit.
  # it will also return some calculations based on the article count, which will later be used in other methods
  def count_articles(articles)
    puts "#{Time.now.strftime("%m/%d/%Y %T,%L")}************* Count Articles *************"

    # starting by finding the starting date and end date of the given list of articles, and calculate the time step for each time unit.
    # also generate the list of article ids to be used in a sql query call later on. by using query calls, it will improve the performace slightly.

    article_ids = articles.map { |e| e[:id]  }

    begin_date = articles.first.publication_time
    end_date = articles.last.publication_time

    step = ((end_date - begin_date) / 9.month + 1).to_i.day

    data = []

    # the while loop will go through each time unit, and returns a hash including the number of articles within. it is
    i = 0
    t = Benchmark.measure do

      while begin_date + i*step <= end_date + step

        start_time = begin_date + i*step
        end_time = begin_date + (i+1)*step

        data[i] = {
          start_time: start_time,
          end_time: end_time,
          count: Article.where(
            "id in (?) and publication_time between ? and ?",
            article_ids, begin_date + i*step, begin_date + (i+1)*step - 1
          ).length,
        }

        i += 1
      end
    end
    puts "while loop time: #{t}"

    # the rest are some calculations for later user
    # the first difference is important for dividing timezones. it is the "trend" of the article density
    data_sum = articles.length
    data_size = data.length
    data_size_non_0 = (data.select { |e| e[:count] >= 0  }).size
    data_average = data_sum.to_f / data_size
    data_average_non_0 = data_sum.to_f / data_size_non_0
    first_difference = []
    for i in (0..(data_size - 2))
      first_difference[i] = data[i+1][:count] - data[i][:count]
    end

    # finally putting the result together and return it.
    # notice there is a data_not_zoned object, it will be used when dividing the timezones using a recursive method. right not it is just a copy of data, or the time density
    params = {
      data: data,
      data_not_zoned: data.clone,
      first_difference: first_difference,
      data_size: data_size,
      data_average: data_average,
      data_average_non_0: data_average_non_0
    }
    return params
  end

  # define a recursive method that find the peak in a given data, and define a timezone surrounding the peak.
  # the idea is to find the peak within the given data, create a timezone around it, then call the method again, passing in the same data but without the identified peak. the recursive funciton shall find the second highest peak until all peaks are dealt with.
  def create_zone_from_peak(params)
    # Initialize the function by copying params
    puts "#{Time.now.strftime("%m/%d/%Y %T,%L")}************* Creating Zones *************"
      # deep copying the params so that changing the value of params won't effect the original data
    params_temp = Marshal.load(Marshal.dump(params))
    data_temp = params_temp[:data]
    data_not_zoned = params_temp[:data_not_zoned]
    # the following data copied will not be changed each time the recursive method is called. they will be used to determine the ending condition for recursively finding peaks and moving boundaries
    first_difference = params_temp[:first_difference]
    data_size = params_temp[:data_size]

    # in this method, we will ignore the "peaks" whose peakvalue is less than the average
    # however if there are only less than 5 timezones in total, then it is pointless to filter out any data point
    if data_size < 5
      data_average = 0
      data_average_non_0 = 0
    else
      data_average = params_temp[:data_average]
      data_average_non_0 = params_temp[:data_average_non_0]
    end
    zones = []

    # identifying the peak in the given data
    top_time_unit = data_temp.max {|a, b| a[:count] <=> b[:count]}
    top_value = top_time_unit[:count]
    top_index = data_temp.index(top_time_unit)

    # now let's move the boundaries
    # first setting up paramiters to determine howfast we are moving the boundaries each time and when to stop finding peaks
    step = 2
    min_peak_multiplier = 4

    # this is the recursive condition: if the peak has value greater than n times of the average, it will generate a hot zone
    if top_value > min_peak_multiplier * data_average_non_0

      # call the move_boundary method to get the boundary of the top peak
      start_index = move_boundary(first_difference, data_not_zoned, data_size, top_index, -step/2, step)
      end_index = move_boundary(first_difference, data_not_zoned, data_size, top_index, step, step)
      # save the result into zones
      zones << {
        start_time: data_temp[start_index][:start_time], end_time: data_temp[end_index][:end_time],
        peak_time: data_temp[top_index],
        top_value: top_value
      }

      # mark the zone so it won't be used again
      for i in (start_index..end_index)
        data_not_zoned[i] = 'stop'
        data_temp[i][:count] = 0
      end

      # method recurs
      zones += create_zone_from_peak(params_temp)

    # ignore the commented out part
    # otherwise, it will break
    # else
    #   # go through all points in data_not_zoned, and make cold zones
    #
    #   i = 0
    #   while i < data_size
    #     # skip hot zones
    #     if data_not_zoned[i] == 'stop'
    #       i += 1
    #     else
    #       # start a cold zone
    #       start_index = i
    #
    #       # end at a hot zone or end of the data
    #       if  data_not_zoned[i..(data_size - 1)].include?('stop')
    #         end_index = i + data_not_zoned[i.. (data_size - 1)].index('stop') - 1
    #       else
    #         end_index = data_size - 1
    #       end
    #
    #       # calculate top_value
    #       top_time_unit_temp = data_temp[start_index..end_index].max {|a, b| a[:count] <=> b[:count]}
    #       top_value_temp = top_time_unit_temp[:count]
    #
    #       # save the zone
    #       zones << {
    #         start_time: data_temp[start_index][:start_time], end_time: data_temp[end_index][:end_time],
    #         top_value: top_value_temp
    #       }
    #
    #       i = end_index + 1
    #     end
    #   end
    end
    # sort the zones and send the data for later use
    return zones.sort { |a, b| a[:start_time] <=> b[:start_time] }
  end

  # given a timezone with most related keywords, sort all the articles by its relevance to the most related keywords
  # the idea is, for every article, defines a value called zone_relevance. this value shall be the biggest for the article that has highest relevanceScore to most number of keywords from the top related keywords set. in another word, this value shall be proportional to the sum of relevanceScore between the article and each keywords in the top related keywords set.
  # also, we would like to pick the article that is closest to the peak. this means the zone_relevance shall be disproportional to the difference between publication_time and peak_time.
  def pick_most_relevant_articles(zones)
    puts "#{Time.now.strftime("%m/%d/%Y %T,%L")}************* Rank Top Articles *************"
    zones.each do |zone|
      # top_num defines how many keywords to be used when sorting the articles.
      top_num = 9
      top_keywords = zone[:keywords][0..top_num].map { |e| e[:keyword] }
      peak_time = zone[:peak_time]

      # zone_relevance is a hash with key being the name of the article, and value being the zone_relevance value
      zone_relevance = {}
      t = Benchmark.measure do
        zone[:article_list].each do |article|
          days_to_peak = (article[:publication_time] - peak_time[:start_time]) / 1.day

          zone_relevance[article[:title]] = 0
          KeywordAnalysis.where("article_id = ? AND name IN (?)", article[:id], top_keywords).each do |keyword_analysis|
            zone_relevance[article[:title]] += keyword_analysis[:relevance] / (days_to_peak.abs() + 4)
          end
        end
      end

      puts "double interation time: #{t}"
      # use the hash zone to sort the article list
      zone[:article_list].sort! {|a,b|
        zone_relevance[b[:title]] <=> zone_relevance[a[:title]]
      }
      # saving the hash zone_relevance for future use
      zone[:article_relevance] = zone_relevance
    end
    return zones
  end

  # this is the ultimate method in the zone module that will divide take a list of articles and divide them into timezones
  def divide_into_zones_from_peak(articles, params)
    puts "#{Time.now.strftime("%m/%d/%Y %T,%L")}************* Working on Zones *************"

    zones = self.create_zone_from_peak(params)
    for i in (0 .. (zones.length - 1))
      zones[i][:article_list] = articles.select { |article|
        article.publication_time >= zones[i][:start_time] && article.publication_time < zones[i][:end_time]
      }
      zones[i][:count] = zones[i][:article_list].size
      zones[i][:keywords] = Keyword.generate_keywords(zones[i][:article_list])
    end
    zones = Keyword.remove_generic_keywords(zones)
    zones = calculate_hotness(zones)
    zones = pick_most_relevant_articles(zones)
    puts "#{Time.now.strftime("%m/%d/%Y %T,%L")}************* End of Zones *************"
    return zones
  end

  # this is another ultimate method. it takes a different approach.
  # define a function that cut the selected time period into 20 zones with equal length. the function will return an array of zones, each as a hash, with start_time, end_time, list of articles within the time zone, count of articles within the zone, and 'hotness' of the zone
  def divide_into_unisized_zones(articles)
    # set the start_time to be the publication_time of the latest article, and end_time to be the publication_time of the oldest one. Then
    begin_date = articles.last.publication_time
    end_date = articles.first.publication_time
    # the +1 is to make sure the last zone will include the newest article
    time_unit = (end_date - begin_date + 1) / 20

    zones = []
    for i in (0 .. 19)
      zones[i] = {
                  start_time: begin_date + time_unit * i,
                  end_time: begin_date + time_unit * (i + 1)}
      zones[i][:article_list] = articles.select { |article|
                  article.publication_time >= zones[i][:start_time] && article.publication_time < zones[i][:end_time]}
      zones[i][:count] = zones[i][:article_list].size
      zones[i][:keywords] = Keyword.generate_keywords(zones[i][:article_list])
    end
    zones = self.calculate_hotness(zones)
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

  # defining a function that can calculate "hottest" of a zone, based on the number of articles it has comparing to the average, and to the max and min
  # defining a method that takes in a zone or a selection of articles and returns top keywords
  def calculate_hotness(zones)
    puts "#{Time.now.strftime("%m/%d/%Y %T,%L")}************* Calculating Hotness *************"
    # find the max, min, average
    unless zones.empty?
      top_array = zones.map {|e| e[:top_value]}


      count_array = zones.map do |e|
        zone_size = (e[:end_time] - e[:start_time]) / 1.day
        e[:count] / zone_size
      end
      hottest = count_array.max()
      coldest = count_array.min()
      if hottest - coldest > 0
        divider = hottest - coldest
      end
      # total = count_array.sum()
      # average = total/zones.length

      #calculate hotness based on the count of articles in the zone, comparing to average, max, min
      zones.each do |zone|
        zone_size = (zone[:end_time] - zone[:start_time]) / 1.day
        zone_average_count = zone[:count] / zone_size

        # if zone_average_count > average
        #   zone[:hotness] = (5 + (zone_average_count - average) * 5 / (hottest - average)).round
        # elsif zone_average_count < average
        #   zone[:hotness] = 5 - ((average - zone_average_count) * 5 / (average - coldest)).round
        # elsif zone_average_count == average
        #   zone[:hotness] = 5
        # end

        if divider
          zone[:hotness] = 2 + (4*(zone_average_count - coldest)/divider).round + (4*zone[:top_value]/top_array.max()).round
        else
          zone[:hotness] = 2 + (4*zone[:top_value]/top_array.max()).round
        end
      end
    end
    return zones
  end

end
