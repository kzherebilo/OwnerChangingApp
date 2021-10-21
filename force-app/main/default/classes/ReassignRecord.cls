public without sharing class ReassignRecord implements
        Database.Batchable<SObject>, Database.Stateful {
    
    private class LogRecord {
        public String       id                  = '';
        public String       status              = '';
        public String       objectName          = '';
        public Integer      recordsProcessed    = 0;
        public Integer      recordsUpdated      = 0;
        public Integer      recordsFailed       = 0;
        public Integer      batchJobItems       = 0;
        public Integer      numberOfErrors      = 0;
        public String       errorType           = '';
        public String       errorCode           = '';
        public String       errorMessage        = '';
    }

    private String                      oldOwnerId;
    private String                      newOwnerId;
    private List<String>                objectNameList;
    private Integer                     numberOfRecordsUpdated = 0;
    private Integer                     numberOfRecordsProcessed = 0;
    private List<LogRecord>             log = new List<LogRecord> ();
    public  List<String>                emailAddressList = new List<String> (); 

    public ReassignRecord(String oldOwnerId, String newOwnerId,
            List<String> objectNameList) {
        this.oldOwnerId = oldOwnerId;
        this.newOwnerId = newOwnerId;
        this.objectNameList = objectNameList;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {      
        String oldOwnerId = this.oldOwnerId;
        String query = 'SELECT OwnerId FROM ' + this.objectNameList[0]
            + ' WHERE OwnerId=:oldOwnerId';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<sObject> records) {
        for (sObject record : records) {
            record.put('OwnerId', this.newOwnerId);
        }
        List<Database.SaveResult> results = Database.update(records, false);
        for (Database.SaveResult result : results) {
            this.numberOfRecordsProcessed ++;
            if (result.isSuccess()) {
                this.numberOfRecordsUpdated++;
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        AsyncApexJob apexJob = [SELECT Id, Status, NumberOfErrors,
            JobItemsProcessed, TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob WHERE Id =
            :context.getJobId()];
        LogRecord logRec = new LogRecord();
        logRec.id = context.getJobId();
        logRec.status = apexJob.Status;
        logRec.objectName = objectNameList[0];
        logRec.recordsProcessed = this.numberOfRecordsProcessed;
        logRec.recordsUpdated = this.numberOfRecordsUpdated;
        logRec.recordsFailed = logRec.recordsProcessed - logRec.recordsUpdated;
        logRec.batchJobItems = apexJob.TotalJobItems;
        logRec.numberOfErrors = apexJob.NumberOfErrors;
        log.add(logRec);
        this.numberOfRecordsProcessed = 0;
        this.numberOfRecordsUpdated = 0;
        objectNameList.remove(0);
        if (objectNameList.size() > 0) {
            Database.executeBatch(this);
        }
        else {
            emailReport(apexJob.CreatedBy.Email);
        }

    }


    private void emailReport(String defaultEmail) {

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if (emailAddressList.isEmpty()) {
            emailAddressList.add(defaultEmail);
        }
        String emailHtmlBody = '';
        String emailSubject = '';
        String overallStatus = 'Completed';

        emailHtmlBody = emailHtmlBody
            + '<tr><td>Old record owner ID</td><td>: ' + oldOwnerId +'</td></tr>\n'
            + '<tr><td>New record owner ID</td><td>: ' + newOwnerId +'</td></tr>\n'
            + '<br/><br/>\n';
        for (LogRecord logRec : log) {
            emailHtmlBody = emailHtmlBody
                + '<tr><td>Apex batch job ID</td><td>: ' + logRec.id +'</td></tr>\n'
                + '<tr><td>Job status</td><td>: ' + logRec.status +'</td></tr>\n'
                + '<tr><td>Object name</td><td>: ' + logRec.objectName +'</td></tr>\n'
                + '<tr><td>Records processed</td><td>: ' + logRec.recordsProcessed +'</td></tr>\n'
                + '<tr><td>Records updated</td><td>: ' + logRec.recordsUpdated +'</td></tr>\n'
                + '<tr><td>Records failed</td><td>: ' + logRec.recordsFailed +'</td></tr>\n'
                + '<tr><td>Job items</td><td>: ' + logRec.batchJobItems +'</td></tr>\n'
                + '<tr><td>Job errors</td><td>: ' + logRec.numberOfErrors +'</td></tr>\n'
                + '<br/>\n';
            if (logRec.status != 'Completed') overallStatus = 'Failed';
            emailSubject += logRec.objectName + ', ';
        }
        emailSubject
            = overallStatus.toUpperCase() + ': '
            + 'Update owner of ' + emailSubject.left(emailSubject.length() - 2)
            + ' records';
        mail.setToAddresses(emailAddressList);
        mail.setSubject(emailSubject);
        mail.setHtmlBody(emailHtmlBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}
