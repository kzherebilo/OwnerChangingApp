public without sharing class OwnerChangingPageController {

    // Public properties
    public String       selectedOldOwnerName    { get; set; }
    public String       selectedNewOwnerName    { get; set; }
    public String[]     selectedObjects         { get; set; }
    public String[]     objectsToUpdate         { get; set; }
    public Boolean      enableEmails            { get; set; }
    
    public String userSuggestionList      {
        get {
            String suggestions = '';
            if (this.userOptionMap.isEmpty()) this.getUsers();
            for (String userName : this.userOptionMap.values()) {
                suggestions += userName + ',';
            }
            return suggestions;
        }
    }
    public List<SelectOption> orgObjects = new List<SelectOption> ();
    public List<SelectOption> userObjects = new List<SelectOption> ();

    //
    // Private properties
    private final List<String> objectFilter = new List<String> {
        'Account',
        'Opportunity',
        'Lead',
        'Contact'
    };
    
    private Map<Id, String> userOptionMap       = new Map<Id, String> ();
    private Id          updateOwnerClassId;
    private String      eventBuffer             = '';
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
    private List<String> verifiedObjectList     {
        get {
            List<String> objectNameList = new List<string> ();
            for (SelectOption option : userObjects) {
                objectNameList.add(option.getValue());
            }
            return objectNameList;
        }
    }
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
        List<String> objectsLabels;
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        for (Schema.SObjectType objectType : globalDescribe.values()) {
            Schema.DescribeSObjectResult objectDescription
                = objectType.getDescribe();
            Map<String, Schema.SObjectField> objectFieldMap
                = objectDescription.fields.getMap();
            Boolean objectQualifies = true
                && this.objectFilter.contains(objectDescription.getName());
                //&& objectDescription.isSearchable();
                //&& objectDescription.isCreateable();
                //|| objectDescription.isCustom();
            if (!objectQualifies) continue;
            Boolean fieldQualifies = true;
            // for (Schema.SObjectField objectField : objectFieldMap.values()) {
            //     fieldQualifies = objectField.getDescribe().getName() == 'OwnerId';
            //     if (fieldQualifies) break;
            // }
            if (fieldQualifies) {
                this.orgObjects.add(new SelectOption(objectDescription.getName(),
                    objectDescription.getLabel()));
                // standardObjectNames.put(objectDescription.getLabel(), 
                //     objectDescription.getName());
            }
        }
        this.orgObjects.sort();
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
        if (this.verifiedObjectList.isEmpty()) {
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
            this.verifiedOldOwnerId, this.verifiedNewOwnerId, this.verifiedObjectList);
        reassignRecordJob.oldOwnerName = verifiedOldOwnerName;
        reassignRecordJob.newOwnerName = verifiedNewOwnerName;
        reassignRecordJob.enableEmails = enableEmails;
        // Check for LimitException is required!!!
        Database.executeBatch(reassignRecordJob);
    }


    public void updateJobState() {
        this.eventBuffer = ApexPages.currentPage().getParameters().get(
            'JSONUpdateEventList');
        this.postMessage(this.eventBuffer, 'END_OF_MSG');
    }

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
