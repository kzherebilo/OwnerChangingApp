public without sharing class ReassignRecordPageController {

    @AuraEnabled
    public static List<User> getUsers() {
        return [SELECT Name, Username FROM User];
    }

    @AuraEnabled
    public static List<String> getObjects() {
        List<String> objectOptions = new List<String> ();
        String delimiter = ReassignRecordPageHelper.STRING_DELIMITER;
        objectOptions.add(delimiter);
        for (SelectOption objectOption : ReassignRecordPageHelper.getOrgObjects()) {
            objectOptions.add(objectOption.getLabel() + delimiter
                + objectOption.getValue());
        }
        return objectOptions;
    }

    @AuraEnabled
    public static Boolean updateRecords(User currentOwner, User newOwner,
            List<String> objectList, Boolean enableEmails){
        if (ReassignRecordPageHelper.isAsyncJobInProgress()) return false;
        ReassignRecord reassignRecordJob = new ReassignRecord(currentOwner.Id,
            newOwner.Id, objectList);
        reassignRecordJob.oldOwnerName = currentOwner.Name;
        reassignRecordJob.newOwnerName = newOwner.Name;
        reassignRecordJob.enableEmails = enableEmails;
        // Check for LimitException is required!!!
        Database.executeBatch(reassignRecordJob);
        return true;
    }
}
