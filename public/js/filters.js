
angular.module('patternFilters', []).filter('patternFilter', function() {
  return function(input) {
    name_reg = new RegExp("<<[a-zA-Z]+>>")
    regxp_reg = new RegExp(">>.+?>>>")
    words = input.split(" ")

    for(var i=0; i<words.length; i++) {
      if (words[i].substr(0,3) == "<<<") {
        name = words[i].match(name_reg)
        regxp = words[i].match(regxp_reg)
        words[i] = name
      }
    }
    return words.join(" ")
  };
});
