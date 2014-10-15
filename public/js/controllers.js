var RminerApp = angular.module('RminerApp', []);


RminerApp.controller('MessagesCtrl', function ($scope, $http) {
  
  $http.get("/messages/?json")
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
  
      
  $scope.final = function() {
    var number = window.location.pathname.split( '/' ).reverse()[0]
    var postObject = { "id" : number }
    $http.post("/final/", postObject)
  }
     
});