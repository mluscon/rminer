var RminerApp = angular.module('RminerApp', []);


RminerApp.controller('ScansCtrl', function ($scope, $http) {

  $http.get("/scans/?json")
  .success(function(response) {$scope.scans = angular.fromJson(response);});

  $scope.regExpString = ""
  $scope.sensitivity = 1
  $scope.scanTag = ""
  $scope.messages = ""
  $scope.activeScan = -1
  $scope.activePattern = -1

  $scope.getMsgs = function(pattern_id) {
    $scope.activePattern = pattern_id
    $http.get("/patterns/".concat(pattern_id,"?json"))
    .success(function(response) {$scope.messages = angular.fromJson(response);});
  }

  $scope.getScanMsgs = function(scan_id) {
    if ($scope.activePattern != -1 || $scope.activeScan != scan_id) {
      $scope.activePattern = -1
      $http.get("/scans/".concat(scan_id,"?json"))
      .success(function(response) {$scope.messages = angular.fromJson(response);});
    }
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

  $scope.packScan = function(scan_id, value) {
    var postObject = {"id" : scan_id, "value": value}
    $http.post("/scan/packed/", postObject)
  }

  $scope.finalizePattern = function(pattern) {
    pattern.final = true
    $http.post("/patterns/finalize/", {"id" : pattern.id})
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
    $scope.scan.Tag = ""
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

});



RminerApp.controller('MessagesCtrl', function ($scope, $http) {

  $http.get("/messages/?json")
  .success(function(response) {$scope.messages = angular.fromJson(response);});

  $scope.regExpString = ""
  $scope.sensitivity = 1
  $scope.scanTag = ""
  $scope.messages = ""
  $scope.activeScan = -1
  $scope.activePattern = -1



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
    $scope.scan.Tag = ""
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
});








RminerApp.controller('PatternsCtrl', function ($scope, $http) {

  var url = "/patterns/".concat( window.location.pathname.split( '/' ).reverse()[0].concat("?json"))
  $http.get(url)
  .success(function(response) {$scope.messages = angular.fromJson(response);});

  $scope.regExpString = ""
  $scope.sensitivity = 1
  $scope.scanTag = ""

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
    var postObject = {"sensitivity" : $scope.sensitivity, "msgs" : filtered, "tag" : $scope.scanTag}
    $http.post("/scan/new", postObject)
    $scope.scan.Tag = ""
  }

  $scope.final = function() {
    var number = window.location.pathname.split( '/' ).reverse()[0]
    var postObject = { "id" : number }
    $http.post("/final/", postObject)
  }

});