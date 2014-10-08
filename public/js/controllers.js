var RminerApp = angular.module('RminerApp', []);


RminerApp.controller('MessagesCtrl', function ($scope, $http) {
  
  $http.get("/messages/?json")
  .success(function(response) {$scope.messages = angular.fromJson(response);});
  
  $scope.regExpString = ""
  $scope.sensitivity = 1
    
  
  $scope.myFilter = function(msg) {
    $scope.regExp = new RegExp($scope.regExpString)
    var res = $scope.regExp.test(msg.body)
    return res
  }
  
  
}); 