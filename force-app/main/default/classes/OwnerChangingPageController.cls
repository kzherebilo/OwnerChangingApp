public without sharing class OwnerChangingPageController {

    public String   selectedOldProfileId    { get; set; }
    public String   selectedOldUserId       { get; set; }
    public String   selectedNewProfileId    { get; set; }
    public String   selectedNewUserId       { get; set; }
    public String[] selectedObjects         { get; set; }
    public String   operationResult         { get; set; }


    public List<SelectOption> getUserProfiles() {
        List<SelectOption> profileOptions = new List<SelectOption> ();
        profileOptions.add(new SelectOption('', '--None--'));
        for (Profile userProfile : [SELECT Id, Name FROM Profile ORDER BY Name ASC]) {
            profileOptions.add(new SelectOption(userProfile.Id, userProfile.Name));
        }
        return profileOptions;
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
            orgObjects.add(new SelectOption(standardObjectNames.get(objectLabel), objectLabel));
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
}
