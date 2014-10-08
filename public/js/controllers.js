var RminerApp = angular.module('RminerApp', []);


RminerApp.controller('MessagesCtrl', function ($scope, $http) {
  
  $http.get("/messages/?json")
  .success(function(response) {$scope.messages = angular.fromJson(response);});
  
  $scope.regExpString = ""
  $scope.sensitivity = 1
  
  $scope.filteredMsgIds = new Array()
  
  $scope.myFilter = function(msg) {
    $scope.regExp = new RegExp($scope.regExpString)
    var res = $scope.regExp.test(msg.body)
    var filtered = new Array()
    if (res) {
      filtered.push(msg.id)
    }
    $scope.filteredMsgIds = filtered
    return res
  }
  
  $scope.analyze = function() {
    var postObject = {"sensitivity" : $scope.sensitivity, "msgs" : $scope.filteredMsgIds}
    $http.post("/scan/new", postObject)    
  }
  
}); 