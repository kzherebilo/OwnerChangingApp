@isTest
private class ReassignRecordTest {

    @isTest
    static void asyncReassignmentTestWithStrings() {
        AggregateResult[] groupedResults = new List<AggregateResult> ();
        List<User> userList = DataFactoryTestHelper.createTestUsers();
        User oldOwner = userList[0];
        User newOwner = userList[1];
        System.debug('User for old owner created. ID: ' + oldOwner.Id);
        System.debug('User for new owner created. ID: ' + newOwner.Id);
        DataFactoryTestHelper.numberOfRecordsToCreate = 100;
        List<Account> accountList
            = DataFactoryTestHelper.createTestAccountsAsUser(oldOwner);
        System.debug('Test records of type ACCOUNT created'
            + accountList.size() + ' items');
        System.debug('Launching batch apex class to update owner...');
        Test.startTest();
        ReassignRecord reassignJob = new ReassignRecord(oldOwner.Id,
            newOwner.Id, new List<String> {'Account'});
        Id batchId = Database.executeBatch(reassignJob);
        Test.stopTest();
        groupedResults = [SELECT COUNT(Id) numberOfRecords
            FROM Account WHERE OwnerId=:newOwner.Id];
        System.assertEquals(accountList.size(), 
            groupedResults[0].get('numberOfRecords'));
        System.debug('Update is successful');
        AsyncApexJob apexJob = [SELECT Status, NumberOfErrors, JobItemsProcessed,
        TotalJobItems FROM AsyncApexJob WHERE Id = :batchId];
        System.debug('Batch apex job => STATUS: ' + apexJob.Status);
        System.debug('Batch apex job => NUMBER_OF_ERRORS: ' + apexJob.NumberOfErrors);
        System.debug('Batch apex job => BATCHES_PROCESSED: ' + apexJob.JobItemsProcessed);
        System.debug('Batch apex job => NUMBER_OF_BATCHES: ' + apexJob.TotalJobItems);
    }

}
