public without sharing class OwnerChangingHelper {


    public static Boolean changeOwner(List<sObject> records, String newOwnerId) {
        
        if (records.isEmpty()) { return true; }
        switch on records[0] {
            when Account r {
                for(sObject record : records) {
                    ((Account)record).OwnerId = newOwnerId;
                }
            }
            when Contact r {
                for(sObject record : records) {
                    ((Contact)record).OwnerId = newOwnerId;
                }
            }
            when else {
                return false;
            }
        }
        Savepoint sp = Database.setSavepoint();
        Database.SaveResult[] updateResults = Database.update(records, true);
        for(Database.SaveResult result : updateResults) {
            if (!result.isSuccess()) {
                Database.rollback(sp);
                return false;
            }
        }
        return true;
    }
}
