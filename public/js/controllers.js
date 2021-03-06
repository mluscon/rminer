var RminerApp = angular.module('RminerApp', ['ngSanitize', 'ui.bootstrap', 'patternFilters', 'editPatternFilters']);


RminerApp.controller('ScansCtrl', function ($scope, $http, $sce, $interval, $timeout) {



  $scope.selectedAlg = "NaggapanVouk"
  $scope.regExpString = ""
  $scope.sensitivity = 1
  $scope.scanTag = ""
  $scope.messages = ""
  $scope.activeScan = -1
  $scope.activePattern = -1
  $scope.last = false
  $scope.updates = []
  $scope.scan_fail = false
  $scope.scan_ok = false
  $scope.promise = null
  $scope.inProgress = false
  $scope.algorithms = []

  $http.get("/scans/?json")
  .success(function(response) {$scope.scans = angular.fromJson(response);});

  $http.get("/variables/?json")
  .success(function(response) {$scope.variables = angular.fromJson(response);});

  $http.get("/algorithms/?json")
  .success(function(response) {$scope.algorithms = angular.fromJson(response);});

  $interval(checkUpdates, 5000);

  function checkUpdates() {
    $http.get("/scans/?json")
    .success(function(response) {

      $scope.updates = angular.fromJson(response);

      for (var i = 0; i<$scope.updates.length; i++) {
        found = false
        for (var j = 0; j<$scope.scans.length; j++) {
          if ($scope.updates[i].id == $scope.scans[j].id) {
            found = true
            break
          }
        }
        if (!found) {
          $scope.scans.push($scope.updates[i])
        }
      }
    });
  }

  $scope.getMsgs = function(pattern_id, last) {
    $scope.last = last
    $scope.activePattern = pattern_id
    $http.get("/patterns/".concat(pattern_id,"/messages?json"))
    .success(function(response) {$scope.messages = angular.fromJson(response);});
  }

  $scope.getScanMsgs = function(scan_id) {
    if ($scope.activePattern != -1 || $scope.activeScan != scan_id) {
      $scope.activePattern = -1
      $http.get("/scans/".concat(scan_id,"?json"))
      .success(function(response) {$scope.messages = angular.fromJson(response);});
    }
  }

  $scope.fixJson = function(json) {
    return angular.fromJson(json)
  }

  $scope.contains = function(words, word) {
    for (var i = 0; i<words.length; i++) {
      if (words[i][0].indexOf(word)>=0) {
        return true
      }
    }
    return false
  }

  $scope.hasChildren = function(pattern_id) {
    for (var i = 0; i<$scope.scans.length; i++ ) {
      if ($scope.scans[i].parent_id == pattern_id) {
        return true;
      }
    }
    return false;
  }

  $scope.changeActive = function(id) {
    $scope.activeScan = id
  }

  $scope.finalizeScan = function(scan) {
    for (var i = 0; i<scan.patterns.length; i++) {
      for (var j = 0; j<$scope.scans.length; j++) {
        if ($scope.scans[j].parent_id == scan.patterns[i].id) {
          $scope.finalizeScan($scope.scans[j])
        }
      }
    }
    scan.removing = true
    $http.post("/scan/finalize/", scan)
  }

  $scope.finalizePattern = function(pattern, final) {
    pattern.final = final
    $scope.savePattern
    $http.post("/patterns/".concat(pattern.id,"?json"), pattern)
  }

  $scope.savePattern = function(pattern) {
    new_body = ""
    for (var i = 0; i<pattern.body_split.length; i++) {
      if (pattern.body_split[i].variable) {
        var found = false
        for (var j = 0; j<$scope.variables.length; j++) {
          if ($scope.variables[j].regexp === pattern.body_split[i].word) {
            found = true
          }
        }
        if (found) {
          new_body = new_body.concat(" %{", pattern.body_split[i].type, ":", pattern.body_split[i].name, "}", "<<", pattern.body_split[i].word, ">>")
        } else {
          new_body = new_body.concat(" %{", "USERDEF", ":", pattern.body_split[i].name, "}", "<<", pattern.body_split[i].word, ">>")
        }
      } else {
        new_body = new_body.concat(" ", pattern.body_split[i].word)
      }
    }
    pattern.body = new_body
    $http.post("/patterns/".concat(pattern.id,"?json"), pattern)
  }

  $scope.removeScan = function(scan) {
    for (var i = 0; i<scan.patterns.length; i++) {
      for (var j = 0; j<$scope.scans.length; j++) {
        if ($scope.scans[j].parent_id == scan.patterns[i].id) {
          $scope.removeScan($scope.scans[j])
        }
      }
    }
    scan.removing = true
    $http.delete("/scans/".concat(scan.id))
  }

  $scope.myFilter = function(msg) {
    var scans = $scope.scans
    var regExp = new RegExp($scope.regExpString)
    var res = regExp.test(msg.body)
    var filtered = new Array()
    return res
  }

  function hideIcons() {
    $scope.scan_ok = false
    $scope.scan_fail = false
  }

  $scope.analyze = function() {
    $scope.inProgress = true
    $timeout.cancel($scope.promise)
    var filtered = []
    var regExp = new RegExp($scope.regExpString)
    for(var i = 0; i<$scope.messages.length; i++ ){
      if (regExp.test($scope.messages[i].body)) {
        filtered.push($scope.messages[i].id);
      }
    }
    var postObject = null
    if ($scope.last) {
      postObject = {"sensitivity" : $scope.sensitivity, "msgs" : filtered,
                    "algorithm" : $scope.selectedAlg, "parent" : ""}
    } else {
      postObject = {"sensitivity" : $scope.sensitivity, "msgs" : filtered,
                    "algorithm" : $scope.selectedAlg, "parent" : $scope.activePattern}
    }
    $http.post("/scan/new", postObject).
    success(function(data, status, headers, config) {
      $scope.scan_ok=true
      $scope.inProgress = false
      $scope.promise = $timeout(hideIcons, 4000);
    }).
    error(function(data, status, headers, config) {
      $scope.scan_fail=true
      $scope.inProgress = false
      $scope.promise = $timeout(hideIcons, 4000);
    });
    $scope.scanTag = ""
  }

  $scope.remove = function() {
    var filtered = []
    var remaining = []
    var regExp = new RegExp($scope.regExpString)
    for(var i = 0; i<$scope.messages.length; i++ ){
      if (regExp.test($scope.messages[i].body)) {
        filtered.push($scope.messages[i].id);
      } else {
        remaining.push($scope.messages[i]);
      }
    }
    $scope.messages = remaining;
    var postObject = { "msgs" : filtered }
    $http.post("/remove/", postObject)
    $scope.regExpString = ""
  }

  $scope.toTrustedHTML = function( html ){
    return $sce.trustAsHtml( html );
  }

});



RminerApp.controller('MessagesCtrl', function ($scope, $http, $timeout) {

  $scope.messages = []
  $scope.allMessages = []
  $scope.regExpString = ""
  $scope.sensitivity = 1
  $scope.messages = ""
  $scope.selectedAlg = "NaggapanVouk"
  $scope.scan_ok = false
  $scope.scan_fail = false
  $scope.promise = null
  $scope.inProgress = false
  $scope.algorithms = []

  $http.get("/algorithms/?json")
  .success(function(response) {$scope.algorithms = angular.fromJson(response);});

  $http.get("/messages/?json")
  .success(function(response) {
    $scope.messages = angular.fromJson(response);
    $scope.allMessages = $scope.messages
  });

  $scope.$watch('regExpString', function() {
    var regExp = new RegExp($scope.regExpString)
    var filtered = []
    for (var i=0; i<$scope.allMessages.length; i++){
      if (regExp.test($scope.allMessages[i].body)) {
        filtered.push($scope.allMessages[i])
      }
    }
    $scope.messages = filtered
  });

  $scope.myFilter = function(msg) {
    var regExp = new RegExp($scope.regExpString)
    var res = regExp.test(msg.body)
    var filtered = new Array()
    return res
  }

  function hideIcons() {
    $scope.scan_ok = false
    $scope.scan_fail = false
  }

  $scope.analyze = function() {
    $scope.inProgress = true
    $timeout.cancel($scope.promise)
    hideIcons()
    var filtered = []
    var regExp = new RegExp($scope.regExpString)
    for(var i = 0; i<$scope.messages.length; i++ ){
      if (regExp.test($scope.messages[i].body)) {
        filtered.push($scope.messages[i].id);
      }
    }
    var postObject = {"sensitivity" : $scope.sensitivity, "msgs" : filtered,
                      "algorithm" : $scope.selectedAlg, "parent" : $scope.activePattern}
    $http.post("/scan/new", postObject).
    success(function(data, status, headers, config) {
      $scope.scan_ok = true
      $scope.inProgress = false
      $scope.promise = $timeout(hideIcons, 4000);
    }).
    error(function(data, status, headers, config) {
      $scope.scan_fail = true
      $scope.inProgress = false
      $scope.promise = $timeout(hideIcons, 4000);
    });
    $scope.scanTag = ""

    $http.get("/info/?json")
    .success(function(response) {
    $scope.info = angular.fromJson(response);
    });
  }

  $scope.currentPage = 1
  $scope.msgsPerPage = 100
  $scope.pages = ($scope.messages.length/10)
  $scope.msgsPage = $scope.messages.slice(0, $scope.msgsPerPage)

  $scope.$watch('currentPage + messages', function() {
    $scope.pages = ($scope.messages.length/10)
    var begin = (($scope.currentPage - 1)* $scope.msgsPerPage)
    var end = begin + $scope.msgsPerPage
    $scope.msgsPage = $scope.messages.slice(begin, end)
  });
});


RminerApp.controller('PatternsCtrl', function ($scope, $http, $interval) {

  $http.get("/patterns/finalized?json")
  .success(function(response) {$scope.patterns = angular.fromJson(response);});

  function checkUpdates() {
    $http.get("/patterns/finalized?json")
    .success(function(response) {

      $scope.updates = angular.fromJson(response);

      for (var i = 0; i<$scope.updates.length; i++) {
        found = false
        for (var j = 0; j<$scope.patterns.length; j++) {
          if ($scope.updates[i].id == $scope.patterns[j].id) {
            found = true
            break
          }
        }
        if (!found) {
          $scope.patterns.push($scope.updates[i])
        }
      }
    });
  }


  $scope.savePattern = function(pattern) {
    new_body = ""
    for (var i = 0; i<pattern.body_split.length; i++) {
      if (pattern.body_split[i].variable) {
        new_body = new_body.concat(" %{", pattern.body_split[i].type, ":", pattern.body_split[i].name, "}", "<<", pattern.body_split[i].word, ">>")
      } else {
        new_body = new_body.concat(" ", pattern.body_split[i].word)
      }
    }
    pattern.body = new_body
    $http.post("/patterns/".concat(pattern.id,"?json"), pattern)
  }

  $scope.removePattern = function(pattern) {
    pattern.finalized = false
    $http.delete("/patterns/".concat(pattern.id), pattern)
  }

  $scope.fixJson = function(json) {
    return angular.fromJson(json)
  }

});

RminerApp.controller('InfoCtrl', function ($scope, $http, $interval) {

  $http.get("/info/?json")
  .success(function(response) {
    $scope.info = angular.fromJson(response);
  });

  $interval(checkUpdates, 5000);

  function checkUpdates() {
    $http.get("/info/?json")
    .success(function(response) {

      $scope.info = angular.fromJson(response);

    });
  }

});

RminerApp.controller('VariablesCtrl', function ($scope, $http) {

  $scope.newVariable = {type:"", short:"", priority:"", regexp:""}

  $http.get("/variables/?json")
  .success(function(response) {
    $scope.variables = angular.fromJson(response);
  });

  $scope.addVariable = function() {
    $scope.newVariable.priority = parseInt($scope.newVariable.priority)
    $scope.variables.push($scope.newVariable)
    $scope.newVariable = {type:"", short:"", priority:"", regexp:""}
    $scope.saveVariables()
  }

  $scope.saveVariables = function() {
    $http.post("variables/?json", $scope.variables)
  }

  $scope.removeVariable = function(variable) {
    $scope.variables.splice($scope.variables.indexOf(variable), 1)
    $scope.saveVariables()
  }
});

