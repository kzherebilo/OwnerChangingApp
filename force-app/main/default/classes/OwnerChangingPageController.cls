public without sharing class OwnerChangingPageController {

    // Public properties
    public String       selectedOldOwnerName    { get; set; }
    public String       selectedNewOwnerName    { get; set; }
    public String[]     selectedObjects         { get; set; }
    public String[]     objectsToUpdate         { get; set; }
    public String       userSuggestionList      {
        get {
            String suggestions = '';
            if (this.userOptionMap.isEmpty()) this.getUsers();
            for (String userName : this.userOptionMap.values()) {
                suggestions += userName + ',';
            }
            return suggestions;
        }
    }
    //
    // Private properties
    private Map<Id, String> userOptionMap       = new Map<Id, String> ();
    private List<SelectOption> orgObjects       = new List<SelectOption> ();
    private List<SelectOption> userObjects      = new List<SelectOption> ();
    private Id          updateOwnerClassId;
    private String      logBuffer               = '';
    private String      verifiedOldOwnerName    {
        get {
            if (this.userOptionMap.values().contains(this.selectedOldOwnerName)) {
                return this.selectedOldOwnerName;
            }
            return '';
        }
    }
    private String      verifiedNewOwnerName    {
        get {
            if (this.userOptionMap.values().contains(this.selectedNewOwnerName)) {
                return this.selectedNewOwnerName;
            }
            return ''; 
        }
    }
    private String      verifiedOldOwnerId      {
        get {
            for (Id userId : this.userOptionMap.keySet()) {
                if (this.userOptionMap.get(userId) == verifiedOldOwnerName) {
                    return (String) userId;
                }
            }
            return '';
        }
    }
    private String      verifiedNewOwnerId      {
        get {
            for (Id userId : this.userOptionMap.keySet()) {
                if (this.userOptionMap.get(userId) == verifiedNewOwnerName) {
                    return (String) userId;
                }
            }
            return '';
        }
    }

/**************************************************************************************************/
/**************************************************************************************************/

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
            List<SelectOption> objectsEmptyList = new List<SelectOption> ();
            objectsEmptyList.add(new SelectOption('', '---------- None ----------'));
            return objectsEmptyList;
        }
        List<String> objectsLabels;
        Map<String, String> standardObjectNames = new Map<String, String> ();
        // Map<String, String> customObjectNames = new Map<String, String> ();
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        for (Schema.SObjectType objectType : globalDescribe.values()) {
            Schema.DescribeSObjectResult objectDescription = objectType.getDescribe();
            if (!objectDescription.isCustom() && objectDescription.isCreateable() 
                    && objectDescription.isSearchable()) {
                standardObjectNames.put(objectDescription.getLabel(), 
                    objectDescription.getName());
            }
        }
        objectsLabels = new List<String> (standardObjectNames.keySet());
        objectsLabels.sort();
        for (String objectLabel : objectsLabels) {
            this.orgObjects.add(new SelectOption(standardObjectNames.get(
                objectLabel), objectLabel));
        }
        return this.orgObjects;
    }

    public List<SelectOption> getUserDefinedObjects() {
        if (this.userObjects.isEmpty()) {
            List<SelectOption> objectsEmptyList = new List<SelectOption> ();
            objectsEmptyList.add(new SelectOption('', '---------- None ----------'));
            return objectsEmptyList;
        }
        return this.userObjects;
    }

    public void addObjectsToList() {
        Integer objectIndex;
        if (this.selectedObjects.isEmpty()) return;
        for (String objectName : this.selectedObjects) {
            for (SelectOption objectOption : this.orgObjects) {
                if (objectOption.getValue() == objectName) {
                    this.userObjects.add(objectOption);
                    objectIndex = this.orgObjects.indexOf(objectOption);
                    break;
                }
            }
            this.orgObjects.remove(objectIndex);
        }
    }

    public void removeObjectsFromList() {
        Integer objectIndex;
        if (this.objectsToUpdate.isEmpty()) return;
        for (String objectName : this.objectsToUpdate) {
            for (SelectOption objectOption : this.userObjects) {
                if (objectOption.getValue() == objectName) {
                    this.orgObjects.add(objectOption);
                    objectIndex = this.userObjects.indexOf(objectOption);
                    break;
                }
            }
            this.userObjects.remove(objectIndex);
        }
    }

    public void updateOwner() {
        String logMessage = '';
        ApexPages.Severity logMsgSeverity = ApexPages.Severity.INFO;
        
        // Make sure the asynchronous class with same class ID is not in the
        // queue. Firstly, determine the async class name (if null) and get the
        // class ID by its name
        if (this.updateOwnerClassId == null) {
            String updateOwnerClassName = ReassignRecord.class.getName();
            this.updateOwnerClassId = [SELECT Id FROM ApexClass
                WHERE Name = :updateOwnerClassName LIMIT 1].Id;
        }
        // Secondly, query all async jobs cureently being processed and filter
        // the results by the class ID obtained eralier
        List<AsyncApexJob> apexJobs = [SELECT ApexClassId, Status FROM AsyncApexJob
            WHERE ApexClassId =: this.updateOwnerClassId
            AND Status != 'Completed' AND Status != 'Failed'];
        // If the list of active jobs is not empty, then apparently an owner 
        // update task is already launched by someone
        logMsgSeverity = ApexPages.Severity.ERROR;
        if (!apexJobs.isEmpty()) { 
            logMessage = 'Another task is being processed. Please try again later';
            ApexPages.addMessage(new ApexPages.Message(logMsgSeverity, logMessage));
            return;
        }
        // A series of trivial checks of user input
        logMsgSeverity = ApexPages.Severity.WARNING;
        if (String.isBlank(this.verifiedOldOwnerName)) {
            logMessage = '"From"-user field is required! '
                + 'Please select a user whose ownership to be revoked';
            ApexPages.addMessage(new ApexPages.Message(logMsgSeverity, logMessage));
            return;
        }
        if (String.isBlank(this.verifiedNewOwnerName)) {
            logMessage = '"To"-user field is required! '
                + 'Please select a new owner of the records';
            ApexPages.addMessage(new ApexPages.Message(logMsgSeverity, logMessage));
            return;
        }
        if (this.verifiedOldOwnerName == this.verifiedNewOwnerName) {
            logMessage = 'Current and new owner are identical! '
                + 'Reassignment is pointless! Select different users';
            ApexPages.addMessage(new ApexPages.Message(logMsgSeverity, logMessage));
            return;
        }
        if ((this.selectedObjects == null) || (this.selectedObjects.size() == 0)) {
            logMessage = 'No object type is selected! '
                + 'Please specify object types, such as Accounts or Leads; the '
                + 'owner of the records belonging to each of the selected type '
                + 'will be updated';
            ApexPages.addMessage(new ApexPages.Message(logMsgSeverity, logMessage));
            return;
        }
        logMsgSeverity = ApexPages.Severity.INFO;
        logMessage = 'Reassignment task is initiated';
        ApexPages.addMessage(new ApexPages.Message(logMsgSeverity, logMessage));

        ReassignRecord reassignRecordJob = new ReassignRecord(
            this.verifiedOldOwnerId, this.verifiedNewOwnerId, this.selectedObjects);
        reassignRecordJob.oldOwnerName = verifiedOldOwnerName;
        reassignRecordJob.newOwnerName = verifiedNewOwnerName;
        reassignRecordJob.enableEmails = false;
        // Check for LimitException is required!!!
        Database.executeBatch(reassignRecordJob);
    }


    public void updateJobState() {
        Update_Owner_Event__e updateEvent = new Update_Owner_Event__e ();
        String logMessage = '';
        ApexPages.Severity logMsgSeverity = ApexPages.Severity.CONFIRM;
        logBuffer = ApexPages.currentPage().getParameters().get('JSONUpdateEventList');
        for (String JSONEvent : logBuffer.split('END_OF_MSG')) {
            JSONParser parser = JSON.createParser(JSONEvent);
            updateEvent = (Update_Owner_Event__e) parser.readValueAs(
                Update_Owner_Event__e.class);
            if (updateEvent.jobStatus__c.contains('Completed')) {
                logMsgSeverity = ApexPages.Severity.CONFIRM;
                logMessage = updateEvent.oldOwnerName__c.toUpperCase() + ' >>> '
                    + updateEvent.newOwnerName__c.toUpperCase() + ' | '
                    + Integer.valueOf(updateEvent.recordsUpdated__c)
                    + updateEvent.objectName__c + ' records updated';
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
