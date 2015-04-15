var RminerApp = angular.module('RminerApp', ['ngSanitize', 'ui.bootstrap', 'patternFilters', 'editPatternFilters']);


RminerApp.controller('ScansCtrl', function ($scope, $http, $sce) {

  $http.get("/scans/?json")
  .success(function(response) {$scope.scans = angular.fromJson(response);});

  $http.get("/variables/?json")
  .success(function(response) {$scope.variables = angular.fromJson(response);});

  $scope.regExpString = ""
  $scope.sensitivity = 1
  $scope.scanTag = ""
  $scope.messages = ""
  $scope.activeScan = -1
  $scope.activePattern = -1

  $scope.getMsgs = function(pattern_id) {
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
    $http.post("/scan/finalize/", scan)
  }

  $scope.packScan = function(scan_id, value) {
    var postObject = {"id" : scan_id, "value": value}
    $http.post("/scan/packed/", postObject)
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
          new_body = new_body.concat(" ", "<<<<<", pattern.body_split[i].type, ">>", pattern.body_split[i].word, ">>>")
        } else {
          new_body = new_body.concat(" ", "<<<<<USERDEF>>", pattern.body_split[i].word, ">>>")
        }
      } else {
        new_body = new_body.concat(" ", pattern.body_split[i].word)
      }
    }
    pattern.body = new_body
    $http.post("/patterns/".concat(pattern.id,"?json"), pattern)
  }

  $scope.removeScan = function(scan) {
    scan.removing = true
    $http.delete("/scans/".concat(scan.id))
    new_scans = []
    for (var i = 0; i<$scope.scans.length; i++) {
      if ($scope.scans[i].id != scan.id) {
        new_scans.push($scope.scans[i].id)
      }
    }
    $scope.scans = new_scans
  }



  $scope.myFilter = function(msg) {
    var scans = $scope.scans
    var regExp = new RegExp($scope.regExpString)
    var res = regExp.test(msg.body)
    var filtered = new Array()
    return res
  }

  $scope.analyze = function() {
    var filtered = []
    var regExp = new RegExp($scope.regExpString)
    for(var i = 0; i<$scope.messages.length; i++ ){
      if (regExp.test($scope.messages[i].body)) {
        filtered.push($scope.messages[i].id);
      }
    }
    var postObject = {"sensitivity" : $scope.sensitivity, "msgs" : filtered, "tag" : $scope.scanTag, "parent" : $scope.activePattern}
    $http.post("/scan/new", postObject)
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



RminerApp.controller('MessagesCtrl', function ($scope, $http) {

  $scope.messages = []
  $scope.allMessages = []
  $scope.regExpString = ""
  $scope.sensitivity = 1
  $scope.messages = ""

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

  $scope.analyze = function() {
    var filtered = []
    var regExp = new RegExp($scope.regExpString)
    for(var i = 0; i<$scope.messages.length; i++ ){
      if (regExp.test($scope.messages[i].body)) {
        filtered.push($scope.messages[i].id);
      }
    }
    var postObject = {"sensitivity" : $scope.sensitivity, "msgs" : filtered, "tag" : $scope.scanTag, "parent" : $scope.activePattern}
    $http.post("/scan/new", postObject)
    $scope.scanTag = ""
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



RminerApp.controller('PatternsCtrl', function ($scope, $http) {

  $http.get("/patterns/finalized?json")
  .success(function(response) {$scope.patterns = angular.fromJson(response);});

  $scope.savePattern = function(pattern) {
    new_body = ""
    for (var i = 0; i<pattern.body_split.length; i++) {
      new_body = new_body.concat(" ", pattern.body_split[i].word)
    }
    pattern.body = new_body
    $http.post("/patterns/".concat(pattern.id,"?json"), pattern)
  }


});