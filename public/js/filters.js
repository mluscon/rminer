
angular.module('patternFilters', []).filter('patternFilter', function() {
  return function(input) {
    name_reg = new RegExp("<<[a-zA-Z]+>>")
    words = input.split(" ")

    for(var i=0; i<words.length; i++) {
      if (words[i].substr(0,3) == "<<<") {
        name = words[i].match(name_reg)

        esc_name = name.replace(/</g, '&lt;').
                        replace(/>/g, '&gt;')

        words[i] = "<span>" + esc_name + "</span>"
      }
    }
    return words.join(" ")
  };
});

angular.module('editPatternFilters', []).filter('editPatternFilter', function() {
  return function(input) {
    name_reg = new RegExp(">>.*>>>")
    words = input.body.split(" ")

    for(var i=0; i<words.length; i++) {
      if (words[i].substr(0,3) == "<<<") {
        name = words[i].match(name_reg)

        esc_name = name.replace(/>>>/g, '').
                        replace(/>>/g, '')
        input.words[i] = esc_name
        words[i] = "<input ng-model='input.words[i]'>" + esc_name + "</input>"
      } else {
        input.words[i] = words[i]
      }
    }
    return words.join(" ")
  };
});