
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

