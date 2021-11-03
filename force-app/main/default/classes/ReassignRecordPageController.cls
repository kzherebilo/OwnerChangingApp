public without sharing class ReassignRecordPageController {

    @AuraEnabled
    public static List<User> getUsers(){
        return [SELECT Name, Username FROM User];
    }

    @AuraEnabled
    public static List<String> getObjects(){
        List<String> objectOptions = new List<String> ();
        objectOptions.add(ReassignRecordPageHelper.STRING_DELIMITER);
        objectOptions.add('Account;Account');
        objectOptions.add('Case;Case');
        return objectOptions;
    }
}
