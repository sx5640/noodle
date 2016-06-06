var timeline = (function() {

  return {

    // Takes an array 'keywordsArray' of object type { keyword: string, relevance: float }
    // and appends the first 'numKeywords' keywords to the jQuery object 'jQuerySelector', which should select
    // an existing DOM element in the active document,
    // and styles each appended keyword's fontWeight based on its relevance value
    replaceKeywords: function(keywordsArray, numKeywords, jQuerySelector, className, relevanceScaleFactor) {
      relevanceScaleFactor = relevanceScaleFactor || 1.0;

      if (keywordsArray !== null) {

        var htmlKeyword;
        var relevance;
        var fontWeight;
        var keywordMax;

        // First, empty the parent element since we're doing a replace
        jQuerySelector.empty();

        // Calculate the number of keywords to display
        keywordMax = keywordsArray.length < numKeywords ? keywordsArray.length : numKeywords;

        if (keywordMax > 0) {
          // Loop through each keyword, attach it to the parent object specified by jQuerySelector,
          // and style it's fontWeight css attribute according to the keyword's relevance.
          for (var i = 0; i < keywordMax; i++) {
            htmlKeyword = "<li><a href='/' class='" + className + "'>" + keywordsArray[i].keyword + "</a></li>";
            relevance = keywordsArray[i].relevance;
            fontWeight = '100';
            // if (relevance > 10.0 * relevanceScaleFactor) {
            //   fontWeight = '500';
            // } else
            if (relevance > 3.0 * relevanceScaleFactor) {
              fontWeight = '400';
            } else if (relevance > 2.0 * relevanceScaleFactor) {
              fontWeight = '300';
            } else if (relevance > 1.0 * relevanceScaleFactor) {
              fontWeight = '200';
            }
            var appendObject = $(htmlKeyword);
            appendObject.find('a').css('font-weight', fontWeight);
            jQuerySelector.append(appendObject);
          }
        } else {
          htmlKeyword = "<li><a href='/' class='" + className + "'>No Keywords</a></li>";
          appendObject = $(htmlKeyword);
          appendObject.find('a').css('font-weight', '400');
          jQuerySelector.append(appendObject);
        }

        return true;
      } else {
        return false;
      }
    }
  }

}) ();
