$(document).on('ready page:load', function() {

  var global_views = [];
  var global_data = [];

  // AJAX call to submit search terms and display the article results
  var newSearch = function(search_string, start_time, end_time) {
    searchFunction(search_string, start_time, end_time, false);
  }

  var subSearch = function(search_string, start_time, end_time) {
    searchFunction(search_string, start_time, end_time, true);
  }

  var searchFunction = function (search_string, start_time, end_time, is_sub_search) {
    if (start_time && end_time) {
      var url = '/articles/search?utf8=%E2%9C%93&search=' + search_string + '&start_time=' + start_time + '&end_time=' + end_time
    }
    else {
      var url = '/articles/search?utf8=%E2%9C%93&search=' + search_string;
    }
    $.ajax({
      url: url,
      type: 'GET',
      dataType: 'json',
      success: function(data) {
        // Clear the view stack and corresponding data stack, and clear any timeline navigation still present
        if (is_sub_search) {
          var htmlBackToTimeline = '<a id="back-to-timeline" href="">Back to Timeline</a>';
          $('#timeline-nav').html(htmlBackToTimeline);
        } else {
          global_views = [];
          global_data = [];
          $('#timeline-nav').empty();
        }

        // Build timeline, display it and push it onto stack along with its data
        pushTimelineView(data);

        // Render minimap
        minimap.render(data['zones']);
        updateMinimap();
      }
    });
  }

  // If there are data in the data attribute, do an automatic search
  presetData = $('#search-section').data()
  if (presetData && presetData.searchString) {
    newSearch(presetData.searchString, presetData.startTime, presetData.endTime)
  };

  // Submit search terms and send AJAX call
  $('.search-form').on('submit', function(eventObject) {
    eventObject.preventDefault();
    newSearch($('.search-form #search').val());
  });

  function pushTimelineView(data) {

    // Use Handlebars to compile our article summary templates and append the resulting html to the index page
    if (data) {

      var firstNonEmptyZoneDisplayed = false;

      // Remove currently displayed timeline from DOM so we can attach the new timeline view
      $('#timeline').remove();

      var htmlTimeline = '<div id="timeline"><ul id="zone-list"></ul></div>';
      var root = $('.content-container').html(htmlTimeline);

      // Display Keywords for entire timeline
      timeline.replaceKeywords(data['keywords'], 10, $('#top-keywords-list'), 'top-keywords');

      // Compile the template with source HTML
      var sourceVisualization = $('#template-visualization').html();
      var templateVisualization = Handlebars.compile(sourceVisualization);

      var sourceZone = $('#template-zone').html();
      var templateZone = Handlebars.compile(sourceZone);

      // Display Timeline title
      var htmlTimelineTitle = '<div id="timeline-header"><h1 class="timeline-title">Timeline</h1></div>';
      $('#timeline').prepend(htmlTimelineTitle);

      if (data.user && data.user.saved_this_timeline === false) {

        var htmlTimelineSave = '<h1 id="save-timeline-button"><a id="save-timeline" href="">*</a></h1>';
        $('#timeline-header').append(htmlTimelineSave);

        // Add event handler for saving the timeline to the user model
        $('#save-timeline').on('click', function(eventObject) {
          eventObject.preventDefault();

          var url = '/users/' + data.user.user_id + '/saved_timelines';

          $.ajax({
            url: url,
            type: 'POST',
            dataType: 'json',
            data: {
              search_string: data.search_info.search_string,
              start_time: data.search_info.start_time,
              end_time: data.search_info.end_time
            },
            success: function(data) {
              console.log(data);
              $('#save-timeline-button').html('<h1 class="timeline-saved-message">saved</h1>');
            }
          });
        });
      }

      // Loop through each zone and combine it with the templates
      for ( var i = data['zones'].length - 1; i >= 0 ; i-- ) {
        console.log(data['zones'][i]);

        var zone = data['zones'][i];
        if (zone !== null) {
          if (zone.count > 0) {
            var htmlVisualization = templateVisualization(zone);
            var size = 25 + zone.hotness * 25;
            var visualizationDiv;
            var start_date = new Date(zone.start_time);
            var end_date = new Date(zone.end_time);
            var months = [ "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" ];
            var start_month = months[start_date.getMonth()];
            var end_month = months[end_date.getMonth()];
            var dateDisplay = "";

            // Display zone summary, eg. keywords, representative article, etc.
            var htmlZone = templateZone(zone.article_list[0]);
            $('#zone-list').append(htmlZone);

            // Append first 3 keywords
            timeline.replaceKeywords(zone.keywords, 3, $('.keywords').last(), 'top-keywords-zone', .25);

            // Display number of articles
            var htmlNumberOfArticles = zone.article_list.length;
            if (zone.article_list.length === 0 || zone.article_list.length > 1) {
              htmlNumberOfArticles += ' stories';
            } else {
              htmlNumberOfArticles += ' story';
            }
            $('.number-of-articles').last().html(htmlNumberOfArticles);

            // Display zone hotness visualization (circle)
            $('.zone').last().prepend(htmlVisualization);
            visualizationDiv = $('.visualization').last();

            visualizationDiv.css('width', size + 'px');
            visualizationDiv.css('height', size + 'px');
            visualizationDiv.css('opacity', .35 + zone.hotness * .05);
            visualizationDiv.css('font-size', .75 + zone.hotness/4 + 'rem');

            // Display year
            $('.zone').last().prepend("<div class='zone-year'>" + end_date.getFullYear() + "</div>");

            // Display month range of zone, eg. JUNE - JULY
            if (start_month === end_month) {
              dateDisplay = start_month;
            } else {
              dateDisplay = start_month + " - " + end_month;
            }
            dateDisplay = dateDisplay.toUpperCase();
            $('.zone').last().prepend("<div class='zone-month'>" + dateDisplay + "</div>");

            // Display vertical zone connector line, except for the first zone
            if (firstNonEmptyZoneDisplayed) {
              $('.zone').last().prepend("<div class='zone-connector'></div>");
            }

            if (!firstNonEmptyZoneDisplayed) {
              firstNonEmptyZoneDisplayed = true;
            }
          } else {

            // If there are no articles, create an empty list item with class zone
            // This is important so that we can use the zone li index to correctly select the right right zone data
            var htmlZone = "<li class='zone'></li>";
            $('#zone-list').append(htmlZone);
          }
        }
      }

      // Push the new view and data

      global_views.push($('#timeline'));
      global_data.push(data);
    }
  }

  function clickKeyword(eventObject) {
    eventObject.preventDefault();

    subSearch(global_data[global_data.length - 1].search_info.search_string + "|" + $(eventObject.target).text());
  }

  $('#top-keywords-list').on('click', clickKeyword);
  // Click event handler to change views when a user clicks on a zone
  // If the number of articles in the zone is < 20, an articles view will be displayed
  // Otherwise, another timeline will be displayed, the data for that timeline will be via an ajax call
  $('.content-container').on('click', function(eventObject) {

    var matchedZones = $(eventObject.target).closest('.zone');

    if (matchedZones.size() > 0) {

      var clickedZone = matchedZones[0];

      var activeViewIndex = global_views.length - 1;
      var data = global_data[activeViewIndex];
      var zoneIndex = data['zones'].length - $(clickedZone).index() - 1;
      var zone = data['zones'][zoneIndex];

      if (zone.count >= 20) {

        ////
        // Branch 1 (20 or more articles) - Create and render sub timeline
        ////

        var start_date = new Date(zone.start_time);
        var end_date = new Date(zone.end_time);
        var url = '/articles/search?utf8=%E2%9C%93&search=' + data.search_info.search_string + '&start_time=' + zone.start_time + '&end_time=' + zone.end_time;
        $.ajax({
          url: url,
          type: 'GET',
          dataType: 'json',
          success: function(data) {
            // Build timeline, display it and push it onto stack along with its data
            pushTimelineView(data);

            // Render minimap
            minimap.render(data['zones']);
            updateMinimap();

            // Add a 'back to timeline' link - the most basic timeline navigation
            var htmlBackToTimeline = '<a id="back-to-timeline" href="">Back to Timeline</a>';
            $('#timeline-nav').html(htmlBackToTimeline);
          };
        });

      } else {

        ////
        // Branch 2 (less than 20 articles) - Create and render articles view
        ////

        // Remove timeline from DOM temporarily
        $('#timeline').remove();

        // Append new DOM element article-list
        var htmlArticleList = '<ul class="article-list"></ul>';
        $('.content-container').append(htmlArticleList);

        // Add a 'back to timeline' link - the most basic timeline navigation
        var htmlBackToTimeline = '<a id="back-to-timeline" href="">Back to Timeline</a>';
        $('#timeline-nav').html(htmlBackToTimeline);

        // Construct each article using the article-summary - reuse template-zone for now
        var sourceZone = $('#template-zone').html();
        var templateZone = Handlebars.compile(sourceZone);

        for (var i = 0; i < zone.count; i++) {
          var htmlArticle = templateZone(zone.article_list[i]);
          $('.article-list').append(htmlArticle);

          // Append first 3 keywords
          timeline.replaceKeywords(zone.keywords, 3, $('.keywords').last(), 'top-keywords-zone', .25);
        }

        // Push articles view onto view stack
        global_views.push($('.article-list'));
        global_data.push('');

        // Render empty mimimap
        minimap.render(null);

        // Scroll the document to the start of content
        scrollToContentContainerTop();
      }
    }
  });

  function scrollToContentContainerTop() {
      var documentHeight = $(document).height();
      var articleListHeight = $('.content-container').outerHeight();
      var headerHeight = documentHeight - articleListHeight + 60;
      $(document).scrollTop(headerHeight);
  }

  // Add event handler to go back to timeline via AJAX
  $('#timeline-nav').on('click', function(eventObject) {
    eventObject.preventDefault();

    // Remove current view
    $('.content-container').empty();

    // Pop the saved dom tree for current view
    global_views.pop();
    global_data.pop();

    // Add the previous view (now the last view in the view stack) to the live dom, displaying it
    $('.content-container').html(global_views[global_views.length - 1]);

    // Re-render the minimap to reflect the current timeline view
    minimap.render(global_data[global_data.length - 1]['zones']);
    updateMinimap();

    // Remove back link if we're back at the root timeline
    if(global_views.length === 1) {
      $('#timeline-nav').empty();
    }
  });

  $(window).scroll(function() {
    updateMinimap();
  });

  function updateMinimap() {
    var documentHeight = $(document).height();
    var windowHeight = $(window).height();
    var navHeight = $('.nav-bar').outerHeight();
    var zoneListHeight = $('#zone-list').outerHeight();
    var headerHeight = documentHeight - zoneListHeight;
    var documentY = $(window).scrollTop();
    var timelineY = documentY - headerHeight + windowHeight/2;
    var minimapY = timelineY * (500/zoneListHeight);
    var index = Math.floor(minimapY / 500 * $('.circle').size());

    if (index < 0) {
      index = 0;
    }

    var circleInFocus = $('.circle').eq(index);
    var circleWidth = circleInFocus.css('width');
    var newCircleWidth = parseInt(circleWidth) * 2;

    $('.minimap-circle-pop').removeClass('minimap-circle-pop');
    if (!circleInFocus.hasClass('minimap-circle-pop')) {
      circleInFocus.toggleClass('minimap-circle-pop');
    }
  }

  // Event handlers to detect mouseover and click events on minimap
  $('#minimap-container').on('mouseover', function(eventObject) {
    var source = eventObject.target;

    if ($(source).hasClass('circle')) {
      $('.minimap-circle-hover').removeClass('minimap-circle-hover');
      $(source).toggleClass('minimap-circle-hover');
    }
  })

  $('#minimap-container').on('mouseout', function(eventObject) {
    $('.minimap-circle-hover').removeClass('minimap-circle-hover');
    updateMinimap();
  })

  $('#minimap-container').on('click', function(eventObject) {
    var offset = $(this).offset();
    var minimapX = eventObject.pageX - offset.left;
    var minimapY = eventObject.pageY - offset.top;
    var minimapHeight = 500;
    var documentHeight = $(document).height();
    var windowHeight = $(window).height();
    var zoneListHeight = $('#zone-list').outerHeight();
    var headerHeight = documentHeight - zoneListHeight;

    var newY = minimapY/minimapHeight * zoneListHeight;// + headerHeight;

    console.log('newY ', newY);

    $(document).scrollTop(newY);
    // $(document).animate({ scrollTop:newY }, 'slow');
  })
});
