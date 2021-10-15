@isTest
private class OwnerChangingHelperTest {

    @isTest
    static void changeOwnerTest() {
        List<User> userList = DataFactoryTestHelper.createTestUsers();
        User oldOwner = userList[0];
        User newOwner = userList[1];
        List<Account> accountList
            = DataFactoryTestHelper.createTestAccountsAsUser(oldOwner);
        OwnerChangingHelper.changeOwner(accountList, newOwner.Id);
        AggregateResult[] groupedResults = [SELECT COUNT(Id) numberOfRecords
            FROM Account WHERE OwnerId=:newOwner.Id];
        System.assertEquals(groupedResults[0].get('numberOfRecords'),
            accountList.size());
    }
}
