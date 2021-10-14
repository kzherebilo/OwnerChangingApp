public without sharing class OwnerChangingPageController {

    public String selectedOldProfileId { get; set; }
    public String selectedOldUserId { get; set; }
    public String selectedNewProfileId { get; set; }
    public String selectedNewUserId { get; set; }
    public String oldUserNumberRecords {get; set; }
    public String newUserNumberRecords {get; set; }
    public String operationResult { get; set; }

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
        for (User usr : [SELECT Id, Name FROM User WHERE ProfileId=:selectedNewProfileId AND Id!=:selectedOldUserId]) {
            userOptions.add(new SelectOption(usr.Id, usr.Name));
        }
        return userOptions;
    }

    // public Integer getNumberOfOldUserAccounts() {
    //     if (selectedOldUserId == '') { return 0; }
    //     AggregateResult queryResult = [SELECT COUNT(Id) FROM ACCOUNT WHERE OwnerId=:selectedOldUserId];
    //     return 1;
    // }

    public void reassignOwner() {
        if (selectedOldUserId == '') { operationResult = 'Failed. No old user ID'; return;}
        if (selectedNewUserId == '') { operationResult = 'Failed. No new user ID'; return; }

        List<Account> accountsToUpdate = new List<Account> ([SELECT Id, OwnerId FROM Account WHERE OwnerId=:selectedOldUserId]);
        if (accountsToUpdate.size() == 0) { operationResult = 'Failed. No accounts to process'; return; }

        Boolean result = OwnerChangingHelper.changeOwner(accountsToUpdate, selectedNewUserId);
        if (result) {
            operationResult = 'Success';
        }
        else {
            operationResult = 'Failed';
        }
    }
}
