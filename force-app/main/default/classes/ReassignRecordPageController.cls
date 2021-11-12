public without sharing class ReassignRecordPageController {

    @AuraEnabled
    public static List<User> getUsers() {
        return [SELECT Id, Name, Username FROM User];
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
            List<String> objectList, Boolean enableEmails, String notes){
        if (ReassignRecordPageHelper.isAsyncJobInProgress()) return false;
        if ((currentOwner == null) || (newOwner == null)) return false;
        if (objectList == null) return false;
        try { if (objectList.isEmpty()) return false; }
        catch (Exception e) { return false; }
        ReassignRecord reassignRecordJob = new ReassignRecord(currentOwner.Id,
            newOwner.Id, objectList);
        reassignRecordJob.oldOwnerName = currentOwner.Name;
        reassignRecordJob.newOwnerName = newOwner.Name;
        reassignRecordJob.enableEmails = enableEmails;
        reassignRecordJob.notes = notes;
        reassignRecordJob.initCustomNotifications(
            'Record_Reassignment_Notification');
        reassignRecordJob.initEmailTemplate(
            'Record_Reassignment_Email_Template');
        Database.executeBatch(reassignRecordJob);
        return true;
    }
}
