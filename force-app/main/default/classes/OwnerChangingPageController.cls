public without sharing class OwnerChangingPageController {

    // Public properties
    public List<SelectOption> orgObjects = new List<SelectOption> ();
    public List<SelectOption> userObjects = new List<SelectOption> ();

    public String selectedOldOwnerName { get; set; }
    public String selectedNewOwnerName { get; set; }
    public String[] selectedObjects { get; set; }
    public String[] objectsToUpdate { get; set; }
    public Boolean enableEmails { get; set; }
    public Record_Reassignment_Task__c dummyLogRecord { get; set; }


    public String userSuggestionList {
        get {
            String suggestions = '';
            if (this.userOptionMap.isEmpty()) this.getUsers();
            for (String userName : this.userOptionMap.values()) {
                suggestions += userName + ',';
            }
            return suggestions;
        }
    }
    public String verifiedOldOwnerName {
        get {
            if (this.userOptionMap.values().contains(this.selectedOldOwnerName)) {
                return this.selectedOldOwnerName;
            }
            return '';
        }
    }
    public String verifiedNewOwnerName {
        get {
            return this.userOptionMap.get(dummyLogRecord.New_Owner__c);
        }
    }
    public String verifiedOldOwnerId {
        get {
            for (Id userId : this.userOptionMap.keySet()) {
                if (this.userOptionMap.get(userId) == verifiedOldOwnerName) {
                    return (String) userId;
                }
            }
            return '';
        }
    }
    public String verifiedNewOwnerId {
        get {
            return dummyLogRecord.New_Owner__c;
        }
    }
    public List<String> verifiedObjectList {
        get {
            List<String> objectNameList = new List<string> ();
            for (SelectOption option : userObjects) {
                objectNameList.add(option.getValue());
            }
            return objectNameList;
        }
    }

    //
    // Private properties
    private Map<Id, String> userOptionMap = new Map<Id, String> ();
    private String eventBuffer = '';
    private List<SelectOption> emptyPickList    {
        get {
            List<SelectOption> objectsEmptyList = new List<SelectOption> ();
            SelectOption emptyOption = new SelectOption('', '-- None --');
            emptyOption.setDisabled(true);
            objectsEmptyList.add(emptyOption);
            return objectsEmptyList;
        }
    }

/**************************************************************************************************/
/**************************************************************************************************/

    // Constructor
    public OwnerChangingPageController() {
        dummyLogRecord = new Record_Reassignment_Task__c();
    }

    // Methods
    public Map<Id, String> getUsers() {
        for (User usr : [SELECT Id, Name FROM User]) {
            this.userOptionMap.put(usr.Id, usr.Name);
        }
        return this.userOptionMap;
    }

    public List<SelectOption> getOrgObjects() {
        if (!this.orgObjects.isEmpty()) {
            return this.orgObjects;
        }
        if (this.orgObjects.isEmpty() && !this.userObjects.isEmpty()) {
            return emptyPickList;
        }
        this.orgObjects = ReassignRecordPageHelper.getOrgObjects();
        return this.orgObjects;
    }

    public List<SelectOption> getUserDefinedObjects() {
        if (this.userObjects.isEmpty()) return emptyPickList;
        return this.userObjects;
    }

    public void addObjectsToList() {
        List<SelectOption> tempObjectList = new List<SelectOption> ();
        if (this.selectedObjects.isEmpty()) return;
        for (SelectOption objectOption : this.orgObjects) {
            if (this.selectedObjects.contains(objectOption.getValue())) {
                this.userObjects.add(objectOption);
            }
            else {
                tempObjectList.add(objectOption);
            }
        }
        this.orgObjects.clear();
        this.orgObjects.addAll(tempObjectList);
        this.userObjects.sort();
        this.orgObjects.sort();
    }

    public void removeObjectsFromList() {
        List<SelectOption> tempObjectList = new List<SelectOption> ();
        if (this.objectsToUpdate.isEmpty()) return;
        for (SelectOption objectOption : this.userObjects) {
            if (this.objectsToUpdate.contains(objectOption.getValue())) {
                this.orgObjects.add(objectOption);
            }
            else {
                tempObjectList.add(objectOption);
            }
        }
        this.userObjects.clear();
        this.userObjects.addAll(tempObjectList);
        this.userObjects.sort();
        this.orgObjects.sort();
    }

    public void updateOwner() {
        if (!ReassignRecordPageHelper.isApexFormValid(this)) return;
        ReassignRecord reassignRecordJob = new ReassignRecord(
            this.verifiedOldOwnerId, this.verifiedNewOwnerId, this.verifiedObjectList);
        reassignRecordJob.oldOwnerName = verifiedOldOwnerName;
        reassignRecordJob.newOwnerName = verifiedNewOwnerName;
        reassignRecordJob.enableEmails = enableEmails;
        reassignRecordJob.initCustomNotifications(
            'Record_Reassignment_Notification');
        reassignRecordJob.initEmailTemplate(
            'Record_Reassignment_Email_Template');
        // Check for LimitException is required!!!
        Database.executeBatch(reassignRecordJob);
    }

    public void updateJobState() {
        this.eventBuffer = ApexPages.currentPage().getParameters().get(
            'JSONUpdateEventList');
        this.postMessage(this.eventBuffer, 'END_OF_MSG');
    }

/************************************** HELPER METHODS ********************************************/

    public void postMessage(String events, String delimiter) {
        Update_Owner_Event__e updateEvent = new Update_Owner_Event__e ();
        String logMessage = '';
        ApexPages.Severity logMsgSeverity = ApexPages.Severity.CONFIRM;
        for (String event : events.split(delimiter)) {
            JSONParser parser = JSON.createParser(event);
            updateEvent = (Update_Owner_Event__e) parser.readValueAs(
                Update_Owner_Event__e.class);
            if (updateEvent.jobStatus__c.contains('Completed')) {
                logMsgSeverity = ApexPages.Severity.CONFIRM;
                logMessage = updateEvent.oldOwnerName__c.toUpperCase() + ' >>> '
                    + updateEvent.newOwnerName__c.toUpperCase() + ' | '
                    + 'Number of ' + updateEvent.objectName__c + ' records ' 
                    + 'updated:  ' + Integer.valueOf(updateEvent.recordsUpdated__c);
                ApexPages.addMessage(new ApexPages.Message(
                    logMsgSeverity, logMessage));
            }
            else {
                logMsgSeverity = ApexPages.Severity.ERROR;
                logMessage = 'Failed to update ' 
                    + updateEvent.objectName__c + ' records. '
                    + 'ERROR CODE: ' + updateEvent.errorCode__c + ', '
                    + 'EEROR TYPE: ' + updateEvent.errorType__c + ', '
                    + 'ERROR DESCRIPTION: ' + updateEvent.errorMessage__C;
                ApexPages.addMessage(new ApexPages.Message(
                    logMsgSeverity, logMessage));
                continue;
            }
            logMsgSeverity = ApexPages.Severity.WARNING;
            if (!String.isBlank(updateEvent.errorType__c)) {
                if (updateEvent.errorType__c.contains('MAIL')) {
                    logMessage = 'Email service is temporarily unavailable. '
                        + 'ERROR CODE: ' + updateEvent.errorCode__c + ', '
                        + 'EEROR TYPE: ' + updateEvent.errorType__c + ', '
                        + 'ERROR DESCRIPTION: ' + updateEvent.errorMessage__C;
                    ApexPages.addMessage(new ApexPages.Message(
                        logMsgSeverity, logMessage));
                }
            }
        }
    }
}
