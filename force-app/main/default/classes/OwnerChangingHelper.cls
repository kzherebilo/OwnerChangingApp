/**
 * Class of helper methods, designed for the Owner Cnahging Application
 * (test assignment #1)
 * 
 * @author Konstantin Zherebilo
 * @date 10/14/2021
 * 
 */
public without sharing class OwnerChangingHelper {

    /**
     * Helper method to substitute newOwnerId for the current owner in the given
     * list of sObjects. If update fails, the database rolls back. The result of
     * update is returned.
     * @author Konstantin Zherebilo
     * @date 10/14/2021
     * @param records: List of sObjects whose owner id is to be updated
     * @param newOwnerId: User ID of the new owner
     * @return Database.SaveResult[] 
     */
    public static List<Database.SaveResult> changeOwner(
            List<sObject> records, String newOwnerId) {
        
        List<Database.SaveResult> updateResults = new List<Database.SaveResult> ();

        // Make sure the list of records is not empty; otherwise return empty
        // array of Database.SaveResult
        if (records.isEmpty()) return updateResults;

        // Iterate over the list of sObjects and override the 'OwnerId' field
        for (sObject record : records) {
            record.put('OwnerId', newOwnerId);
        }

        // Create a save point of the database
        Savepoint sp = Database.setSavepoint();
        // Update records in the database with the option allOrNone disabled
        // (partial success is allowed, but the databese is rolled back if any
        // of the records fails to update)
        updateResults = Database.update(records, false);
        // Iterate over the results of the transaction and roll back the database
        // on errors, if any
        for(Database.SaveResult result : updateResults) {
            if (!result.isSuccess()) {
                Database.rollback(sp);
                break;
            }
        }

        return updateResults;
    }
}
