public without sharing class ReassignRecordPageController {


    @AuraEnabled
    public static List<User> getUsers(){
        return [SELECT Id, Name, Username FROM User];
    }
}
