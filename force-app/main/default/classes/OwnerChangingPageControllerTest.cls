@IsTest
private class OwnerChangingPageControllerTest {

    // @isTest
    // static void getUserProfilesTest() {
    //     OwnerChangingPageController pageController = new OwnerChangingPageController();
    //     List<SelectOption> profileList = pageController.getUserProfiles();
    //     System.assert(profileList.size() > 0);
    // }

    // @isTest
    // static void getOldUsersTest() {
    //     OwnerChangingPageController pageController = new OwnerChangingPageController();
    //     List<User> userList = DataFactoryTestHelper.createTestUsers();
    //     System.assert(userList.size() > 0, 'Failed to obtain a list of test users');
    //     pageController.selectedOldProfileId = userList[0].ProfileId;
    //     List<SelectOption> oldUserList = pageController.getOldUsers();
    //     for (SelectOption userOption : oldUserList) {
    //         if (userOption.getValue() == (String) userList[0].Id) {
    //             System.assert(true);
    //             return;
    //         }
    //     }
    //     System.assert(false);
    // }

    // @isTest
    // static void getNewUsersTest() {
    //     Boolean isTestUserInPicklist = false;
    //     Boolean isOldUserInPicklist = false;
    //     OwnerChangingPageController pageController = new OwnerChangingPageController();
    //     List<User> userList = DataFactoryTestHelper.createTestUsers();
    //     pageController.selectedOldUserId = userList[0].Id;
    //     pageController.selectedNewProfileId = userList[1].ProfileId;
    //     List<SelectOption> newUserList = pageController.getNewUsers();
    //     for (SelectOption userOption : newUserList) {
    //         if (!isTestUserInPicklist) {
    //             isTestUserInPicklist = (userOption.getValue() == (String) userList[1].Id);
    //         }
    //         if (!isOldUserInPicklist) {
    //             isOldUserInPicklist = (userOption.getValue() == (String) userList[0].Id);
    //         }
    //     }
    //     System.assert(isTestUserInPicklist && !isOldUserInPicklist);
    // }

    // @isTest
    // static void getOrgObjects() {
    //     OwnerChangingPageController pageController = new OwnerChangingPageController();
    //     List<SelectOption> objectList = pageController.getOrgObjects();
    //     System.assert(objectList.size() > 0);
    // }

    // @isTest
    // static void reassignOwnerSingleObjectTest() {
    //     OwnerChangingPageController pageController = new OwnerChangingPageController();
    //     pageController.selectedObjects = new List<String>();
    //     List<User> userList = DataFactoryTestHelper.createTestUsers();
    //     List<Account> recordList= DataFactoryTestHelper.createTestAccountsAsUser(userList[0]);
    //     pageController.selectedOldUserId = (String) userList[0].Id;
    //     pageController.selectedNewUserId = (String) userList[1].Id;
    //     pageController.selectedObjects.add(
    //         recordList[0].Id.getSobjectType().getDescribe().getName());
    //     pageController.reassignOwner();
    //     String operationResult = 'Success | Number Of Records Updated: '
    //         + recordList.size();
    //     System.assertEquals(operationResult, pageController.operationResult);
    // }

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

