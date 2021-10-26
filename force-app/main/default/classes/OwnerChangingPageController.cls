public without sharing class OwnerChangingPageController {

    public String       selectedOldProfileId    { get; set; }
    public String       selectedOldUserId       { get; set; }
    public String       selectedNewProfileId    { get; set; }
    public String       selectedNewUserId       { get; set; }
    public String[]     selectedObjects         { get; set; }
    public String       operationResult         { get; set; }
    public String       numberOfObjectsSelected { get; set; }    
    private Id          updateOwnerClassId;
    private String      logBuffer = '';
    

    private String      selectedOldUserName  {
        get {
            for (SelectOption userOption : this.userOptionList) {
                if (userOption.getValue() == selectedOldUserId) {
                    return userOption.getLabel();
                }
            }
            return '';
        }
    }
    private String      selectedNewUserName {
        get {
            for (SelectOption userOption : this.userOptionList) {
                if (userOption.getValue() == selectedNewUserId) {
                    return userOption.getLabel();
                }
            }
            return '';
        }
    }
    private List<SelectOption> userOptionList = new List<SelectOption> ();


    public void updateNumberOfObjects() {
        if (this.selectedObjects == null) {
            numberOfObjectsSelected = '0';
        }
        else {
            numberOfObjectsSelected = selectedObjects.size().format();
        }
    }
    
    public List<SelectOption> getUserProfiles() {
        List<SelectOption> profileOptions = new List<SelectOption> ();
        profileOptions.add(new SelectOption('', '--None--'));
        for (Profile userProfile : [SELECT Id, Name FROM Profile ORDER BY Name ASC]) {
            profileOptions.add(new SelectOption(userProfile.Id, userProfile.Name));
        }
        return profileOptions;
    }

    public List<SelectOption> getUsers() {
        userOptionList.add(new SelectOption('', '--None--'));
        for (User usr : [SELECT Id, Name FROM User]) {
            userOptionList.add(new SelectOption(usr.Id, usr.Name));
        }
        return userOptionList;
    }

    public List<SelectOption> getOldUsers() {
        List<SelectOption> userOptions = new List<SelectOption> ();
        userOptions.add(new SelectOption('', '--None--'));
        for (User usr : [SELECT Id, Name FROM User WHERE ProfileId=:selectedOldProfileId]) {
            userOptions.add(new SelectOption(usr.Id, usr.Name));
        }
        return userOptions;
    }

    public List<SelectOption> getNewUsers() {
        List<SelectOption> userOptions = new List<SelectOption> ();
        userOptions.add(new SelectOption('', '--None--'));
        for (User usr : [SELECT Id, Name FROM User 
                WHERE ProfileId=:selectedNewProfileId AND Id!=:selectedOldUserId]) {
            userOptions.add(new SelectOption(usr.Id, usr.Name));
        }
        return userOptions;
    }

    public List<SelectOption> getOrgObjects() {
        List<SelectOption> orgObjects = new List<SelectOption> ();
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
            orgObjects.add(new SelectOption(standardObjectNames.get(
                objectLabel), objectLabel));
        }
        return orgObjects;
    }

    public void reassignOwner() {

        List<Database.SaveResult> resultList = new List<Database.SaveResult> ();
        Integer numberOfRecordsUpdated = 0;
        Boolean isReassignmentSuccessful = true;

        if (selectedOldUserId == '') return;
        if (selectedNewUserId == '') return;
        if (selectedObjects == null) return;
        if (selectedObjects.size() == 0) return;

        for (String objectName : selectedObjects) {
            String queryString = 
                'SELECT OwnerId FROM '
                + objectName
                + ' WHERE OwnerId=:selectedOldUserId';
            List<SObject> records = Database.query(queryString);
            resultList = OwnerChangingHelper.changeOwner(records, selectedNewUserId);
            for (Database.SaveResult result : resultList) {
                isReassignmentSuccessful = result.isSuccess();
                if (!result.isSuccess()) break;
            }
            if (!isReassignmentSuccessful) break;
            numberOfRecordsUpdated += resultList.size();
        }
        operationResult = isReassignmentSuccessful
            ? 'Success | Number Of Records Updated: ' + numberOfRecordsUpdated.format()
            : 'Failed';
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
        if (String.isBlank(this.selectedOldUserId)) {
            logMessage = '"From"-user field is required! '
                + 'Please select a user whose ownership to be revoked';
            ApexPages.addMessage(new ApexPages.Message(logMsgSeverity, logMessage));
            return;
        }
        if (String.isBlank(this.selectedNewUserId)) {
            logMessage = '"To"-user field is required! '
                + 'Please select a new owner of the records';
            ApexPages.addMessage(new ApexPages.Message(logMsgSeverity, logMessage));
            return;
        }
        if (this.selectedOldUserId == this.selectedNewUserId) {
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
            this.selectedOldUserId, this.selectedNewUserId, this.selectedObjects);
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
            if (updateEvent.jobStatus__c == 'Completed') {
                logMsgSeverity = ApexPages.Severity.CONFIRM;
                logMessage = selectedOldUserName.toUpperCase() + ' >>> ' 
                    + selectedNewUserName.toUpperCase() + ' | '
                    + updateEvent.objectName__c + ' records updated: '
                    + Integer.valueOf(updateEvent.recordsUpdated__c) + ' records in total';
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
