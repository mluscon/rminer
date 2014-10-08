var RminerApp = angular.module('RminerApp', []);


RminerApp.controller('MessagesCtrl', function ($scope, $http) {
  
  $http.get("/messages/?json")
  .success(function(response) {$scope.messages = angular.fromJson(response);});
  
  
  
}); 