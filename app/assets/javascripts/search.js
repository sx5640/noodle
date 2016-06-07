$(document).on('ready page:load', function() {

  //
  // View stack and corresponding data stack that describes multiple levels of timelines
  //
  var global_views = [];
  var global_data  = [];

  //
  // Initialize Three.js
  //
  visualization.init();

  //
  // Hide visualization
  //
  hideAllContent();

  //
  // 3D visualization selection state variables
  //
  var isSelecting = false;
  var selectionX; // x offset of initial mouse click that creates selection

  //
  // Get saved timeline, populated by the user profile
  //
  var savedTimeline = $('#search-section').data();

  //
  // Starting point 1 - handle event: search submit
  //
  $('.search-form').on('submit', function(eventObject) {
    eventObject.preventDefault();
    newSearch( $('.search-form #search').val() );
  });

  //
  // Starting point 2 - handle returning to this page via user profile page by displaying the timeline described by
  // the search-section's data attribute, if present
  //
  if (savedTimeline && savedTimeline.searchString) {
    newSearch(savedTimeline.searchString, savedTimeline.startTime, savedTimeline.endTime);
  }

  // Perform a search via AJAX request
  function newSearch(search_string, start_time, end_time) {
    $('#search').val(search_string);
    searchFunction(search_string, start_time, end_time, false);
  };

  // Perform a subsearch via AJAX request
  function subSearch(search_string, start_time, end_time) {
    $('#search').val(search_string);
    searchFunction(search_string, start_time, end_time, true);
  };

  function searchFunction(search_string, start_time, end_time, is_sub_search) {
    if (start_time && end_time) {
      var url = '/articles/search?utf8=%E2%9C%93&search=' + search_string + '&start_time=' + start_time + '&end_time=' + end_time;
    }
    else {
      var url = '/articles/search?utf8=%E2%9C%93&search=' + search_string;
    }

    // Before making search AJAX call, hide all content and display activity indicator
    hideAllContent();
    showSearchActivityIndicator();
    visualization.pause(); // pause visualization so that it doesn't affect css animation performance

    // Shrink logo
    if (!$('#logo').hasClass('logo-search')) {
      $('#logo').toggleClass('logo-search');
    }

    $.ajax({
      url: url,
      type: 'GET',
      dataType: 'json',
      success: function(data) {

        // Detect if search returned 0 results, and throw a message.
        if (!data['article_count']) {
          // Hide search activity indicator and display an error message
          hideSearchActivityIndicator();
          showNoSearchResults();
          return;
        }

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
        displayTimelineView(data);

        // Unhide all the content
        hideSearchActivityIndicator();
        visualization.unpause();
        showAllContent();

        // Render 3D visualization
        visualization.render(data['article_count'], data['search_info'], data['zones']);

        // Render minimap
        minimap.render(data['zones']);
        updateMinimap();
      }
    });
  }

  //
  // Helper function: hide all content
  //
  function hideAllContent() {
    $('#keywords-container').hide();
    $('#visualization-container').hide();
    $('#timeline-nav').hide();
    $('#down-arrow').hide();
    $('#content-container').hide();
    $('#minimap-container').hide();
  }

  //
  // Helper function: show all content
  //
  function showAllContent() {
    $('#keywords-container').show();
    $('#visualization-container').show();
    $('#timeline-nav').show();
    $('#down-arrow').show();
    $('#content-container').show();
    $('#minimap-container').show();
  }

  //
  // Helper function: show search activity indicator
  //
  function showSearchActivityIndicator() {
    var htmlActivityIndicator = '<div id="search-indicator-circle"></div>';
    $('#search-indicator-container').html(htmlActivityIndicator);
    $('#search-indicator-circle').addClass('pulse');
  }

  //
  // Helper function: show search activity indicator
  //
  function hideSearchActivityIndicator() {
    $('#search-indicator-container').empty();
  }

  //
  // Helper function: show 'no search results' message
  //
  function showNoSearchResults() {
    var htmlNoSearchResults = '<div id="search-results">No Search Results</div>';
    $('#search-indicator-container').html(htmlNoSearchResults);
  }

  //
  // Handle event: click on keyword
  //
  // Trigger an AJAX call to do a subsearch
  //
  $('#top-keywords-list').on('click', clickKeyword);

  function clickKeyword(eventObject) {
    eventObject.preventDefault();

    var search_string = global_data[global_data.length - 1].search_info.search_string + "|" + $(eventObject.target).text();
    search_string = search_string.toLowerCase();
    subSearch(search_string);
  }

  //
  // Handle event: click on zone
  //
  // Trigger an AJAX call to get another timeline, or display articles list (< 20 articles in zone)
  //
  $('#content-container').on('click', function(eventObject) {

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

        subSearch(data.search_info.search_string, zone.start_time, zone.end_time);

      } else {

        ////
        // Branch 2 (less than 20 articles) - Create and render articles view
        ////

        // Remove timeline from DOM temporarily
        $('#timeline').remove();

        // Append new DOM element article-list
        var htmlArticleList = '<ul class="article-list"></ul>';
        $('#content-container').append(htmlArticleList);

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
        // var documentHeight = $(document).height();
        // var articleListHeight = $('#content-container').outerHeight();
        // var headerHeight = documentHeight - articleListHeight + 60;

        // Hide visualization in articles view
        $('#visualization-container').hide();

        var navHeight = 60;
        var searchHeight = $('#search-section').outerHeight();
        var keywordsHeight = $('#keywords-container').outerHeight();
        var headerHeight = navHeight + searchHeight + keywordsHeight;
        $(document).scrollTop(headerHeight);
      }
    }
  });

  //
  // Handle event: click to go back up a level
  //
  $('#timeline-nav').on('click', function(eventObject) {
    eventObject.preventDefault();

    var data;

    // Remove current view
    $('#content-container').empty();

    // Pop the saved dom tree for current view
    global_views.pop();
    global_data.pop();
    data = global_data[global_data.length - 1];

    // Add the previous view (now the last view in the view stack) to the live dom, displaying it
    $('#content-container').html(global_views[global_views.length - 1]);

    // Re-render keywords for entire timeline
    timeline.replaceKeywords(data['keywords'], 10, $('#top-keywords-list'), 'top-keywords');

    // Make sure to show visualization again in case we're coming back up from an articles view where it has been hidden
    $('#visualization-container').show();

    // Re-render 3D visualization to reflect the current timeline view
    visualization.render(data['article_count'], data['search_info'], data['zones']);

    // Re-render the minimap to reflect the current timeline view
    minimap.render(global_data[global_data.length - 1]['zones']);
    updateMinimap();

    // Remove back link if we're back at the root timeline
    if(global_views.length === 1) {
      $('#timeline-nav').empty();
    }

    // Set the document back to the top if going back from articles view
    $(document).scrollTop(0);
  });

  //
  // Handle event: document scroll
  //
  // Update the minimap to reflect latest position
  //
  $(window).scroll(function() {
    updateMinimap();
  });

  //
  // Handle event: mouse over on minimap
  //
  $('#minimap-container').on('mouseover', function(eventObject) {
    var source = eventObject.target;

    if ($(source).hasClass('circle')) {
      $('.minimap-circle-hover').removeClass('minimap-circle-hover');
      $(source).toggleClass('minimap-circle-hover');
    }
  });

  //
  // Handle event: mouse out on minimap
  //
  $('#minimap-container').on('mouseout', function(eventObject) {
    $('.minimap-circle-hover').removeClass('minimap-circle-hover');
    updateMinimap();
  });

  //
  // Handle event: click on minimap
  //
  $('#minimap-container').on('click', function(eventObject) {
    var offset = $(this).offset();
    var minimapY = eventObject.pageY - offset.top;
    var minimapHeight = 500;
    var zoneListHeight = $('#zone-list').outerHeight();
    var newY = minimapY/minimapHeight * zoneListHeight;

    $(document).scrollTop(newY);
  });

  //
  // Handle event: mouse over on minimap
  //
  $('#minimap-container').on('mouseover', function(eventObject) {
    var source = eventObject.target;

    if ($(source).hasClass('circle')) {
      $('.minimap-circle-hover').removeClass('minimap-circle-hover');
      $(source).toggleClass('minimap-circle-hover');
    }
  });

  //
  // Handle event: click on 3D visualization
  //
  $('#visualization-container').on('click', function(eventObject) {
    var currentX = (eventObject.pageX - $(this).offset().left);
    var data = global_data[global_data.length - 1];
    var articleCountArray = data['article_count'];
    var articleCountArraySize = articleCountArray.length;
    var pixelsPerArticleCount = 2.672672672672672;
    var widthOfGraph = articleCountArraySize * pixelsPerArticleCount;
    var xOffset;
    var x1, x2;
    var adjustedX1, adjustedX2;
    var x1Index, x2Index;
    var searchString = data.search_info.search_string;
    var startTime;
    var endTime;

    if (!isSelecting) {
      selectionX = currentX;
      var htmlSelection = '<div id="selection"></div>';
      $('#visualization-container').prepend(htmlSelection);
      $('#selection').css('left', selectionX + 'px');
      isSelecting = true;
    } else {

      // Extract data for search, cancel selection state, and run new search
      x1 = selectionX;
      x2 = currentX;
      if (x2 < x1) {
        var tmp = x1;
        x1 = x2;
        x2 = tmp;
      }
      cancelSelectionOnVisualization();

      console.log('selection: x1=' + x1 + ', x2=' + x2);
      var canvasWidth = $('#threejs > canvas').outerWidth(true);
      console.log('canvasWidth: ', canvasWidth);

      xOffset = (canvasWidth - widthOfGraph) / 2;
      adjustedX1 = x1 - xOffset;
      adjustedX2 = x2 - xOffset;
      x1Index = convertToArrayIndex(adjustedX1 / pixelsPerArticleCount, articleCountArraySize);
      x2Index = convertToArrayIndex(adjustedX2 / pixelsPerArticleCount, articleCountArraySize);

      console.log('adjustedX1=' + adjustedX1 + ', adjustedX2=' + adjustedX2);
      console.log('x1Index=' + x1Index + ', x2Index=' + x2Index);

      // New search
      startTime = articleCountArray[x1Index].start_time;
      endTime = articleCountArray[x2Index].end_time;
      console.log('search_string: ' + searchString + ', start_time: ' + startTime + ', end_time: ' + endTime);
      subSearch(searchString, startTime, endTime);
    }
  });

  //
  // Helper function: converts first argument to array index within 0 and the second argument
  //
  function convertToArrayIndex(decimalNumberToConvert, arraySize) {
    var result = Math.floor(decimalNumberToConvert);
    if (result < 0) {
      result = 0;
    } else if (result > (arraySize - 1)) {
      result = arraySize - 1;
    }
    return result;
  }

  //
  // Handle event: mouse move on 3D visualization
  //
  $('#visualization-container').on('mousemove', function(eventObject) {
    if (isSelecting) {
      var currentX = (eventObject.pageX - $(this).offset().left);
      if (currentX >= selectionX) {
        setSelectionBounds(selectionX, currentX);
      } else {
        setSelectionBounds(currentX, selectionX);
      }
    }
  });

  //
  // Helper function: sets selection div based on left and right x coords. x2 must be greater than or equal to x1.
  //
  function setSelectionBounds(x1, x2) {
      $('#selection').css('left', x1 + 'px');
      var width = x2 - x1;
      if (width === 0) {
        width = 1;
      }
      $('#selection').css('width', width + 'px');
  }

  //
  // Handle event: mouse leave on 3D visualization cancels selection state
  //
  $('#visualization-container').on('mouseleave', function(eventObject) {
    if (isSelecting) {
      cancelSelectionOnVisualization();
    }
  });

  //
  // Handle event: escape key on 3D visualization cancels selection state
  //
  $(document).on('keydown', function(eventObject) {
    if (eventObject.keyCode === 27) {
      if (isSelecting) {
        cancelSelectionOnVisualization();
      }
    }
  });

  //
  // Helper function: cancels selection state by removing selection div and resetting isSelecting to false
  //
  function cancelSelectionOnVisualization() {
    $('#selection').remove();
    isSelecting = false;
  }

  //
  // View: display timeline described by the data object
  //
  function displayTimelineView(data) {

    // Use Handlebars to compile our article summary templates and append the resulting html to the index page
    if (data) {

      var firstNonEmptyZoneDisplayed = false;

      // Remove currently displayed timeline from DOM so we can attach the new timeline view
      $('#timeline').remove();

      var htmlTimeline = '<div id="timeline"><ul id="zone-list"></ul></div>';
      var root = $('#content-container').html(htmlTimeline);

      // Display Keywords for entire timeline
      timeline.replaceKeywords(data['keywords'], 10, $('#top-keywords-list'), 'top-keywords');

      // Compile the template with source HTML
      var sourceVisualization = $('#template-visualization').html();
      var templateVisualization = Handlebars.compile(sourceVisualization);

      var sourceZone = $('#template-zone').html();
      var templateZone = Handlebars.compile(sourceZone);

      // Display Timeline title
      var htmlTimelineTitle = '<div id="timeline-header"><h1 class="timeline-title">Big Moments</h1></div>';
      $('#timeline').prepend(htmlTimelineTitle);

      if (data.user && data.user.saved_this_timeline === false) {

        var htmlTimelineSave = '<div id="save-timeline-button"><a id="save-timeline" href="">Save Timeline</a></div>';
        // var htmlTimelineSave = '<div id="save-timeline-button"><button type="button" id="save-timeline">Save Timeline</button></div>';
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
              $('#save-timeline').html('Saved!');
            }
          });
        });
      }

      // Loop through each zone and combine it with the templates
      for ( var i = data['zones'].length - 1; i >= 0 ; i-- ) {

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

  //
  // View: udpate the minimap to reflect the latest scroll position
  //
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
});
