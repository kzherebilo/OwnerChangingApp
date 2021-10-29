@IsTest
private class OwnerChangingPageControllerTest {

    @isTest
    static void reassignOwnerSingleObjectTest() {
        AggregateResult[] groupedResults = new List<AggregateResult> ();
        OwnerChangingPageController pageController = new OwnerChangingPageController();
        pageController.selectedObjects = new List<String>();
        pageController.objectsToUpdate = new List<String>();
        List<User> userList = DataFactoryTestHelper.createTestUsers();
        userList = [SELECT Id, Name FROM User WHERE Id =:userList[0].Id OR Id=:userList[1].Id];
        List<Account> recordList= DataFactoryTestHelper.createTestAccountsAsUser(userList[0]);
        
        pageController.getUsers();
        System.assert(pageController.userSuggestionList.contains(userList[0].Name));
        System.assert(pageController.userSuggestionList.contains(userList[1].Name));
        System.debug('Suggestions list is filled out correctly');
        pageController.selectedOldOwnerName = userList[0].Name;
        pageController.selectedNewOwnerName = userList[1].Name;
        
        pageController.getOrgObjects();
        SelectOption objectOption = pageController.orgObjects[0];
        pageController.selectedObjects.add(objectOption.getValue());
        pageController.addObjectsToList();
        System.assert(pageController.userObjects.contains(objectOption));
        System.debug('List of objects to process has been updated with ' 
            + objectOption.getValue() + ' object');
        pageController.objectsToUpdate.add(objectOption.getValue());
        pageController.removeObjectsFromList();
        System.assertEquals(1, pageController.getUserDefinedObjects().size());
        System.assertNotEquals(pageController.userObjects, pageController.getUserDefinedObjects());
        System.debug(pageController.getUserDefinedObjects()[0].getLabel());
        
        pageController.selectedObjects.clear();
        pageController.selectedObjects.add('Account');
        pageController.addObjectsToList();
        System.assert(pageController.userObjects.contains(
            new SelectOption('Account', 'Account')));
        System.debug('List of objects to process has been updated: Accounts added');

        pageController.enableEmails = true;

        Test.startTest();
        pageController.updateOwner();
        Test.stopTest();
        
        groupedResults = [SELECT COUNT(Id) numberOfRecords
            FROM Account WHERE OwnerId=:userList[1].Id];
        System.assertEquals(recordList.size(), 
            groupedResults[0].get('numberOfRecords'));
        System.debug('Update is successful');
        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.debug(messages.size());
        System.debug(messages[0].getSummary());

    }

    @isTest
    static void postMessageTest() {
        String eventBuffer = '';
        String eventMsgDelimiter = 'END_OF_MSG';
        System.JSONGenerator JSONGen = JSON.createGenerator(true);
        OwnerChangingPageController pageController = new OwnerChangingPageController();
        Update_Owner_Event__e updateEvent = new Update_Owner_Event__e ();
        updateEvent.jobStatus__c = 'Completed';
        updateEvent.jobId__c = '';
        updateEvent.errorCode__c = '';
        updateEvent.errorMessage__c = '';
        updateEvent.errorType__c = 'MAIL';
        updateEvent.recordsProcessed__c = 3;
        updateEvent.recordsUpdated__c = 3;
        updateEvent.newOwnerName__c = 'user 2';
        updateEvent.oldOwnerName__c = 'user 1';
        updateEvent.objectName__c = 'Account';
        JSONGen.writeObject(updateEvent);
        eventBuffer += JSONGen.getAsString() + eventMsgDelimiter;
        JSONGen = JSON.createGenerator(true);
        updateEvent.jobStatus__c = 'Failed';
        updateEvent.objectName__c = 'Contact';
        JSONGen.writeObject(updateEvent);
        eventBuffer += JSONGen.getAsString() + eventMsgDelimiter;
        System.debug('Generated JSON event: ' + eventBuffer);
        pageController.postMessage(eventBuffer, eventMsgDelimiter);
        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertEquals(3, messages.size());
        System.debug(messages.size() + 'has been poseted');
        System.assertEquals(messages[0].getSeverity(), ApexPages.Severity.CONFIRM);
        System.debug('Message severity level: ' + messages[0].getSeverity());
        System.debug('Message summary: ' + messages[0].getSummary());

        System.assertEquals(messages[1].getSeverity(), ApexPages.Severity.WARNING);
        System.debug('Message severity level: ' + messages[1].getSeverity());
        System.debug('Message summary: ' + messages[1].getSummary());

        System.assertEquals(messages[2].getSeverity(), ApexPages.Severity.ERROR);
        System.debug('Message severity level: ' + messages[2].getSeverity());
        System.debug('Message summary: ' + messages[2].getSummary());

    }

    // @isTest
    // static void reassignOwnerMultipleObjectTest() {
    //     OwnerChangingPageController pageController = new OwnerChangingPageController();
    //     pageController.selectedObjects = new List<String>();
    //     List<User> userList = DataFactoryTestHelper.createTestUsers();
    //     List<Account> accountList = DataFactoryTestHelper.createTestAccountsAsUser(userList[0]);
    //     List<Contact> contactList = DataFactoryTestHelper.createTestContactsAsUser(userList[0]);
    //     pageController.selectedOldUserId = (String) userList[0].Id;
    //     pageController.selectedNewUserId = (String) userList[1].Id;
    //     pageController.selectedObjects.add(
    //         accountList[0].Id.getSobjectType().getDescribe().getName());
    //     pageController.selectedObjects.add(
    //         contactList[0].Id.getSobjectType().getDescribe().getName());
    //     pageController.reassignOwner();
    //     Integer numberOfRecordsUpdated = accountList.size() + contactList.size();
    //     String operationResult = 'Success | Number Of Records Updated: '
    //         + numberOfRecordsUpdated;
    //     System.assertEquals(operationResult, pageController.operationResult);
    // }
}

