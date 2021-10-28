@isTest
public class DataFactoryTestHelper {

    public static Integer numberOfRecordsToCreate = 10;
    
    public static List<User> createTestUsers() {
        List<User> userList = new List<User> ();
        Profile userProfile = [SELECT Id FROM Profile WHERE Name='Standard Platform User']; 
        userList.add(new User(
            Alias = 'tusr1',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey='UTF-8',
            LastName='testUser1',
            FirstName = 'testUser2FirstName',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = userProfile.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='test-user-a@testorg.com')
        );    
        userList.add(new User(
            Alias = 'tusr2',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey='UTF-8',
            LastName ='testUser2',
            FirstName = 'testUser2FirstName',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = userProfile.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='test-user-b@testorg.com')
        );
        insert userList;
        return userList;
    }

    public static List<Account> createTestAccountsAsUser(User owner) {
        List<Account> accountList = new List<Account> ();
        for (Integer i = 0; i < numberOfRecordsToCreate; i++) {
            String accountName = 'Test Account ' + i;
            accountName = 'Test Account ' + accountName.hashCode().format();
            accountList.add(new Account(Name = accountName));
        }
        System.runAs(owner) {
            insert accountList;
        }
        return accountList;
    }

    public static List<Contact> createTestContactsAsUser(User owner) {
        List<Contact> contactList = new List<Contact> ();
        for (Integer i = 0; i < numberOfRecordsToCreate; i++) {
            String contactName = 'Test Contact ' + i;
            contactName = 'Test Contact ' + contactName.hashCode().format();
            contactList.add(new Contact(LastName = contactName));
        }
        System.runAs(owner) {
            insert contactList;
        }
        return contactList;
    }
}
