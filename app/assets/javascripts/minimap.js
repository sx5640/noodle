var minimap = (function() {

  return {

    render: function(zones) {

      $('#minimap-container').empty();
      var windowHeight = $(window).height();
      var minimapHeight = 500;
      var top = (windowHeight - minimapHeight) / 2;

      $('#minimap-container').css('height', minimapHeight + 'px');
      $('#minimap-container').css('top', top);

      if (zones && zones.length > 0) {
        var displayCount = 0;
        var distance = 500 / minimap.numberOfNonEmptyZones(zones);
        var topOffset = distance / 2;

        for ( var i = zones.length - 1; i >= 0 ; i-- ) {
          var zone = zones[i];

          if (zone.count > 0) {
            var htmlCircle = '<div class="circle"></div>';
            var circle;
            var size = Math.floor(5 + zone.hotness * zone.hotness * .225);

            $('#minimap-container').append(htmlCircle);
            circle = $('.circle').last();
            circle.css('top', (displayCount * distance - size / 2) + topOffset + 'px');
            circle.css('left', (50 - size / 2) + 'px');
            circle.css('width', size + 'px');
            circle.css('height', size + 'px')
            circle.css('opacity', (zone.hotness * .75));
            displayCount++;
          }
        }
      }
    },

    numberOfNonEmptyZones: function(zones) {
      var result = 0;
      for ( var i = 0; i < zones.length; i++ ) {
        if (zones[i].count > 0) {
          result++;
        }
      }
      return result;
    }
  }

}) ();
